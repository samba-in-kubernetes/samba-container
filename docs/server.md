
# Using the Samba Server Image

The container image for the Samba server defaults to the `samba-container`
entrypoint. If invoked without arguments, the container image defaults to the
arguments `run smbd`. You can bypass the `samba-container` entrypoint to run
any of the binaries in the container if you wish. However, the document that
follows assumes the use of the `samba-container` entrypoint.


The `samba-container` entrypoint is designed to make the container image
feel like a cohesive application rather than just a collection of parts.
However, there are times that a low-level understanding of Samba and its
parts are useful and this document will assume some familiarity
with Samba. If you're reading this document and find sections that you feel
need better explanation, please file an issue in our project.

The `samba-container` tool has a built in help system. Pass --help to
the command or after any subcommand (example: `run --help`) to
display the internal help text. The built-in help text will be the
most up to date reflecting the version in use, but likely terser than
this document.


## General Configuration

There are two critical values that control the samba-container tool.  First,
the command line option `--config` and the equivalent environment variable
`SAMBACC_CONFIG` specifies a path (or colon separated paths) to a JSON based
configuration file. The JSON based configuration can contain multiple
"instances" and so the `--identity` option and/or the equivalent environment
variable `SAMBA_CONTAINER_ID` provides a name to identify which configuration
to use.

The complete [documentation for the JSON configuration
file](https://github.com/samba-in-kubernetes/sambacc/blob/master/docs/configuration.md)
can be found in the sambacc project. A default configuration file is included
as part of container image which specifies a simple demonstration share.

Other global CLI options include:
* `--username`  For any command that may require a username, specify a user name.
* `--password` For any command that may require a password, specify a password.
* `--join-marker` Specify the location of a file that indicates a domain join
  has already been performed.
* `--samba-debug-level` Specify an integer, from 0 to 10, that will be
  passed to Samba commands for debugging purposes.
* `--skip-if-file` Specify the location of a file. If the file exists the
  command will be skipped (it will not be further executed).


## Running Servers

The `run` subcommand starts Samba servers. Valid Samba servers include: `smbd`,
`winbindd`, and `ctdbd`. For example to start smbd explicitly you can run
`podman run --rm --name smbd quay.io/samba.org/samba-server:latest run smbd` or
to start winbind execute `podman run --rm --name winbindd
quay.io/samba.org/samba-server:latest run winbindd`. The servers run in the foreground as is typical for application containers.

The option `--setup` may be specified one or more times. The values
to the setup option tell the tool what setup steps to perform before
starting up the server. This allows one to have more precise control
over the container configuration and environment.

Valid values include:
* `init-all` - A special value that tells the tool to perform all known
  and valid setup steps.
* `config` - Import sambacc configuration into Samba's configuration registry.
* `users` - Import users into the systems /etc files
* `users_passdb` - Import users into Samba's password db
* `nsswitch` - Configure the container's `/etc/nsswitch` file
* `share_paths` - Create and/or update Share paths and their permissions

Here's an example of running an smbd server with a specific set of setup steps.
One might want to do something like this if Samba's db files are persisted
across restarts of the container. Example:
`podman run --rm --name -v /var/lib/sambactr/var:/var/lib/samba smbd quay.io/samba.org/samba-server:latest run --setup=users --setup=nsswitch --setup=share_paths smbd`


## Environment & System Control

The `samba-container` tool provides a number of subcommands that help
configure the general environment that the Samba servers run in.
This includes the ephemeral system level files, Samba configuration,
and the data volume(s) that contain the shares.

### init

The `init` command works much like the `--setup=init-all` setup step,
only it exits after completion rather than trying to start a server.
This command can be used to prepare a directory (or directories) that
will be later be mapped into a running server container.

### import

The `import` command will import configuration parameters from the sambacc
config to samba's registry-based configuration database.

### ensure-share-paths

The `ensure-share-paths` command will examine the configured shares and check
if the share paths already exist. If not, the command will create them.
Depending on the configuration it may also check and/or update the permissions
on the share directories as well.

### import-users

The `import-users` command will take the users and groups listed in the
JSON based configuration file and translate them to the "system files"
`/etc/passwd` and `/etc/group` of the container. This allows the use of
local (non-domain) user logons.  Note that these files
are part of the ephemeral base image of the container and thus largely
exists to reflect the equivalent functionality in `--setup=users`.

### print-config

The `print-config` subcommand translates the JSON based configuration
into an smb.conf-style output of Samba specific parameters. It does not
change any configuration. It is most useful for debugging what configuration
values will be set by a sub-command like `import`.


For example, the default configuration of the server image:
```
podman run --rm quay.io/samba.org/samba-server:latest print-config
[global]
        security = user
        server min protocol = SMB2
        load printers = no
        printing = bsd
        printcap name = /dev/null
        disable spoolss = yes
        guest ok = no
        netbios name = SAMBA

[share]
        path = /share
        valid users = sambauser, otheruser
```


## Domain Join


The `samba-container` tool provides mechanisms that wrap Samba's domain
join functionality. The commands are only useful when the Samba state
directory `/var/lib/samba` is persisted.

The `join` command attempts an immediate domain join. The inputs for
domain credentials is outlined below. The `must-join` command will
check for available credentials but is allowed to wait until
credentials become available or another process performs the join.
The `must-join` subcommand is mostly useful when building a declarative
set of container commands and the pipeline should block until
the "instance" has been joined to a domain.

Both `join` and `must-join` support the options:
* `--insecure`  Enable sourcing a domain username/password from CLI arguments
  or environment variables
* `--no-insecure` Disable sourcing a domain username/password from CLI
  arguments or environment variables
* `--files` Enable sourcing a domain username/password from dedicated
  JSON files.
* `--no-files` Disable sourcing a domain username/password from dedicated
  JSON files.
* `--join-file` (`-j`) Specify the path to a JSON file containing a
  domain user's name and password. May be specified more than once.


The `join` command also supports the options:
* `--interactive`  Enable interactive password prompt
* `--no-interactive`  Disable interactive password prompt

The `must-join` command also supports the options:
* `--wait`  Do not exit until a join to the domain has been completed
* `--no-wait`  Exit even if a join has not been completed

For fully automated deployment of samba-server container with domain
access the best currently supported method is to combine the `must-join`
command with a secret store. For example, podman supports the `podman create
secret` command and the `--secret` option to the run command. This
allows one to store a JSON file with the required username and password.
Other systems such as Kubernetes can combine the Secret resource with
a store such as HashiCorp Vault.

However, if one is not comfortable with storing a domain user with a password a
partially automated deployment with a domain join can still be performed.  One
option is a workflow similar to a traditional Samba server on a physical or VM
host. Execute containers with the `init` and then `join` subcommands (with tty
support enabled (podman -it) and ensure that the Samba state directory(s) are
persisted before starting the servers.  Another option is to let the
`must-join` command run and while it is in its wait loop, exec into the
container and run the `join`.

Example:
```
$ podman run -d --rm --name joiner -v /var/lib/sambactr/var:/var/lib/samba quay.io/samba.org/samba-server:latest must-join --wait
$ podman exec --rm -it joiner
# samba-container join --interactive
```


# Dynamic Configuration

The `update-config` command can be used to support more dynamic configuration
in the case of a JSON configuration shared between the host and the container.
When the JSON configuration file is updated a container running `update-config`
in concert with an smbd (and optional winbind) container can automatically
update the configuration of the running Samba server.

The `update-config` command can be launched in a container that shares the
same pid namespace and persisted directories as the smbd/winbind containers.
It will automatically check the Samba configuration matches the JSON
configuration and update it if needed. It will also create any missing
shares and update permissions like the `ensure-share-paths` subcommand.

Passing the `--watch` option to `update-config` makes the process
continue running rather than exiting after the initial updates. Periodically,
this command will check for changes and repeat the configuration update
action.


# Combining Containers

In a typical hardware or VM based Samba installation that is a domain member
multiple server processes act in concert. The smbd process handles the SMB
protocol while winbindd takes care of integration with Active Directory.
Accomplishing this with the samba server containers is possible by starting
multiple containers with namespaces shared between them.

Namespaces that must be shared:
* PID Namespace
* UTS Namespace
* Network namespace

In addition you should share the directories/volumes that contain the samba
state files (samba's TDB databases). You do not have to expose the volumes or
directories containing shares to the winbind pod.

An example script setting this up using [podman CLI commands is available in
our examples
directory](https://github.com/samba-in-kubernetes/samba-container/blob/master/examples/podman/smb-wb-pod.sh).
Another example using [kubernetes
YAML](https://github.com/samba-in-kubernetes/samba-container/blob/master/examples/kubernetes/sambadmpod.yml)
is also available.


<!--
Skipping for now:
   All ctdb-* subcommands.
   dns-register - It's hard to explain outside the context of k8s at this time.
                  Perhaps it means this command is ripe for fixes?
   check - a bit low level, specific to k8s?
-->
