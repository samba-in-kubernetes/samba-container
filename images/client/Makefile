build:
	podman build --tag centos8:samba-client -f ./Dockerfile.centos8

tag: build
	podman tag centos8:samba-client quay.io/obnox/samba-client-centos8:latest

push: tag
	podman image push quay.io/obnox/samba-client-centos8:latest

.PHONY: \
	build \
	tag \
	push
