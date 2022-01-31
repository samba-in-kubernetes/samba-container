#!/bin/sh
# Some K8S environments (OpenShift) encorage not to run containers with UID=0,
# though they do allow GID=0. Modify relevant parts of file-system accordingly
# so that smbd will not get -EPERM.
set -e
chmod 770 /etc
chmod 660 /etc/passwd
chmod 660 /etc/samba/smb.conf
chmod 770 /var/lib/samba
chmod 770 /var/lib/samba/private
chmod 770 /var/lib/samba/lock
