#!/bin/sh

set -e

REALM="ZZZ-BEST.X.ASYNCHRONO.US"
DOM="ZZZ-BEST"
PW="Passw0rd"

#if ! grep -q $HOSTNAME /etc/hosts ; then
#    echo "$HOSTNAME not found in /etc/hosts"
#    exit 1
#fi

echo 'Provisioning...'

samba-tool domain provision \
    --option="netbios name=samba1" \
    --use-rfc2307 \
    --dns-backend="SAMBA_INTERNAL" \
    --server-role=dc \
    --realm="${REALM}" \
    --domain="${DOM}" \
    --adminpass="${PW}"

