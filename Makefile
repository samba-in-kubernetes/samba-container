CONTAINER_CMD ?=
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell docker version >/dev/null 2>&1 && echo docker)
endif
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman version >/dev/null 2>&1 && echo podman)
endif

SERVER_DIR:=images/samba
CLIENT_DIR:=images/client

build: build-server
.PHONY: build

build-server:
	$(CONTAINER_CMD) build --tag centos8:samba -f $(SERVER_DIR)/Dockerfile.centos8 $(SERVER_DIR)
.PHONY: build-server

push-server: build-server
	$(CONTAINER_CMD) image push centos8:samba quay.io/obnox/samba-centos8:latest
.PHONY: push-server

build-client:
	$(CONTAINER_CMD) build --tag centos8:samba-client -f $(CLIENT_DIR)/Dockerfile.centos8 $(CLIENT_DIR)
.PHONY: build-client

push-client: build-client
	$(CONTAINER_CMD) image push centos8:samba-client quay.io/obnox/samba-client-centos8:latest
.PHONY: push-client

test: build
	CONTAINER_COMMAND=$(CONTAINER_CMD) hack/test-samba-container.sh
.PHONY: test
