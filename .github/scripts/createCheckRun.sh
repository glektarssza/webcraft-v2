#!/usr/bin/env bash

# -- Errors are fatal, no echoing
set +e +x;

# -- Handy function for finding our script directory
function get_script_dir() {
    local SOURCE_PATH="${BASH_SOURCE[0]}";
    local SYMLINK_DIR;
    local SCRIPT_DIR;
    while [ -L "${SOURCE_PATH}" ]; do
        SYMLINK_DIR="$(cd -P "$(dirname "${SOURCE_PATH}")" > /dev/null 2>&1 && pwd)";
        SOURCE_PATH="$(readlink "${SOURCE_PATH}")";
        if [[ "${SOURCE_PATH}" != /* ]]; then
            SOURCE_PATH="${SYMLINK_DIR}/${SOURCE_PATH}";
        fi
    done
    SCRIPT_DIR="$(cd -P "$(dirname "${SOURCE_PATH}")" > /dev/null 2>&1 && pwd)";
    echo "${SCRIPT_DIR}";
}

# -- Forward declare variables
declare SCRIPT_DIR PROJECT_ROOT STATUS_CODE HEAD_SHA GITHUB_API_CALL_DATA;
declare REPOSITORY HEAD_REF RUN_ID JOB_ID EXTERNAL_ID DRY_RUN;
declare CHECK_NAME CHECK_TITLE CHECK_SUMMARY CHECK_TEXT;

# -- Cleanup routine
# shellcheck disable=SC2329
function cleanup() {
    unset SCRIPT_DIR PROJECT_ROOT STATUS_CODE HEAD_SHA GITHUB_API_CALL_DATA;
    unset REPOSITORY HEAD_REF RUN_ID EXTERNAL_ID CHECK_NAME CHECK_TITLE DRY_RUN;
    unset CHECK_NAME CHECK_TITLE CHECK_SUMMARY CHECK_TEXT;
}

trap cleanup EXIT;

SCRIPT_DIR="$(get_script_dir)";

# shellcheck disable=SC2034
PROJECT_ROOT="$(readlink -f "${SCRIPT_DIR}/../..")";

DRY_RUN="false";

function is_dry_run() {
    if [[ "${DRY_RUN}" =~ [Tt][Rr][Uu][Ee]|1 ]]; then
        return 0;
    else
        return 1;
    fi
}

function parse_args() {
    echo "::debug::Parsing arguments...";
    while [[ -n "$1" ]]; do
        case "$1" in
            --repository)
                shift 1;
                REPOSITORY="$1";
                echo "::debug::Parsed repository \"${REPOSITORY}\"";
            ;;
            --repository=*)
                REPOSITORY="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed repository \"${REPOSITORY}\"";
            ;;
            --head-ref)
                shift 1;
                HEAD_REF="$1";
                echo "::debug::Parsed head reference \"${HEAD_REF}\"";
            ;;
            --head-ref=*)
                HEAD_REF="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed head reference \"${HEAD_REF}\"";
            ;;
            --external-id)
                shift 1;
                EXTERNAL_ID="$1";
                echo "::debug::Parsed external ID \"${EXTERNAL_ID}\"";
            ;;
            --external-id=*)
                EXTERNAL_ID="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed external ID \"${JOB_ID}\"";
            ;;
            --job-id)
                shift 1;
                JOB_ID="$1";
                echo "::debug::Parsed GitHub job ID \"${JOB_ID}\"";
            ;;
            --job-id=*)
                JOB_ID="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed GitHub job ID \"${JOB_ID}\"";
            ;;
            --run-id)
                shift 1;
                RUN_ID="$1";
                echo "::debug::Parsed GitHub run ID \"${RUN_ID}\"";
            ;;
            --run-id=*)
                RUN_ID="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed GitHub run ID \"${RUN_ID}\"";
            ;;
            --check-name)
                shift 1;
                CHECK_NAME="$1";
                echo "::debug::Parsed check name \"${CHECK_NAME}\"";
            ;;
            --check-name=*)
                CHECK_NAME="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed check name \"${CHECK_NAME}\"";
            ;;
            --check-title)
                shift 1;
                CHECK_TITLE="$1";
                echo "::debug::Parsed check title \"${CHECK_TITLE}\"";
            ;;
            --check-title=*)
                CHECK_TITLE="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed check title \"${CHECK_TITLE}\"";
            ;;
            --check-summary)
                shift 1;
                CHECK_SUMMARY="$1";
                echo "::debug::Parsed check summary \"${CHECK_SUMMARY}\"";
            ;;
            --check-summary=*)
                CHECK_SUMMARY="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed check summary \"${CHECK_SUMMARY}\"";
            ;;
            --check-text)
                shift 1;
                CHECK_TEXT="$1";
                echo "::debug::Parsed check text \"${CHECK_TEXT}\"";
            ;;
            --check-text=*)
                CHECK_TEXT="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed check text \"${CHECK_TEXT}\"";
            ;;
            --dry-run)
                DRY_RUN="true";
                echo "::debug::Running in dry run mode";
            ;;
            --no-dry-run)
                DRY_RUN="false";
                echo "::debug::Not running in dry run mode";
            ;;
            --dry-run=*)
                DRY_RUN="$(echo "$1" | awk -F"=" '{print $2;}')";
                if is_dry_run; then
                    echo "::debug::Running in dry run mode";
                else
                    echo "::debug::Not running in dry run mode";
                fi
            ;;
        esac
        shift 1;
    done
    echo "::debug::Done Parsing arguments";
}

parse_args "$*";

if [[ -z "${REPOSITORY}" ]]; then
    echo "::debug::Repository not provided on the command line, using default \"${OWNER}/${REPO}\"";
    REPOSITORY="${OWNER}/${REPO}";
fi

if [[ ! "${REPOSITORY}" =~ [[:graph:]]+/[[:graph:]]+ ]]; then
    echo "::error::Invalid GitHub repository (invalid value)!";
    exit 1;
fi

if [[ -z "${RUN_ID}" ]]; then
    echo "::error::Invalid GitHub run ID (no value)!";
    exit 1;
fi

if [[ ! "${RUN_ID}" =~ [[:digit:]]+ ]]; then
    echo "::error::Invalid GitHub run ID (invalid value)!";
    exit 1;
fi

if [[ -z "${JOB_ID}" ]]; then
    echo "::error::Invalid GitHub job ID (no value)!";
    exit 1;
fi

if [[ ! "${JOB_ID}" =~ [[:digit:]]+ ]]; then
    echo "::error::Invalid GitHub job ID (invalid value)!";
    exit 1;
fi

if [[ -z "${EXTERNAL_ID}" ]]; then
    echo "::debug::External ID not provided on the command line, using default (job ID) \"${JOB_ID}\"";
    EXTERNAL_ID="${JOB_ID}";
fi

if [[ -z "${CHECK_NAME}" ]]; then
    echo "::error::Invalid GitHub check name (no value)!";
    exit 1;
fi

if [[ -z "${CHECK_TITLE}" ]]; then
    echo "::error::Invalid GitHub check title (no value)!";
    exit 1;
fi

if [[ -z "${HEAD_REF}" ]]; then
    echo "::error::Invalid head reference (no value)!";
    exit 1;
fi

HEAD_SHA="$(git rev-parse --verify "${HEAD_REF}" 2> /dev/null)";

if [[ -z "${HEAD_SHA}" ]]; then
    echo "::error::Invalid head reference (does not map to a known Git SHA)!";
    exit 1;
fi

echo "::debug::Calling GitHub API to create a check run for Git SHA \"${HEAD_SHA}\"...";

if is_dry_run; then
    GITHUB_API_CALL_DATA="";
    STATUS_CODE="0";
else
    GITHUB_API_CALL_DATA="$(gh api --method POST \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${GITHUB_REPOSITORY}/check-runs" \
        --input - <<EOF
{
    "name": "${CHECK_NAME}"
    "output": {
        "title": "${CHECK_TITLE}",
        "summary": "${CHECK_SUMMARY}",
        "text": "${CHECK_TEXT}"
    },
    "status": "in_progress",
    "started_at": "$(date --iso-8601=seconds)",
    "details_url": "https://github.com/${GITHUB_REPOSITORY}/actions/runs/${RUN_ID}/job/${JOB_ID}",
    "head_sha": "$(git rev-parse HEAD)",
    "external_id": "${EXTERNAL_ID}"
}
EOF
    )";
    STATUS_CODE="$?";
fi

if [[ "${STATUS_CODE}" != "0" ]]; then
    echo "::error::Failed to call GitHub API (call returned status code \"${STATUS_CODE}\")!";
    exit "${STATUS_CODE}";
fi

echo "::debug::Raw GitHub API output: ${GITHUB_API_CALL_DATA}";
echo "::debug::Created new check run for Git SHA \"${HEAD_SHA}\"";

exit 0;
