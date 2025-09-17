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
    local -a ARGUMENTS;
    local INDEX;
    echo "::debug::Parsing arguments...";
    mapfile -td " " ARGUMENTS < <(echo "$*");
    for INDEX in $(eval "echo {0..${#ARGUMENTS[@]}}"); do
        local ARG;
        ARG="${ARGUMENTS[${INDEX}]}";
        case "${ARG}" in
            --repository|--repo|-r)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid GitHub repository (no value)!";
                    exit 1;
                fi
                REPOSITORY="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed GitHub repository \"${REPOSITORY}\"";
                INDEX=${INDEX}+1;
            ;;
            --repository=*|--repo=*)
                REPOSITORY="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed GitHub run ID \"${REPOSITORY}\"";
            ;;
            --job-id)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid job ID (no value)!";
                    exit 1;
                fi
                JOB_ID="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed job ID \"${JOB_ID}\"";
                INDEX=${INDEX}+1;
            ;;
            --job-id=*)
                JOB_ID="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed job ID \"${JOB_ID}\"";
            ;;
            --run-id)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid GitHub run ID (no value)!";
                    exit 1;
                fi
                RUN_ID="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed GitHub run ID \"${RUN_ID}\"";
                INDEX=${INDEX}+1;
            ;;
            --run-id=*)
                RUN_ID="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed GitHub run ID \"${RUN_ID}\"";
            ;;
            --external-id)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid external ID (no value)!";
                    exit 1;
                fi
                EXTERNAL_ID="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed external ID \"${EXTERNAL_ID}\"";
                INDEX=${INDEX}+1;
            ;;
            --external-id=*)
                EXTERNAL_ID="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed external ID \"${EXTERNAL_ID}\"";
            ;;
            --check-name)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid check name (no value)!";
                    exit 1;
                fi
                CHECK_NAME="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed check name \"${CHECK_NAME}\"";
                INDEX=${INDEX}+1;
            ;;
            --check-name=*)
                CHECK_NAME="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed check name \"${CHECK_NAME}\"";
            ;;
            --check-title)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid check title (no value)!";
                    exit 1;
                fi
                CHECK_TITLE="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed check title \"${CHECK_TITLE}\"";
                INDEX=${INDEX}+1;
            ;;
            --check-title=*)
                CHECK_TITLE="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed check title \"${CHECK_TITLE}\"";
            ;;
            --check-summary)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid check summary (no value)!";
                    exit 1;
                fi
                CHECK_SUMMARY="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed check summary \"${CHECK_SUMMARY}\"";
                INDEX=${INDEX}+1;
            ;;
            --check-summary=*)
                CHECK_SUMMARY="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed check summary \"${CHECK_SUMMARY}\"";
            ;;
            --check-text)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid check text (no value)!";
                    exit 1;
                fi
                CHECK_TEXT="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed check text \"${CHECK_TEXT}\"";
                INDEX=${INDEX}+1;
            ;;
            --check-text=*)
                CHECK_TEXT="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed check text \"${CHECK_TEXT}\"";
            ;;
            --dry-run)
                if [[ $((INDEX+1)) -lt ${#ARGUMENTS[@]} && "${ARGUMENTS[INDEX+1],,}" =~ true|false ]]; then
                    DRY_RUN="${#ARGUMENTS[${INDEX}+1]}";
                    INDEX=${INDEX}+1;
                else
                    DRY_RUN="true";
                fi
                if is_dry_run; then
                    echo "::debug::Running in dry run mode";
                fi
            ;;
            --no-dry-run)
                if [[ ${INDEX} -lt ${#ARGUMENTS[@]} && "${#ARGUMENTS[${INDEX}+1],,}" =~ true|false ]]; then
                    DRY_RUN="${#ARGUMENTS[${INDEX}+1]}";
                    if is_dry_run; then
                        DRY_RUN="false";
                    else
                        DRY_RUN="true";
                    fi
                    INDEX=${INDEX}+1;
                else
                    DRY_RUN="true";
                fi
                if is_dry_run; then
                    echo "::debug::Running in dry run mode";
                fi
            ;;
            --dry-run=*)
                DRY_RUN="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                if is_dry_run; then
                    echo "::debug::Running in dry run mode";
                else
                    echo "::debug::Not running in dry run mode";
                fi
            ;;
        esac
    done
    echo "::debug::Done Parsing arguments";
}

parse_args "$@";

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
