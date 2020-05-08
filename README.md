# samba-container

Simple samba container that exports one share "share",
which should be handed in from the host.
Just one user is given access to the samba share.
By default, this is "sambauser" with password "samba".


## Build the container

```
make build
```

## Run the container

```
podman run --name samba --publish 10139:139 --publish 10445:445 --volume=/path/on/host/to/share:/share:Z --rm  samba-centos8:latest
```

The port mapping (`--publish`) is only needed when running as non-root, e.g. for
testing purposes.

## changing the user

The "setuser" script can be used to create a new user
and reconfigure samba to restrict access to this user.

Example:

```
podman exec samba-c8 setuser.sh <username> <password>
```

Similarly for use in scripts:

```
echo -e "pass\npass" | podman exec -i samba-c8 setuser.sh <username>
```
