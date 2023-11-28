#!/bin/bash



echo "determining container command."
if [ -z "${CONTAINER_CMD}" ]; then
	CONTAINER_CMD=$(command -v docker || echo )
fi
if [ -z "${CONTAINER_CMD}" ]; then
	CONTAINER_CMD=$(command -v podman || echo )
fi
if [ -z "${CONTAINER_CMD}" ]; then
echo "Error determining container command."
exit 1
fi
echo "container command: '${CONTAINER_CMD}'."
echo "creating temporary directory."
TMPDIR="$(mktemp -d)"
rc=$?

if [ $rc -ne 0 ]; then
	echo "Error creating temporary directory."
	exit 1
fi
echo "temporary directory: '${TMPDIR}'"
echo "starting Samba container."
CONTAINER_ID="$(${CONTAINER_CMD} run --network=none --name samba \
	--volume="${TMPDIR}":/share:Z --rm  -d "${LOCAL_TAG}")"
rc=$?

if [ $rc -ne 0 ]; then
	echo "Error running samba container"
	exit 1
fi
echo "Container started, ID: '${CONTAINER_ID}'"

# give samba a second to come up
sleep 1

echo "Listing samba shares"
	${CONTAINER_CMD} exec "${CONTAINER_ID}" smbclient -U% -L 127.0.0.1
	rc=$?

if [ ${rc} -ne 0 ]; then
	echo "Error listing samba shares"
	exit 1
fi


echo "stopping samba container."

${CONTAINER_CMD} kill "${CONTAINER_ID}"
rc=$?

if [ $rc -ne 0 ]; then
	echo "Error stopping samba container"
	exit 1
fi

echo "samba container stopped."




echo "removing temporary directory."
rm -rf "${TMPDIR}"
rc=$?


if [ $rc -eq 0 ]; then
	echo "Success"
fi

exit $rc
