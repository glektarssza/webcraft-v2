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

function json_len() {
    echo "$1" | jq -r "length";
    return $?;
}

function json_to_csv() {
    echo "$1" | jq -r "@csv";
    return $?;
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
            --head-ref)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid GitHub head reference (no value)!";
                    exit 1;
                fi
                HEAD_REF="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed GitHub head reference \"${HEAD_REF}\"";
                INDEX=${INDEX}+1;
            ;;
            --head-ref=*)
                HEAD_REF="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed GitHub head reference \"${HEAD_REF}\"";
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
    echo "::debug::Repository not provided on the command line, using default repository \"${OWNER}/${REPO}\"";
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
    GITHUB_API_CALL_DATA="";
    STATUS_CODE="0";
else
    GITHUB_API_CALL_DATA="$(gh api --method GET \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${REPOSITORY}/commits/${HEAD_SHA}/check-runs" | \
        jq -f "${SCRIPT_DIR}/check_runs_extract_ids.jq" --arg external_id "${EXTERNAL_ID}")";
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

echo "::debug::Found $(json_len "${GITHUB_API_CALL_DATA}") existing check run ID(s)";
echo "::debug::Existing check run ID(s) are \"$(json_to_csv "${GITHUB_API_CALL_DATA}")\"";
echo "existing-check-run-ids=${GITHUB_API_CALL_DATA}" >> "${GITHUB_OUTPUT}";
echo "has-existing-check-run=$([[ $(json_len "${GITHUB_API_CALL_DATA}") != "0" ]] && echo "true" || echo "false";)" >> "${GITHUB_OUTPUT}";

exit 0;
