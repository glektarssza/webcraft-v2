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
declare -a LONG_OPTIONS SHORT_OPTIONS;
declare SCRIPT_DIR PROJECT_ROOT STATUS_CODE GITHUB_API_CALL_DATA;
declare REPOSITORY HEAD_REF RUN_ID JOB_ID EXTERNAL_ID DRY_RUN;
declare CHECK_NAME CHECK_TITLE CHECK_SUMMARY CHECK_TEXT;

# -- Cleanup routine
# shellcheck disable=SC2329
function cleanup() {
    unset LONG_OPTIONS SHORT_OPTIONS;
    unset SCRIPT_DIR PROJECT_ROOT STATUS_CODE GITHUB_API_CALL_DATA;
    unset REPOSITORY HEAD_REF RUN_ID JOB_ID EXTERNAL_ID DRY_RUN;
    unset CHECK_NAME CHECK_TITLE CHECK_SUMMARY CHECK_TEXT;
}

trap cleanup EXIT;

SCRIPT_DIR="$(get_script_dir)";

# shellcheck disable=SC2034
PROJECT_ROOT="$(readlink -f "${SCRIPT_DIR}/../..")";

DRY_RUN="false";

source "${SCRIPT_DIR}/lib/dry-run.sh";
source "${SCRIPT_DIR}/lib/json.sh";

SHORT_OPTIONS=("r:");

LONG_OPTIONS=(
    "dry-run!" "repository:" "job-id:" "run-id:" "external-id:" "head-ref:"
    "check-name:" "check-title:" "check-text:" "check-summary:"
);

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
    echo "::error::Invalid Git head reference (no value)!";
    exit 1;
fi

if [[ ! "${HEAD_REF}" =~ [a-zA-Z0-9]{40} && ! "${HEAD_REF}" =~ ([[:graph:]]|/)+ ]]; then
    echo "::error::Invalid Git head reference (invalid value)!";
    exit 1;
fi

HEAD_REF="$(git rev-parse --verify "${HEAD_REF}" 2> /dev/null)";

if [[ ! "${HEAD_REF}" =~ [a-zA-Z0-9]{40} ]]; then
    echo "::error::Invalid Git head reference (does not map to a known Git SHA)!";
    exit 1;
fi

echo "::debug::Calling GitHub API to create a check run for Git SHA \"${HEAD_REF}\"...";

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
    "name": "${CHECK_NAME}",
    "output": {
        "title": "${CHECK_TITLE}",
        "summary": "${CHECK_SUMMARY}",
        "text": "${CHECK_TEXT}"
    },
    "status": "in_progress",
    "started_at": "$(date --iso-8601=seconds)",
    "details_url": "https://github.com/${GITHUB_REPOSITORY}/actions/runs/${RUN_ID}/job/${JOB_ID}",
    "head_sha": "${HEAD_REF}",
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
echo "::debug::Created new check run for Git SHA \"${HEAD_REF}\"";

exit 0;
