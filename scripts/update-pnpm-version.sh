#!/usr/bin/env bash
set +x +e

declare -A EXIT_CODES=(
    [SUCCESS]=0
    [UNSUPPORTED_SHELL]=1
    [MISSING_PNPM_VERSION]=2
    [ENTER_PROJECT_ROOT_FAILED]=3
    [EXIT_PROJECT_ROOT_FAILED]=4
    [PNPM_VERSION_UPGRADE_FAILED]=5
)

declare -A EXIT_MESSAGES=(
    [SUCCESS]="Successfully upgraded pnpm version in all package manifests!"
    [MISSING_PNPM_VERSION]="No pnpm version to upgrade to supplied!"
    [ENTER_PROJECT_ROOT_FAILED]="Failed to enter project root directory!"
    [UNSUPPORTED_SHELL]="Unsupported shell! Please use bash, ksh93, or zsh."
    [ENTER_PROJECT_ROOT_FAILED]="Failed to enter project root directory!"
    [EXIT_PROJECT_ROOT_FAILED]="Failed to exit project root directory!"
    [PNPM_VERSION_UPGRADE_FAILED]="Failed to upgrade pnpm version in package manifests!"
)

SCRIPT_DIR="$( (
    function get_script_dir() {
        pushd . 2>&1 > /dev/null || return 1
        local SCRIPT_PATH
        if [[ -n "${BASH}" ]]; then
            # shellcheck disable=SC2128
            SCRIPT_PATH="${BASH_SOURCE}"
        elif [[ -n "${ZSH_VERSION}" ]]; then
            # shellcheck disable=SC2296
            SCRIPT_PATH="${(%):-%x}"
        elif [[ -n "${TMOUT}" ]]; then
            # shellcheck disable=SC2296
            SCRIPT_PATH="${.sh.file}"
        elif [[ "${0##*/}" == "dash" ]]; then
            local x
            x="$(lsof -p $$ -Fn0 | tail -1)"
            # shellcheck disable=SC2296
            SCRIPT_PATH="${x#n}"
        else
            printf '\e[38;5;196m[ERROR]\e[0m %s' "${EXIT_MESSAGES[UNSUPPORTED_SHELL]}" 1>&2
            # shellcheck disable=SC2086
            return ${EXIT_CODES[UNSUPPORTED_SHELL]}
        fi
        while [[ -L "${SCRIPT_PATH}" ]]; do
            cd "$(dirname -- "${SCRIPT_PATH}")" || return 2
            SCRIPT_PATH="$(readlink -e -- "$SCRIPT_PATH")"
        done
        cd "$(dirname -- "$SCRIPT_PATH")" > /dev/null || return 2
        SCRIPT_PATH="$(pwd)"
        popd 2>&1 > /dev/null || return 3
        echo "${SCRIPT_PATH}"
        return 0
    }
    get_script_dir
))"

_LIB_PATH="$(readlink -e -- "${SCRIPT_DIR}/lib/")"

# shellcheck source=./lib/logging.sh
source "${_LIB_PATH}/logging.sh"

if [[ "$*" == *"--verbose"* ]]; then
    VERBOSE="${TRUE}"
    lib::logging::verbose "Verbose logging enabled!"
fi

# -- The path to the project root directory
PROJECT_ROOT="$(readlink -e -- "${SCRIPT_DIR}/../")"

# -- The desired version of pnpm to update to
PNPM_VERSION="${1}"

if [[ -z "${PNPM_VERSION}" ]]; then
    lib::logging::error "${EXIT_MESSAGES[MISSING_PNPM_VERSION]}"
    lib::logging::failure "FAILED"
    # shellcheck disable=SC2086
    exit ${EXIT_CODES[MISSING_PNPM_VERSION]}
fi

lib::logging::info "Starting pnpm version update..."

if ! pushd "${PROJECT_ROOT}" > /dev/null 2>&1; then
    lib::logging::error "${EXIT_MESSAGES[ENTER_PROJECT_ROOT_FAILED]}"
    lib::logging::failure "FAILED"
    # shellcheck disable=SC2086
    exit ${EXIT_CODES[ENTER_PROJECT_ROOT_FAILED]}
fi

find "${PROJECT_ROOT}" -iname "node_modules" -prune -o -type f -iname "package.json" \
    -exec sed -i -E "s/^([[:space:]]*\"packageManager\":[[:space:]]*\"pnpm@).*(\"[^\$]*)$/\1${1}\2/" {} \;
RESULT=$?
if [[ $RESULT -ne 0 ]]; then
    lib::logging::error "${EXIT_MESSAGES[PNPM_VERSION_UPGRADE_FAILED]}"
    lib::logging::failure "FAILED"
    # shellcheck disable=SC2086
    exit ${EXIT_CODES[PNPM_VERSION_UPGRADE_FAILED]}
fi

if ! popd > /dev/null 2>&1; then
    lib::logging::error "${EXIT_MESSAGES[EXIT_PROJECT_ROOT_FAILED]}"
    lib::logging::failure "FAILED"
    # shellcheck disable=SC2086
    exit ${EXIT_CODES[EXIT_PROJECT_ROOT_FAILED]}
fi

lib::logging::success "${EXIT_MESSAGES[SUCCESS]}"
# shellcheck disable=SC2086
exit ${EXIT_CODES[SUCCESS]}
