CONTAINER_CMD ?=
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman version >/dev/null 2>&1 && echo podman)
endif
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell docker version >/dev/null 2>&1 && echo docker)
endif

BUILD_CMD:=$(CONTAINER_CMD) build $(BUILD_OPTS)
PUSH_CMD:=$(CONTAINER_CMD) push $(PUSH_OPTS)

SERVER_DIR:=images/server
AD_SERVER_DIR:=images/ad-server
CLIENT_DIR:=images/client
SERVER_SRC_FILE:=$(SERVER_DIR)/Dockerfile.fedora
SERVER_SOURCES:=$(SERVER_DIR)/smb.conf
AD_SERVER_SRC_FILE:=$(AD_SERVER_DIR)/Containerfile
AD_SERVER_SOURCES:=$(AD_SERVER_DIR)/populate.sh $(AD_SERVER_DIR)/provision.sh $(AD_SERVER_DIR)/run.sh
CLIENT_SRC_FILE:=$(CLIENT_DIR)/Dockerfile

TAG?=latest
SERVER_NAME:=samba-container:$(TAG)
AD_SERVER_NAME:=samba-ad-container:$(TAG)
CLIENT_NAME:=samba-client-container:$(TAG)

SERVER_REPO_NAME:=quay.io/samba.org/samba-server:$(TAG)
AD_SERVER_REPO_NAME:=quay.io/samba.org/samba-ad-server:$(TAG)
CLIENT_REPO_NAME:=quay.io/samba.org/samba-client:$(TAG)

BUILDFILE_SERVER:=.build.server
BUILDFILE_AD_SERVER:=.build.ad-server
BUILDFILE_CLIENT:=.build.client

build: build-server build-ad-server build-client
.PHONY: build

build-server: $(BUILDFILE_SERVER)
$(BUILDFILE_SERVER): Makefile $(SERVER_SRC_FILE) $(SERVER_SOURCES)
	$(BUILD_CMD) --tag $(SERVER_NAME) --tag $(SERVER_REPO_NAME) -f $(SERVER_SRC_FILE) $(SERVER_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(SERVER_NAME) > $(BUILDFILE_SERVER)

push-server: build-server
	$(PUSH_CMD) $(SERVER_REPO_NAME)
.PHONY: push-server

build-ad-server: $(BUILDFILE_AD_SERVER)
$(BUILDFILE_AD_SERVER): Makefile $(AD_SERVER_SRC_FILE) $(AD_SERVER_SOURCES)
	$(BUILD_CMD) --tag $(AD_SERVER_NAME) --tag $(AD_SERVER_REPO_NAME) -f $(AD_SERVER_SRC_FILE) $(AD_SERVER_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(AD_SERVER_NAME) > $(BUILDFILE_AD_SERVER)

push-ad-server: build-ad-server
	$(PUSH_CMD) $(AD_SERVER_REPO_NAME)
.PHONY: push-ad-server

build-client: $(BUILDFILE_CLIENT)
$(BUILDFILE_CLIENT): Makefile $(CLIENT_SRC_FILE)
	$(BUILD_CMD) --tag $(CLIENT_NAME) --tag $(CLIENT_REPO_NAME) -f $(CLIENT_SRC_FILE) $(CLIENT_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(CLIENT_NAME) > $(BUILDFILE_CLIENT)

push-client: build-client
	$(PUSH_CMD) $(CLIENT_REPO_NAME)
.PHONY: push-client

test: test-server
.PHONY: test

test-server: build-server
	CONTAINER_CMD=$(CONTAINER_CMD) LOCAL_TAG=$(SERVER_NAME) tests/test-samba-container.sh
.PHONY: test-server
