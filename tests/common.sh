#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

AD_DEPLOYMENT_YAML="${SCRIPT_DIR}/files/samba-ad-server-deployment.yml"
AD_DEPLOYMENT_NAME="samba-ad-server"
MEMBER_POD_YAML="${SCRIPT_DIR}/files/samba-domain-member-pod.yml"
MEMBER_POD_NAME="samba-dm"
MEMBER_CM_NAME="samba-container-config"
MEMBER_SECRET_NAME="ad-join-secret"

KEEP=${KEEP:-0}

_error() {
	echo "$@"
	exit 1
}
