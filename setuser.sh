#!/usr/bin/env bash

# create a samba user with specified name and password
# and configure the samba share to only grant this user access.

set -o nounset
set -e

usage() {
	echo "USAGE: $0 <username> <password>"
}

if [[ $# -eq 0 ]]; then
	echo "ERROR: username not provided."
	usage
	exit 1
fi

username="$1"

shift

password=""
if [[ $# -ne 0 ]]; then
        password="$1"
fi

useradd --no-create-home --user-group --shell /bin/false "$username"
if [[ -n "$password" ]]; then
        echo -e "$password\n$password" | smbpasswd -a -s "$username"
else
        cat | smbpasswd -a -s "$username"
fi

#net conf setparm share "write list" "$username"
#net conf setparm share "read list" "$username"
net conf setparm share "valid users" "$username"
