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

if [[ -n "${_LIB_STRINGS_GUARD+x}" ]]; then
    return 0
fi
declare _LIB_STRINGS_GUARD

# Convert a string to all lower case.
# === Inputs ===
# `$1` - The string to convert.
# === Outputs ===
# The converted string.
# === Returns ===
# `0` - The operation succeeded.
# `*` - The operation failed.
function lib::strings::to_lower_case() {
    if ! echo "$1" | tr '[:upper:]' '[:lower:]'; then
        return 1
    fi
    return 0
}

# Convert a string to all upper case.
# === Inputs ===
# `$1` - The string to convert.
# === Outputs ===
# The converted string.
# === Returns ===
# `0` - The operation succeeded.
# `*` - The operation failed.
function lib::strings::to_upper_case() {
    if ! echo "$1" | tr '[:lower:]' '[:upper:]'; then
        return 1
    fi
    return 0
}
