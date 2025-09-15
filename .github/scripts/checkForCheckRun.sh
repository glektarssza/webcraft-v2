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
declare SCRIPT_DIR PROJECT_ROOT STATUS_CODE HEAD_SHA GITHUB_API_CALL_DATA;
declare REPOSITORY HEAD_REF EXTERNAL_ID DRY_RUN;

# -- Cleanup routine
# shellcheck disable=SC2329
function cleanup() {
    unset SCRIPT_DIR PROJECT_ROOT STATUS_CODE HEAD_SHA GITHUB_API_CALL_DATA;
    unset REPOSITORY HEAD_REF RUN_ID EXTERNAL_ID DRY_RUN;
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
            --repo|-r)
                shift 1;
                REPOSITORY="$1";
                echo "::debug::Parsed GitHub repository \"${REPOSITORY}\"";
            ;;
            --repo=*)
                REPOSITORY="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed GitHub run ID \"${REPOSITORY}\"";
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
            --run-id)
                shift 1;
                RUN_ID="$1";
                echo "::debug::Parsed GitHub run ID \"${RUN_ID}\"";
            ;;
            --run-id=*)
                RUN_ID="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed GitHub run ID \"${RUN_ID}\"";
            ;;
            --external-id)
                shift 1;
                EXTERNAL_ID="$1";
                echo "::debug::Parsed external ID \"${EXTERNAL_ID}\"";
            ;;
            --external-id=*)
                EXTERNAL_ID="$(echo "$1" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed external ID \"${EXTERNAL_ID}\"";
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

if [[ -z "${HEAD_REF}" ]]; then
    echo "::error::Invalid head reference (no value)!";
    exit 1;
fi

HEAD_SHA="$(git rev-parse --verify "${HEAD_REF}" 2> /dev/null)";

if [[ -z "${HEAD_SHA}" ]]; then
    echo "::error::Invalid head reference (does not map to a known Git SHA)!";
    exit 1;
fi

if [[ -z "${EXTERNAL_ID}" ]]; then
    echo "::error::Invalid external ID (invalid value)!";
    exit 1;
fi

echo "::debug::Calling GitHub API to check for GitHub check runs with external ID \"${EXTERNAL_ID}\"...";
if is_dry_run; then
    echo "::warning::Running in dry run mode!";
    GITHUB_API_CALL_DATA="false";
    STATUS_CODE="0";
else
    GITHUB_API_CALL_DATA="$(gh api --method GET \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${REPOSITORY}/commits/${HEAD_SHA}/check-runs" | \
        jq -f "${SCRIPT_DIR}/check_runs_find_external_id.jq" --arg external_id "${EXTERNAL_ID}")";
    STATUS_CODE="$?";
fi

if [[ "${STATUS_CODE}" != "0" ]]; then
    echo "::error::Failed to call GitHub API (call returned status code \"${STATUS_CODE}\")!";
    exit "${STATUS_CODE}";
fi

echo "::debug::Raw GitHub API output: ${GITHUB_API_CALL_DATA}";

if [[ -z "${GITHUB_API_CALL_DATA}" ]]; then
    echo "::error::GitHub API returned no data!";
    exit 1;
fi

echo "has-existing-check-run=${GITHUB_API_CALL_DATA}" >> "${GITHUB_OUTPUT}";
case "${GITHUB_API_CALL_DATA,,}" in
    true)
        echo "::debug::Found existing GitHub Actions check run!";
    ;;
    false)
        echo "::debug::Found no existing GitHub Actions check run!";
        exit 0;
    ;;
esac

echo "::debug::Extracting check run ID...";
if is_dry_run; then
    echo "::warning::Running in dry run mode!";
    GITHUB_API_CALL_DATA="";
    STATUS_CODE="0";
else
    GITHUB_API_CALL_DATA="$(gh api --method GET \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${REPOSITORY}/commits/${HEAD_SHA}/check-runs" | \
        jq -f "${SCRIPT_DIR}/check_runs_extract_id.jq" --arg external_id "${EXTERNAL_ID}" | \
        awk 'BEGIN{IRS=" ";OFS=":"}{$1=$1;print;}END{printf"\n"}')";
    STATUS_CODE="$?";
fi

if [[ "${STATUS_CODE}" != "0" ]]; then
    echo "::error::Failed to call GitHub API (call returned status code \"${STATUS_CODE}\")!";
    exit "${STATUS_CODE}";
fi

if [[ -z "${GITHUB_API_CALL_DATA}" ]]; then
    echo "::error::GitHub API returned no data!";
    exit 1;
fi

echo "::debug::Found existing check run ID(s) \"${GITHUB_API_CALL_DATA}\"";
echo "existing-check-run-id=${GITHUB_API_CALL_DATA}" >> "${GITHUB_OUTPUT}";

exit 0;
