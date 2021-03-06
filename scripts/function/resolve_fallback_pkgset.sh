# scripts/function/resolve_fallback_pkgset.sh
#
# shellcheck shell=bash
# vi: set ft=bash
#

# source once and only once!
[[ ${GVM_RESOLVE_FALLBACK_PKGSET:-} -eq 1 ]] && return || readonly GVM_RESOLVE_FALLBACK_PKGSET=1

# load dependencies
dep_load() {
    local base="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && builtin pwd)"
    local deps; deps=(
        "_shell_compat.sh"
    )
    for file in "${deps[@]}"
    do
        source "${base}/${file}"
    done
}; dep_load; unset -f dep_load

# __gvm_resolve_fallback_pkgset()
# /*!
# @abstract Determine applicable fallback pkgset for go version
# @discussion
# When normal go pkgset resolution fails the fallback function will attempt to
#   find a suitable fallback from the installed go pkgsets for the specfied
#   go version name.
#
# If a local pkgset is found in the current directory, then that pkgset will be
# selected.
# @param version [optional] Go version name for which to find a fallback pkgset,
#   defaults to the currently exported go_version_name.
# @return Returns a string containing the fallback version name (status 0) or an
#   empty string (status 1) on failure.
# @note Also sets global variable RETVAL to the same return value.
# */
function __gvm_resolve_fallback_pkgset() {
    local version="${1:-$gvm_go_name}"
    local pkgset=""
    local pkgset_regex='^([[:space:]]*[=>*]*[[:space:]]+)([A-Za-z0-9._#:%\/\+\-]+)$'
    local local_pkgset_regex='^([[:space:]]*[=>*]*)(L[[:space:]]+)(\/[^:\\\n\\\0]*)+$'
    local goversion_regex='^([[:space:]]*[=>*]*)(G[[:space:]]+)(go([0-9]+(\.[0-9]+)*))$'
    unset RETVAL

    [[ "x${version// /}" == "x" ]] && RETVAL="" && echo "${RETVAL}" && return 1

    while IFS=$'\n' read -r _line; do
        # skip the G (go version) line
        if __gvm_rematch "${_line}" "${goversion_regex}"
        then
            # GVM_REMATCH[1]: indicator (e.g. ' ', '*', '=>', '=*')
            # GVM_REMATCH[2]: pkgset type (e.g. ' ', 'G')
            # GVM_REMATCH[3]: version name (e.g. go1.7.1)
            # GVM_REMATCH[4]: isolated version (e.g. 1.7.1)
            continue
        fi

        # if the current directory has a local pkgset, we should fallback to it
        if __gvm_rematch "${_line}" "${local_pkgset_regex}" && [[ "${PWD}" == "${GVM_REMATCH[3]}" ]]
        then
            # GVM_REMATCH[1]: indicator (e.g. ' ', '*', '=>', '=*')
            # GVM_REMATCH[2]: pkgset type (e.g. ' ', 'L')
            # GVM_REMATCH[3]: pkgset name (e.g. /home/me/dev/go/test)
            pkgset="${GVM_REMATCH[3]}"
            break
        fi

        if __gvm_rematch "${_line}" "${pkgset_regex}" && [[ "global" == "${GVM_REMATCH[2]}" ]]
        then
            # GVM_REMATCH[1]: indicator (e.g. ' ', '*', '=>', '=*')
            # GVM_REMATCH[2]: pkgset name (e.g. go1.7.1)
            pkgset="global"
            break
        fi
    done <<< "$(gvm_go_name="${version}" \gvm pkgset list --porcelain 2>/dev/null)"

    RETVAL="${pkgset}"

    if [[ -z "${RETVAL// /}" ]]
    then
        RETVAL="" && echo "${RETVAL}" && return 1
    fi

    echo "${RETVAL}" && return 0
}
