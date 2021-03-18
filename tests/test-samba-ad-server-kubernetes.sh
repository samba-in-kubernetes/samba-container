#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEPLOYMENT_YAML="${BASE_DIR}/examples/kubernetes/samba-ad-server-deployment.yml"
DEPLOYMENT_NAME="samba-ad-server"

_error() {
	echo "$@"
	exit 1
}

kubectl create -f "${DEPLOYMENT_YAML}"
[ $? -eq 0 ] || _error "Error creating deployment"

kubectl get deployment

replicaset="$(kubectl describe deployment ${DEPLOYMENT_NAME} | grep -s "NewReplicaSet:" | awk '{ print $2 }')"
[ $? -eq 0 ] || _error "Error getting replicaset"

podname="$(kubectl get pod | grep $replicaset | awk '{ print $1 }')"
[ $? -eq 0 ] || _error "Error getting podname"

echo "Samba pod is $podname"

echo "waiting for pod to be in Running state"
tries=0
podstatus="none"
until [ $tries -ge 120 ] || echo $podstatus | grep -q 'Running'; do
	sleep 1
	echo -n "."
	tries=$(( tries + 1 ))
	podstatus="$(kubectl get pod $podname -o go-template='{{.status.phase}}')"
done
echo
kubectl get pod
echo
echo $podstatus | grep -q 'Running' || _error "Pod did not reach Running state"

echo "waiting for samba to become reachable"
tries=0
rc=1
while [ $tries -lt 120 ] && [ $rc -ne 0 ]; do
	sleep 1
	tries=$(( tries + 1 ))
	kubectl exec "${podname}" -- smbclient -N -L 127.0.0.1 2>/dev/null 1>/dev/null
	rc=$?
	echo -n "."
done
echo
[ $rc -eq 0 ] || _error "Error listing samba shares"

kubectl exec "${podname}" -- smbclient -N -L 127.0.0.1
echo

kubectl exec "${podname}" -- samba-tool domain info 127.0.0.1
[ $? -eq 0 ] || _error "Error listing domain info"
echo

kubectl delete deployment "samba-ad-server"
[ $? -eq 0 ] || _error "Error deleting deployment"
echo

echo "Success"
exit 0
