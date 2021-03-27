#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

AD_DEPLOYMENT_YAML="${SCRIPT_DIR}/files/samba-ad-server-deployment.yml"
AD_DEPLOYMENT_NAME="samba-ad-server"

KEEP=${KEEP:-0}

_error() {
	echo "$@"
	exit 1
}
