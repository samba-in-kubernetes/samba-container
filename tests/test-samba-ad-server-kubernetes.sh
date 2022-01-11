#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

source "${SCRIPT_DIR}/test-deploy-ad-server.sh"

kubectl exec "${podname}" -- samba-tool domain info 127.0.0.1
[ $? -eq 0 ] || _error "Error listing domain info"
echo

source "${SCRIPT_DIR}/test-deploy-ad-member.sh"

kubectl exec "${podname}" -c "smb" -- smbclient -N -L 127.0.0.1
kubectl exec "${podname}" -c "winbind" -- wbinfo -t
# note: testing `wbinfo -t` from the smb container again
# to make sure samba can communicate to winbindd
kubectl exec "${podname}" -c "smb" -- wbinfo -t

source "${SCRIPT_DIR}/test-remove-ad-member.sh"

source "${SCRIPT_DIR}/test-remove-ad-server.sh"

echo
echo "Success"
exit 0
