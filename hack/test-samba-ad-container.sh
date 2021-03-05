#!/bin/bash

LOCAL_TAG="${LOCAL_TAG:-samba-ad-container:latest}"

if [ -z "${CONTAINER_CMD}" ]; then
	CONTAINER_CMD=$(command -v docker || echo "")
fi
if [ -z "${CONTAINER_CMD}" ]; then
	CONTAINER_CMD=$(command -v podman || echo "")
fi

_error() {
	echo "$@"
	exit 1
}

CONTAINER_ID="$(${CONTAINER_CMD} run --name samba-ad \
	--cap-add SYS_ADMIN --rm -d "${LOCAL_TAG}")"
if [ $? -ne 0 ]; then
	_error "Error running samba ad container"
fi

echo "Container started, ID: '${CONTAINER_ID}'"

# provisioning and populating takes a while
# retry for 2 minutes before giving up

tries=0
rc=1
while [ $tries -lt 120 ] && [ $rc -ne 0 ]; do
	sleep 1
	tries=$(( tries + 1 ))
	echo "try #$tries:"
	${CONTAINER_CMD} exec "${CONTAINER_ID}" smbclient -N -L 127.0.0.1
	rc=$?
done

if [ $rc -ne 0 ]; then
	_error "Error listing samba shares"
fi

${CONTAINER_CMD} exec "${CONTAINER_ID}" samba-tool domain info 127.0.0.1
if [ $? -ne 0 ]; then
	_error "Error listing domain info"
fi

${CONTAINER_CMD} kill "${CONTAINER_ID}"

echo "Success"
exit 0
