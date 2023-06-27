# samba-container

Container images for [Samba](https://samba.org) services.

### Our images:
* Are [OCI](https://opencontainers.org/) formatted container images
* Provide application-like high-level entrypoint scripts
* Are available as pre-built stable and "nightly" [variants](#image-variants)
* Are used by the [samba-operator](https://github.com/samba-in-kubernetes/samba-operator) for Kubernetes
* Don't require Kubernetes
* Are [available at quay.io](https://quay.io/organization/samba.org)

### Image Types:

|Image Type   | Repository | Custom Entrypoint | Features |
|-------------|------------|-------------------|----------|
|[Samba Server](#samba-server) | [quay.io](https://quay.io/repository/samba.org/samba-server) | Yes | Standalone file server, Domain member file server |
|[AD Domain Controller](#ad-dc) | [quay.io](https://quay.io/repository/samba.org/samba-ad-server) | Yes | Active Directory Domain Controller |
|[Client](#client) | [quay.io](https://quay.io/repository/samba.org/samba-ad-server) | No | Basic Userspace Client Utilities |
|[Toolbox](#toolbox) | [quay.io](https://quay.io/repository/samba.org/samba-ad-server) | No | Extra debugging and testing tools |


## Samba Server

The Samba server image defaults to the `samba-container` entrypoint.

In the default configuration, the server container image exports one share,
named "share", with the path `/share` which is expected to be a volume provided
by the host. A default user, named "sambauser" is predefined with a password of
"samba". This simple mode of operation is great for quick demos. Example:

```sh
podman run --name samba --publish 10445:445 --volume=/path/on/host/to/share:/share:Z --rm  quay.io/samba.org/samba-server:latest
```
> **Note**
> The port mapping option (`--publish`) is only needed when running
> as non-root, e.g. for testing purposes.

The `samba-container` entrypoint can perform many functions and is
designed to make the container image act like a cohesive application.
It can automate the management of Samba as well as the container environment
to make them work together. This tool is provided by the
[sambacc project](https://github.com/samba-in-kubernetes/sambacc).

```sh
# print help
podman run --rm quay.io/samba.org/samba-server:latest --help
# print help for the run subcommand
podman run --rm quay.io/samba.org/samba-server:latest run --help
```

### Changing the configuration

The behavior of the container can be changed by invoking it with specific
arguments for the `samba-container` script and/or setting environment
variables.

You can include a custom configuration via the following method:
```
$EDITOR /path/to/config/config.json
podman run --name samba  --publish 10445:445 --volume=/path/on/host/to/share:/share:Z --volume=/path/to/config:/etc/samba-container -e SAMBACC_CONFIG=/etc/samba-container/config.json -e SAMBA_CONTAINER_ID=myid  --rm  quay.io/samba.org/samba-server:latest
```

<!-- TODO: link to advanced docs for samba server -->

## AD DC

The AD DC image defaults to the `samba-dc-container` entrypoint.

In the default configuration, the AD DC container image automatically
provisions and serves a simple stock domain `DOMAIN1.SINK.TEST`.
Because the Samba AD DC uses certain file system xattrs this container
must currently be run with privileges. Example:

```sh
podman run --rm --privileged  quay.io/samba.org/samba-ad-server:latest
```

The `samba-dc-container` entrypoint can perform multiple functions as is
designed to make the container image act like a cohesive application.
It helps automate the provisioning of and/or connection to a domain.
This tool is provided by the
[sambacc project](https://github.com/samba-in-kubernetes/sambacc).

<!-- TODO: link to advanced docs for samba server -->

## Client

The project provides a simple samba client container image that can be
useful for testing. One does not need to install the user space samba client
locally but rather use the container image. It can run the samba client
interactively when a TTY is available and can also be scripted for
automated testing purposes. Example:

```sh
podman run --rm -it   quay.io/samba.org/samba-client:latest
[root@dc0419d28c4e /]# smbclient -U 'sambauser' //foo.example.org/share
```

## Toolbox

The project provides a container image container containing the samba test
suite program
([smbtorture](https://wiki.samba.org/index.php/Writing_Torture_Tests)) as well
as the user space client. This can be used for debugging and testing purposes.
Example:

```sh
podman run --rm -it   quay.io/samba.org/samba-toolbox:latest
[root@dc0419d28c4e /]# smbtorture --help
```
## Image Variants

The server images come in two variants: stable and nightly. The
stable variant is what you get with the "latest" tag and includes
Samba packages from the Linux distribution used in our base images.
The "nightly" images are based on Samba packages created by the
[samba-integration project](https://github.com/gluster/samba-integration)
which builds and tests Samba builds before release. The nightly images
are tagged with "nightly" instead of "latest".

## Developers

### Building the containers

```sh
# Build Everything
make build
```

Each container image type has a build target:
```sh
# Build the server image
make build-server
# Build the server with "nightly" samba
make build-nightly-server
# Build the client
make build-client
# And so on...
```

There are matching `push-*` rules that default to pushing the images to the
"official" quay.io repositories. These rules can be executed by the appropriate
github actions or by project maintainers.
