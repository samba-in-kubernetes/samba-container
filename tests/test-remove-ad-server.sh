#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

if [ "${KEEP}" -eq 1 ]; then
	echo "keeping ad server deployment (KEEP=1)"
	exit 0
fi

echo "removing ad server deployment..."
kubectl delete deployment "${AD_DEPLOYMENT_NAME}"
[ $? -eq 0 ] || _error "Error deleting deployment"
echo
echo "ad server deployment removed"
