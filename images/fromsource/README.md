
fromsource
==========

Build a container that builds Samba.

The script `build.py` is intended to be run by developers on a local system.
You can set up a YAML file to configure build.py:

```yaml
job: demo
base_image: quay.io/centos/centos:stream9
artifacts_dir: /home/example/tmp/samba.out.d
tasks:
  - image
  - packages
```

```sh
./images/fromsource/build.py -c demo.yaml
```

Results will be written to `/home/example/tmp/samba.out.d/demo`.
