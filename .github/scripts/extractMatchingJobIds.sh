#!/usr/bin/env bash

# -- Errors are fatal, no echoing
set +ex;

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
declare -a JOB_IDS;
declare SCRIPT_DIR PROJECT_ROOT STATUS_CODE HEAD_REF HEAD_SHA DRY_RUN;
declare JOB_NAME_PATTERN;

# -- Cleanup routine
# shellcheck disable=SC2329
function cleanup() {
    unset JOB_IDS;
    unset SCRIPT_DIR PROJECT_ROOT STATUS_CODE HEAD_REF HEAD_SHA DRY_RUN;
    unset JOB_NAME_PATTERN;
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
            --head-ref)
                shift 1;
                HEAD_REF="$1";
                echo "::debug::Parsed head reference \"${HEAD_REF}\"";
            ;;
            --head-ref=*)
                HEAD_REF="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed head reference \"${HEAD_REF}\"";
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
            --job-name-pattern)
                shift 1;
                JOB_NAME_PATTERN="$1";
                echo "::debug::Parsed job name pattern \"${JOB_NAME_PATTERN}\"";
            ;;
            --job-name-pattern=*)
                JOB_NAME_PATTERN="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed job name pattern \"${JOB_NAME_PATTERN}\"";
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

parse_args "$@";

if [[ -z "${RUN_ID}" ]]; then
    echo "::error::Invalid GitHub run ID (no value)!";
    exit 1;
fi

if [[ ! "${RUN_ID}" =~ [[:digit:]]+ ]]; then
    echo "::error::Invalid GitHub run ID (invalid value)!";
    exit 1;
fi

if [[ -z "${JOB_NAME_PATTERN}" ]]; then
    echo "::error::Invalid job name pattern (no value)!";
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

echo "::debug::Calling GitHub API to retrieve known check runs for Git SHA \"${HEAD_SHA}\"...";
if is_dry_run; then
    STATUS_CODE="0";
else
    GITHUB_API_CALL_DATA="$(gh api --method GET \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${OWNER}/${REPO}/actions/runs/${RUN_ID}/jobs" | \
        jq --arg job_name "${JOB_NAME_PATTERN}" -f "${SCRIPT_DIR}/workflow_runs_extract_job_ids.jq")";
    STATUS_CODE="$?";
fi
if [[ "${STATUS_CODE}" != "0" ]]; then
    echo "::error::Failed to call GitHub API (call returned status code \"${STATUS_CODE}\")!";
    exit "${STATUS_CODE}";
fi

mapfile -t JOB_IDS < <(echo "${GITHUB_API_CALL_DATA}");

echo "::info::Found ${#JOB_IDS[@]} matching job IDs for name pattern \"${JOB_NAME_PATTERN}\"";
echo "::debug::Matching job IDs are \"$(echo "${JOB_IDS[@]}" | tr ' ' ',' )\"";
echo "job-ids=$(echo "${JOB_IDS[@]}" | tr ' ' ':')" >> "$GITHUB_OUTPUT";
exit 0;
