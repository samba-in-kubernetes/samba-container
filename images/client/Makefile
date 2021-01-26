CONTAINER_CMD ?=
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell docker version >/dev/null 2>&1 && echo docker)
endif
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman version >/dev/null 2>&1 && echo podman)
endif

build:
	$(CONTAINER_CMD) build --tag centos8:samba-client -f ./Dockerfile.centos8 .
.PHONY: build

push: build
	$(CONTAINER_CMD) image push centos8:samba-client quay.io/obnox/samba-client-centos8:latest
.PHONY: push
