if [[ -z "${_LIB_PATH}" ]]; then
    SCRIPT_DIR="$( (
        function get_script_dir() {
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
                # shellcheck disable=SC2296
                x="$(lsof -p $$ -Fn0 | tail -1)"
                # shellcheck disable=SC2296
                SCRIPT_PATH="${x#n}"
            else
                return 1
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
    if [[ $? -eq 1 ]]; then
        printf "[FATAL] Unsupported shell, please use a supported shell!\n"
        return 1
    fi

    if [[ -z "${_LIB_PATH}" ]]; then
        _LIB_PATH="$(readlink -e -- "${SCRIPT_DIR}")"
    fi
fi

if [[ -n "${_LIB_BOOLEAN_GUARD+x}" ]]; then
    return 0
fi
declare _LIB_BOOLEAN_GUARD

# shellcheck source=./strings.sh
source "${_LIB_PATH}/strings.sh"

# The numerical value considered to be "true".
export TRUE=0

# The numerical value considered to be "false".
export FALSE=1

# Get whether the input value is truthy ("1" or the string "true", lower or upper
# case.)
function lib::boolean::is_truthy() {
    if [[ "$(lib::strings::to_lower_case "${1,,}")" =~ (1|true) ]]; then
        # shellcheck disable=SC2086
        return ${TRUE}
    fi
    # shellcheck disable=SC2086
    return ${FALSE}
}

# Get whether the input value is truthy (any numeric value other than "1" or any
# string other than the string "true", lower or uppercase.)
function lib::boolean::is_falsy() {
    if ! lib::boolean::is_truthy "$1"; then
        # shellcheck disable=SC2086
        return ${TRUE}
    fi
    # shellcheck disable=SC2086
    return ${FALSE}
}
