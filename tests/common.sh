#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"

export AD_DEPLOYMENT_YAML="${SCRIPT_DIR}/files/samba-ad-server-deployment.yml"
export AD_DEPLOYMENT_NAME="samba-ad-server"
export MEMBER_POD_YAML="${SCRIPT_DIR}/files/samba-domain-member-pod.yml"
export MEMBER_POD_NAME="samba-dm"
export MEMBER_CM_NAME="samba-container-config"
export MEMBER_SECRET_NAME="ad-join-secret"

export KEEP=${KEEP:-0}

_error() {
	echo "$@"
	exit 1
}
