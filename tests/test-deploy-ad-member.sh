#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
IMG_TAG=${IMG_TAG:-"latest"}
IMG_NAME="${SERVER_IMG:-samba-server}:${IMG_TAG}"
IMG_PULL_POLICY="${IMG_PULL_POLICY:-Never}"

source "${SCRIPT_DIR}/common.sh"

echo "Creating ad member pod..."
ERROR_MSG=$(IMG_NAME="${IMG_NAME}" IMG_PULL_POLICY="${IMG_PULL_POLICY}" envsubst < "${MEMBER_POD_YAML}" | kubectl create -f - 2>&1 1>/dev/null)
if [ $? -ne 0 ] ; then
	if [[ "${ERROR_MSG}" =~ "AlreadyExists" ]] ; then
		echo "pod exists already. Continuing."
	else
		_error "Error creating member pod."
	fi
fi

kubectl get pod

podname="$(kubectl get pod | grep "${MEMBER_POD_NAME}" | awk '{ print $1 }')"
[ $? -eq 0 ] || _error "Error getting podname"

echo "Samba ad member pod is $podname"

echo "waiting for pod to be in Running state"
tries=0
podstatus="none"
until [ $tries -ge 120 ] || echo "$podstatus" | grep -q 'Running'; do
	sleep 1
	echo -n "."
	tries=$(( tries + 1 ))
	podstatus="$(kubectl get pod "$podname" -o go-template='{{.status.phase}}')"
done
echo
kubectl get pod
echo
echo "$podstatus" | grep -q 'Running' || \
    _errordbg "Pod did not reach Running state" "pod/${podname}"

echo "waiting for samba to become reachable"
tries=0
rc=1
while [ $tries -lt 120 ] && [ $rc -ne 0 ]; do
	sleep 1
	tries=$(( tries + 1 ))
	kubectl exec "${podname}" -c "smb" -- smbclient -N -L 127.0.0.1 2>/dev/null 1>/dev/null
	rc=$?
	echo -n "."
done
echo
[ $rc -eq 0 ] || _error "Error: samba ad did not become reachable"

echo "member setup done"
