CONTAINER_CMD ?=
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell docker version >/dev/null 2>&1 && echo docker)
endif
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman version >/dev/null 2>&1 && echo podman)
endif

build:
	$(MAKE) -C images/samba build
.PHONY: build

test: build
	CONTAINER_COMMAND=$(CONTAINER_CMD) hack/test-samba-container.sh
.PHONY: test
