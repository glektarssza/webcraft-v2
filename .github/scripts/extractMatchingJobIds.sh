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
declare SCRIPT_DIR PROJECT_ROOT STATUS_CODE GITHUB_API_CALL_DATA;
declare REPOSITORY JOB_NAME_PATTERN DRY_RUN

# -- Cleanup routine
# shellcheck disable=SC2329
function cleanup() {
    unset JOB_IDS;
    unset SCRIPT_DIR PROJECT_ROOT STATUS_CODE GITHUB_API_CALL_DATA;
    unset REPOSITORY JOB_NAME_PATTERN DRY_RUN
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
            --repo|-r)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid GitHub repository (no value)!";
                    exit 1;
                fi
                REPOSITORY="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed GitHub repository \"${REPOSITORY}\"";
                INDEX=${INDEX}+1;
            ;;
            --repo=*)
                REPOSITORY="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed GitHub run ID \"${REPOSITORY}\"";
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
            --job-name-pattern)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid job name pattern (no value)!";
                    exit 1;
                fi
                JOB_NAME_PATTERN="${ARGUMENTS[INDEX+1]}";
                echo "::debug::Parsed job name pattern \"${JOB_NAME_PATTERN}\"";
                INDEX=${INDEX}+1;
            ;;
            --job-name-pattern=*)
                JOB_NAME_PATTERN="$(echo "${ARG}" | awk -F"=" '{print $2;}')";
                echo "::debug::Parsed job name pattern \"${JOB_NAME_PATTERN}\"";
            ;;
            --job-name)
                if [[ ${INDEX} -ge ${#ARGUMENTS[@]} ]]; then
                    echo "::error::Invalid job name (no value)!";
                    exit 1;
                fi
                JOB_NAME_PATTERN="^$(echo "${ARGUMENTS[INDEX+1]}" | sed -E 's/([][)(\\\|\*\+\?\^\$\.\!}{])/\\\1/g')$";
                echo "::debug::Parsed job name pattern \"${JOB_NAME_PATTERN}\"";
                INDEX=${INDEX}+1;
            ;;
            --job-name=*)
                JOB_NAME_PATTERN="^$(echo "${ARG}" | awk -F"=" '{print $2;}' | sed -E 's/([][)(\\\|\*\+\?\^\$\.\!}{])/\\\1/g')$";
                echo "::debug::Parsed job name pattern \"${JOB_NAME_PATTERN}\"";
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

if [[ -z "${JOB_NAME_PATTERN}" ]]; then
    echo "::error::Invalid job name pattern (no value)!";
    exit 1;
fi

echo "::debug::Calling GitHub API to retrieve known check runs for Git SHA \"${HEAD_SHA}\"...";
if is_dry_run; then
    STATUS_CODE="0";
else
    GITHUB_API_CALL_DATA="$(gh api --method GET \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/${REPOSITORY}/actions/runs/${RUN_ID}/jobs" | \
        jq --arg job_name "${JOB_NAME_PATTERN}" -f "${SCRIPT_DIR}/workflow_runs_extract_job_ids.jq")";
    STATUS_CODE="$?";
fi
if [[ "${STATUS_CODE}" != "0" ]]; then
    echo "::error::Failed to call GitHub API (call returned status code \"${STATUS_CODE}\")!";
    exit "${STATUS_CODE}";
fi

if [[ -z "${GITHUB_API_CALL_DATA}" ]]; then
    echo "::error::GitHub API returned no results for job name pattern \"${JOB_NAME_PATTERN}\"!";
    exit 1;
fi

mapfile -t JOB_IDS < <(echo "${GITHUB_API_CALL_DATA}");

echo "::info::Found ${#JOB_IDS[@]} matching job IDs for name pattern \"${JOB_NAME_PATTERN}\"";
echo "::debug::Matching job IDs are \"$(echo "${JOB_IDS[@]}" | tr ' ' ',' )\"";
echo "job-ids=$(echo "${JOB_IDS[@]}" | \
    awk 'BEGIN{IRS=" ";OFS=":"}{$1=$1;print;}END{printf"\n"}')" >> "$GITHUB_OUTPUT";
exit 0;
