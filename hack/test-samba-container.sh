#!/bin/bash

LOCAL_TAG="${LOCAL_TAG:-centos8:samba}"

if [ -z "${CONTAINER_CMD}" ]; then
	CONTAINER_CMD=$(command -v docker || echo "")
fi
if [ -z "${CONTAINER_CMD}" ]; then
	CONTAINER_CMD=$(command -v podman || echo "")
fi

TMPDIR="$(mktemp -d)"
rc=$?

if [ $rc -ne 0 ]; then
	echo "Error creating temporary directory"
else
	CONTAINER_ID="$(${CONTAINER_CMD} run --network=none --name samba \
		--volume="${TMPDIR}":/share:Z --rm  -d "${LOCAL_TAG}")"
	rc=$?

	if [ $rc -ne 0 ]; then
		echo "Error running samba container"
	else
		echo "Container started, ID: '${CONTAINER_ID}'"

		# give samba a second to come up
		sleep 1

		${CONTAINER_CMD} exec "${CONTAINER_ID}" smbclient -U% -L 127.0.0.1
		rc=$?

		if [ $rc -ne 0 ]; then
			echo "Error listing samba shares"
		fi
	fi

	${CONTAINER_CMD} kill "${CONTAINER_ID}"
fi

rm -rf "${TMPDIR}"

if [ $rc -eq 0 ]; then
	echo "Success"
fi

exit $rc
