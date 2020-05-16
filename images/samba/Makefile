
build:
	podman build --tag centos8:samba -f ./Dockerfile.centos8

tag: build
	podman tag centos8:samba quay.io/obnox/samba-centos8:latest

push: tag
	podman image push quay.io/obnox/samba-centos8:latest

.PHONY: \
	build \
	tag \
	push
