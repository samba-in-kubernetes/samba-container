
# Podman Examples

These examples demonstrate using samba container images with podman.

## Domain Joined SMB Shares

Included here is a shell script and a JSON config template that demonstrates
using podman to run an smbd instance joined to Active Directory.  Do note that
the Active Directory in question must already exist and permit new joins using
the Administrator account. You *must* edit the provided files to match your
domain/environment.

If you plan to run the pod with rootless podman do note that the smbd processes
make use of the setuid and setgroups system apis. Rootless podman is restricted
to a limited set of ids that are controlled by /etc/subuid and /etc/subgid. If
the ID range configured for winbind exceed these limits the smbd process will
panic when the user connects to the share. See the
[rootless podman documentation](https://github.com/containers/podman/blob/master/docs/tutorials/rootless_tutorial.md#etcsubuid-and-etcsubgid-configuration)
for more detail on this subject.

Example:
```
cd ./examples/podman
# configure the example config for your domain:
$EDITOR config.json
# tweak script parameters for your environment:
$EDITOR smb-wb-pod.sh

./smb-wb-pod.sh /tmp/samba-container-demo start
# wait a little bit
smbclient --port 4450 -U 'DOM\User%Pass' //localhost/share

# stop it
./smb-wb-pod.sh /tmp/samba-container-demo stop

# clean up working dir
./smb-wb-pod.sh /tmp/samba-container-demo clean
```

