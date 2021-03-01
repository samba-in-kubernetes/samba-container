#!/bin/sh

if ! [ -f /etc/samba/smb.conf ]; then
    provision.sh
fi

# if the POPULATE env var is set, run it to populate the AD
if [ "${POPULATE}" ]; then
    if [ ! -e "/var/lib/samba/POPULATED" ]; then
        echo "Populating..."
        if "${POPULATE}" ; then
            touch "/var/lib/samba/POPULATED"
        else
            exit 1
        fi
    fi
fi

echo 'Starting...'

cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
samba -F
if $? -ne 0 ; then
    echo "FAILED"
    sleep infinity
    exit 1
fi

