#!/bin/bash
# helper script to install build auxiliary tools in local directory
#
# usage:
#   install-tools.sh --<tool-name> <alt_bin>
#
#
set -e

_ensure_alt_bin() {
	mkdir -p "${ALT_BIN}"
}

_require_py() {
    if [ -z "$PY_CMD" ]; then
        echo "error: python3 command required, but not found" >&2
        echo "(set PY_CMD to specify python command)" >&2
        exit 5
    fi
}

_install_gitlint() {
    _require_py
    _ensure_alt_bin
    "${PY_CMD}" -m venv "${ALT_BIN}/.py"
    "${ALT_BIN}/.py/bin/pip" install "gitlint==${GITLINT_VER}"
    installed_to="${ALT_BIN}/gitlint"
    ln -s "${ALT_BIN}/.py/bin/gitlint" "${installed_to}"
}

_install_shellcheck() {
    installed_to="${ALT_BIN}/shellcheck"
    local url="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VER}/shellcheck-${SHELLCHECK_VER}.linux.x86_64.tar.xz"
    tmpdir="$(mktemp -d)"
    _ensure_alt_bin
    curl -Lo "${tmpdir}/shellcheck.tar.xz" "$url"
    mkdir "${tmpdir}/shellcheck"
    tar -xf "${tmpdir}/shellcheck.tar.xz" -C "${tmpdir}/shellcheck"
    mkdir -p ~/bin
    install -m0755 "${tmpdir}/shellcheck/shellcheck-${SHELLCHECK_VER}/shellcheck" "${installed_to}"
    rm -rf "${tmpdir}"
}


GITLINT_VER="0.19.1"
SHELLCHECK_VER="v0.8.0"


if [ -z "$PY_CMD" ]; then
    if ! PY_CMD="$(command -v python3)"; then
        echo "warning: failed to find python3 command" >&2
    fi
fi

ALT_BIN="$(realpath "${2:-.bin}")"
case "$1" in
    --gitlint)
        if command -v "${ALT_BIN}/gitlint" 2>/dev/null; then
            exit 0
        fi
        _install_gitlint 1>&2
        echo "${installed_to}"
    ;;
    --shellcheck)
        if command -v "${ALT_BIN}/shellcheck" 2>/dev/null; then
            exit 0
        fi
        _install_shellcheck 1>&2
        echo "${installed_to}"
    ;;
    *)
        echo "usage: $0 --<tool-name> [<ALT_BIN>]"
        echo ""
        echo "available tools:"
        echo "  --gitlint"
        echo "  --shellcheck"
    ;;
esac
