normalize_name() {
    local input="$1"

    # lowercase
    input="${input,,}"

    # remove non‑alphanumeric except spaces
    input="$(printf "%s" "$input" | tr -cd 'a-z0-9 ')"

    # trim leading/trailing spaces
    input="$(printf "%s" "$input" | sed 's/^ *//; s/ *$//')"

    # extract first token
    set -- $input
    printf "%s\n" "$1"
}