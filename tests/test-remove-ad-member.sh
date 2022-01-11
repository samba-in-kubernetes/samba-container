#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

if [ "${KEEP}" -eq 1 ]; then
	echo "keeping ad member pod (KEEP=1)"
	exit 0
fi

echo "removing ad member pod..."
kubectl delete pod "${MEMBER_POD_NAME}"
[ $? -eq 0 ] || _error "Error deleting pod"
echo

kubectl delete cm "${MEMBER_CM_NAME}"
[ $? -eq 0 ] || _error "Error deleting configmap"
echo

kubectl delete secret "${MEMBER_SECRET_NAME}"
[ $? -eq 0 ] || _error "Error deleting secret"
echo

echo "ad member pod removed"
