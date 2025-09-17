# shellcheck shell=bash

# Get the length of a JSON array or object.
# === Params ===
# $1 - The JSON data to get the length of.
# === Returns ===
# The length of the JSON array or object.
function json_len() {
    local ALLOWED_TYPES='["string", "array", "object"]';
    echo "$1" | \
        jq -r --argjson allowed_types "${ALLOWED_TYPES}" \
        ". as \$data | if \$allowed_types | any(. == \$data | type) then \
            \$data | length \
        else \
            null \
        end";
    return $?;
}

# Convert JSON data to CSV format.
# === Params ===
# $1 - The JSON data to convert.
# === Returns ===
# The converted JSON data.
function json_to_csv() {
    echo "$1" | jq -r "@csv";
    return $?;
}
