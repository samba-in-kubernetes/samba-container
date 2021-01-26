CONTAINER_CMD ?=
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell docker version >/dev/null 2>&1 && echo docker)
endif
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman version >/dev/null 2>&1 && echo podman)
endif

BUILD_CMD:=$(CONTAINER_CMD) build $(BUILD_OPTS)
PUSH_CMD:=$(CONTAINER_CMD) push $(PUSH_OPTS)

SERVER_DIR:=images/samba
CLIENT_DIR:=images/client
SERVER_SRC_FILE:=$(SERVER_DIR)/Dockerfile.centos8
CLIENT_SRC_FILE:=$(CLIENT_DIR)/Dockerfile.centos8

TAG?=latest
SERVER_NAME:=samba-container:$(TAG)
CLIENT_NAME:=samba-client-container:$(TAG)
SERVER_REPO_NAME:=quay.io/obnox/samba-centos8:$(TAG)
SERVER_REPO_NAME:=quay.io/obnox/samba-client-centos8:$(TAG)


build: build-server build-client
.PHONY: build

build-server:
	$(BUILD_CMD) --tag $(SERVER_NAME) -f $(SERVER_SRC_FILE) $(SERVER_DIR)
.PHONY: build-server

push-server: build-server
	$(PUSH_CMD) $(SERVER_NAME) $(SERVER_REPO_NAME)
.PHONY: push-server

build-client:
	$(BUILD_CMD) --tag $(CLIENT_NAME) -f $(CLIENT_SRC_FILE) $(CLIENT_DIR)
.PHONY: build-client

push-client: build-client
	$(PUSH_CMD) $(CLIENT_NAME) $(CLIENT_REPO_NAME)
.PHONY: push-client

test: build
	CONTAINER_COMMAND=$(CONTAINER_CMD) LOCAL_TAG=$(SERVER_NAME) hack/test-samba-container.sh
.PHONY: test
