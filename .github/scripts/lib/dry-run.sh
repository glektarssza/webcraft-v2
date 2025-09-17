# shellcheck shell=bash

# Check whether the script is running in dry run mode.
# === Returns ===
# Success if the script is in dry run mode, failure otherwise.
function is_dry_run() {
    if [[ "${DRY_RUN}" =~ [Tt][Rr][Uu][Ee]|1 ]]; then
        return 0;
    else
        return 1;
    fi
}
