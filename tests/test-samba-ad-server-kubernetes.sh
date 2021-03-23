#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEPLOYMENT_YAML="${BASE_DIR}/tests/files/samba-ad-server-deployment.yml"
DEPLOYMENT_NAME="samba-ad-server"

_error() {
	echo "$@"
	exit 1
}

. ${BASE_DIR}/tests/test-deploy-ad-server.sh

kubectl exec "${podname}" -- samba-tool domain info 127.0.0.1
[ $? -eq 0 ] || _error "Error listing domain info"
echo

if [ ${KEEP} -eq 0 ]; then
	echo "removing ad server deployment again..."
	kubectl delete deployment "samba-ad-server"
	[ $? -eq 0 ] || _error "Error deleting deployment"
	echo
fi

echo "Success"
exit 0
