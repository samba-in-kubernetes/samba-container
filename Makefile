build: build.centos8

build.centos8:
	podman build --tag centos8:samba -f ./Dockerfile.centos8

tag.centos8: build.centos8
	podman tag centos8:samba quay.io/obnox/samba-centos8:latest

push.centos8: tag.centos8
	podman image push quay.io/obnox/samba-centos8:latest

.PHONY: \
	build \
	build.centos8 \
	tag.centos8 \
	push.centos8
