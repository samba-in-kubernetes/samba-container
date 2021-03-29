#!/bin/sh

set -e

REALM="DOMAIN1.SINK.TEST"
DOMAIN="DOMAIN1"
DCNAME="samba1"
PW="Passw0rd"

#if ! grep -q $HOSTNAME /etc/hosts ; then
#    echo "$HOSTNAME not found in /etc/hosts"
#    exit 1
#fi

echo 'Provisioning...'

samba-tool domain provision \
    --option="netbios name=${DCNAME}" \
    --use-rfc2307 \
    --dns-backend="SAMBA_INTERNAL" \
    --server-role=dc \
    --realm="${REALM}" \
    --domain="${DOMAIN}" \
    --adminpass="${PW}"

