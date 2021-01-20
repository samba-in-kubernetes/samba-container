CONTAINER_CMD ?=
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell docker version >/dev/null 2>&1 && echo docker)
endif
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman version >/dev/null 2>&1 && echo podman)
endif

build:
	$(CONTAINER_CMD) build --tag centos8:samba -f ./Dockerfile.centos8 .
.PHONY: build

tag: build
	$(CONTAINER_CMD) tag centos8:samba quay.io/obnox/samba-centos8:latest
.PHONY: tag

push: tag
	$(CONTAINER_CMD) image push quay.io/obnox/samba-centos8:latest
.PHONY: push
