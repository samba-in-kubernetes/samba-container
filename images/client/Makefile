build:
	podman build --tag centos8:samba-client -f ./Dockerfile.centos8
.PHONY: build

tag: build
	podman tag centos8:samba-client quay.io/obnox/samba-client-centos8:latest
.PHONY: tag

push: tag
	podman image push quay.io/obnox/samba-client-centos8:latest
.PHONY: push
