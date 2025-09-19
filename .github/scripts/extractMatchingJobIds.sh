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
declare -a LONG_OPTIONS;
declare SCRIPT_DIR PROJECT_ROOT STATUS_CODE GITHUB_API_CALL_DATA;
declare REPOSITORY DRY_RUN;

# -- Cleanup routine
# shellcheck disable=SC2329
function cleanup() {
    unset LONG_OPTIONS;
    unset SCRIPT_DIR PROJECT_ROOT STATUS_CODE GITHUB_API_CALL_DATA;
    unset REPOSITORY DRY_RUN;
}

trap cleanup EXIT;

SCRIPT_DIR="$(get_script_dir)";

# shellcheck disable=SC2034
PROJECT_ROOT="$(readlink -f "${SCRIPT_DIR}/../..")";

DRY_RUN="false";

source "${SCRIPT_DIR}/lib/dry-run.sh";
source "${SCRIPT_DIR}/lib/json.sh";

LONG_OPTIONS=(
    "dry-run!" "repository:" "run-id:" "job-name" "job-name-pattern"
    "case-insensitive!"
)

export AWKPATH="${SCRIPT_DIR}/lib:${AWKPATH}";

echo "::debug::Parsing arguments...";
OPTS="$(echo "$*" | awk \
    -v long_options="$(echo "${LONG_OPTIONS[@]}" | tr ' ' ',')" \
    -v short_options="$(echo "${SHORT_OPTIONS[@]}" | tr -d ' ')" \
    -f "${SCRIPT_DIR}/arg-parse.awk")"
echo "::debug::Got raw options:";
printf "%s\0" "${OPTS}" | xargs -d "\0" -I{} echo '::debug::{}';
export "$(env -i -S "${OPTS}")";
echo "::debug::Done Parsing arguments";

if [[ -z "${REPOSITORY}" ]]; then
    REPOSITORY="${OWNER}/${REPO}";
    echo "::debug::Using default repository \"${REPOSITORY}\"";
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

if [[ -z "${JOB_NAME_PATTERN}" && -n "${JOB_NAME}" ]]; then
    JOB_NAME_PATTERN="^${JOB_NAME}\$";
elif [[ -z "${JOB_NAME_PATTERN}" ]]; then
    echo "::error::Invalid job name pattern (no value)!";
    exit 1;
fi

echo "::debug::Calling GitHub API to retrieve known check runs for GitHub run ID \"${RUN_ID}\"...";
if is_dry_run; then
    GITHUB_API_CALL_DATA="";
    STATUS_CODE="0";
else
    GITHUB_API_CALL_DATA="$(gh api --method GET \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${REPOSITORY}/actions/runs/${RUN_ID}/jobs" | \
        jq --arg job_name "${JOB_NAME_PATTERN}" --arg regex_flags "$(
        if is_case_insensitive; then
            echo "i";
        else
            echo "";
        fi
        )" \
            -f "${SCRIPT_DIR}/workflow_runs_extract_job_ids.jq")";
    STATUS_CODE="$?";
fi
if [[ "${STATUS_CODE}" != "0" ]]; then
    echo "::error::Failed to call GitHub API (call returned status code \"${STATUS_CODE}\")!";
    exit "${STATUS_CODE}";
fi

if [[ -z "${GITHUB_API_CALL_DATA}" ]]; then
    echo "::debug::GitHub API returned no results for job name pattern \"${JOB_NAME_PATTERN}\"!";
    echo "job-ids=[]" >> "$GITHUB_OUTPUT";
    exit 0;
fi

# NOTE: We compact the data to a single line here, otherwise GitHub gets mad...
GITHUB_API_CALL_DATA="$(json_compact "${GITHUB_API_CALL_DATA}")"
echo "::info::Found $(json_len "${GITHUB_API_CALL_DATA}") matching job ID(s)";
echo "::debug::Matching job ID(s) are \"${GITHUB_API_CALL_DATA}\"";
echo "job-ids=${GITHUB_API_CALL_DATA}" >> "$GITHUB_OUTPUT";
exit 0;
