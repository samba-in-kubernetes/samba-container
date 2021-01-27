#!/bin/bash
#
# This script demonstrates using podman's pods feature to run a smbd
# and winbind container together, configured via samba-container json.
# It automatically joins the domain with the password specified below.
# We don't currently have a secure containerized join so please only
# use this on scratch testing domains.

set -e

# NOTE: This script depnds on the sambacc config json to:
#       a) Reside in the same directory as this script
#       b) Be configured for your AD domain settings

#-- user settable options ---
#
# The container image to use
image=quay.io/samba.org/samba-server:latest
# The name of the pod
name=domsamba
# The port that 445 will be mapped to
pubport=4450
# Use the following vars to customize the podman cli for your particular
# environment
podextraopts=()
ctrextraopts=()
# The AD administrator password for INSECURE join
ad_password="Passw0rd"
#----------------------------

workdir="$1"

case "$2" in
    start)
        set -x

        mkdir -p "${workdir}"/state/private
        mkdir -p "${workdir}"/wbsockets
        mkdir -p "${workdir}"/config
        mkdir -p "${workdir}"/share
        chmod 0755 "${workdir}"/wbsockets
        chmod 0777 "${workdir}"/share
        cp config.json "${workdir}"/config/config.json

        podman pod create \
            --hostname="${name}" \
            --name="${name}" \
            --share=pid,uts,net \
            --publish="${pubport}:445" \
            "${podextraopts[@]}"
        podman pod start "${name}"

        podman container run \
            --detach \
            --pod="${name}" \
            --name="${name}-wb" \
            -v "${workdir}/config":/usr/local/etc \
            -v "${workdir}/state":/var/lib/samba:z \
            -v "${workdir}/wbsockets":/run/samba/winbindd:z \
            -e SAMBA_CONTAINER_ID="${name}" \
            -e SAMBACC_CONFIG="/usr/local/etc/config.json" \
            "${ctrextraopts[@]}" \
            "${image}" \
            --password="${ad_password}" \
            run \
            --insecure-auto-join \
            winbindd
        sleep 1s
        podman container run \
            --detach \
            --pod="${name}" \
            --name="${name}-smb" \
            -v "${workdir}/config":/usr/local/etc \
            -v "${workdir}/state":/var/lib/samba:z \
            -v "${workdir}/wbsockets":/run/samba/winbindd:z \
            -v "${workdir}/share":/share:z \
            -e SAMBA_CONTAINER_ID="${name}" \
            -e SAMBACC_CONFIG="/usr/local/etc/config.json" \
            "${ctrextraopts[@]}" \
            "${image}" \
            run \
            smbd
    ;;
    stop)
        podman pod stop wbtest
        podman pod rm wbtest
    ;;
    restart)
        "$0" "$1" stop
        "$0" "$1" start
    ;;
    clean)
        rm -rf "$workdir"
    ;;
    *)
        echo "Run smb filesharing with domain join in podman"
        echo ""
        echo "$0 <workdir> {start,stop,clean}"
        echo "   workdir: the directory to place shared container data"
        echo "   start:   start the pod"
        echo "   stop:    stop the pod"
        echo "   restart: stop and then start the pod"
        echo "   clean:   remove the shared workdir"
        echo ""
        echo "Example:"
        echo "  $0 /tmp/samba-container-demo start"
    ;;
esac
