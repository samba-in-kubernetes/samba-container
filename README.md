# samba-container

Container images for [Samba](https://samba.org) services.

In the default configuration, the server container image exports one share,
named "share", which is expected to be a volume provided by the host. A default
user, named "sambauser" is predefined with a password of "samba".

The entrypoint for the server is the `samba-container` script. This tool is
designed to help automate the management of samba tools & services in a
container environment. This script is part of the
[sambacc project](https://github.com/samba-in-kubernetes/sambacc).
The behavior of this tool can customized via a JSON based configuration file.

The project also provides a simple samba client container image that can be
useful for testing.


## Build the container

```
make build
```

## Run the container

```
podman run --name samba --publish 10445:445 --volume=/path/on/host/to/share:/share:Z --rm  quay.io/samba.org/samba-server:latest
```

The port mapping (`--publish`) is only needed when running as non-root, e.g. for
testing purposes.

## Changing the configuration

The behavior of the container can be changed by invoking it with specific
arguments for the `samba-container` script and/or setting environment
variables.

You can include a custom configuration via the following method:
```
$EDITOR /path/to/config/config.json
podman run --name samba  --publish 10445:445 --volume=/path/on/host/to/share:/share:Z --volume=/path/to/config:/etc/samba-container -e SAMBACC_CONFIG=/etc/samba-container/config.json -e SAMBA_CONTAINER_ID=myid  --rm  quay.io/samba.org/samba-server:latest
```

The configuration may be used to define custom users or different share
configurations.
