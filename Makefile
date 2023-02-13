CONTAINER_CMD ?=
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman version >/dev/null 2>&1 && echo podman)
endif
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell docker version >/dev/null 2>&1 && echo docker)
endif
# handle the case where podman is present but is (defaulting) to remote and is
# not not functioning correctly. Example: mac platform but no 'podman machine'
# vms are ready
ifeq ($(CONTAINER_CMD),)
	CONTAINER_CMD:=$(shell podman --version >/dev/null 2>&1 && echo podman)
ifneq ($(CONTAINER_CMD),)
$(warning podman detected but 'podman version' failed. \
	this may mean your podman is set up for remote use, but is not working)
endif
endif

BUILD_CMD:=$(CONTAINER_CMD) build $(BUILD_OPTS)
PUSH_CMD:=$(CONTAINER_CMD) push $(PUSH_OPTS)
SHELLCHECK:=shellcheck

SERVER_DIR:=images/server
AD_SERVER_DIR:=images/ad-server
CLIENT_DIR:=images/client
TOOLBOX_DIR:=images/toolbox
SERVER_SRC_FILE:=$(SERVER_DIR)/Containerfile.fedora
SERVER_SOURCES:=\
	$(SERVER_DIR)/smb.conf \
	$(SERVER_DIR)/install-packages.sh \
	$(SERVER_DIR)/install-sambacc.sh
AD_SERVER_SRC_FILE:=$(AD_SERVER_DIR)/Containerfile.fedora
AD_SERVER_SOURCES:=\
	$(AD_SERVER_DIR)/install-packages.sh \
	$(AD_SERVER_DIR)/install-sambacc.sh
CLIENT_SRC_FILE:=$(CLIENT_DIR)/Containerfile.fedora
TOOLBOX_SRC_FILE:=$(TOOLBOX_DIR)/Containerfile.fedora

TAG?=latest
NIGHTLY_TAG?=nightly

OS_NAME?= fedora


_REPO_BASE?=quay.io//samba.org/
SERVER_NAME:=samba-$(OS_NAME)-server-container:$(TAG)
NIGHTLY_SERVER_NAME:=samba-$(OS_NAME)-server-container:$(NIGHTLY_TAG)
AD_SERVER_NAME:=samba-$(OS_NAME)-ad-server-container:$(TAG)
NIGHTLY_AD_SERVER_NAME:=samba-$(OS_NAME)-ad-server-container:$(NIGHTLY_TAG)
CLIENT_NAME:=samba-$(OS_NAME)-client-container:$(TAG)

NIGHTLY_CLIENT_NAME:=samba-$(OS_NAME)-client-container:$(NIGHTLY_TAG)
TOOLBOX_NAME:=samba-$(OS_NAME)-toolbox-container:$(TAG)
NIGHTLY_TOOLBOX_NAME:=samba-$(OS_NAME)-toolbox-container:$(NIGHTLY_TAG)
SERVER_REPO_NAME:=$(REPO_BASE)$(SERVER_NAME)
EPOHTLY_SERVER_REPO_NAME:=$(REPO_BASE)$(NIGHTLY_SERVER_NAME)
AD_SERVER_NAME:=samba-$(OS_NAME)-ad-server-container:$(TAG)
NIGHTLY_AD_SERVER_NAME:=$(REPO_BASE)samba-$(OS_NAME)-ad-server-container:$(NIGHTLY_TAG)

CLIENT_NAME:=$(REPO_BASE)samba-$(OS_NAME)-client-container:$(TAG)
TOOLBOX_NAME:=$*REPO_BASE)samba-$(OS_NAME)-toolbox-container:$(TAG)

SERVER_REPO_NAME:=$(REPO_BASE)$(SERVER_NAME)
NIGHTLY_SERVER_REPO_NAME:=$(REPO_BASE)$(NIGHTLY_SERVER_NAME)

AD_SERVER_REPO_NAME:=$(REPO_BASE)$(AD_SERVER_NAME)
NIGHTLY_AD_SERVER_REPO_NAME:=$(REPO_BASE)$(NIGHLY_AD_SERVER_NAME)
CLIENT_REPO_NAME:=$(REPO_BASE)$(CLIENT_NAME)
NIGHTLY_CLIENT_REPO_NAME:=$(REPO_BASE)$(NIGHTLY_CLIENT_NAME)
TOOLBOX_REPO_NAME:=$(REPO_BASE)$(TOOLBOX_NAME)
NIGHTLY_TOOLBOX_REPO_NAME:=$(REPO_BASE)$(NIGHTLY_TOOLBOX_NAME)


BUILDFILE_SERVER:=.build.$(OS_NAME)-server
BUILDFILE_NIGHTLY_SERVER:=.build.nightly-$(OS_NAME)server
BUILDFILE_AD_SERVER:=.build.$(OS_NAME)-ad-server
BUILDFILE_NIGHTLY_AD_SERVER:=.build.nightly-$(OS_NAME)ad-server
BUILDFILE_TOOLBOX:=.build.$(OS_NAME)-toolbox
BUILDFILE_NIGHTLY_TOOLBOX:=.build.nightly-$(OS_NAME)-toolbox
BUILDFILE_CLIENT:=.build.$(OS_NAME)-client
BUILDFILE_NIGHTLY_CLIENT:=.build.nightly-$(OS_NAME)-client


build: build-server build-nightly-server build-ad-server build-client \
	build-toolbox
.PHONY: build

build-server: $(BUILDFILE_SERVER)
.PHONY: build-server
$(BUILDFILE_SERVER): Makefile $(SERVER_SRC_FILE) $(SERVER_SOURCES)
	$(BUILD_CMD) \
		--tag $(SERVER_NAME) --tag $(SERVER_REPO_NAME) \
		-f $(SERVER_SRC_FILE) $(SERVER_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(SERVER_NAME) > $(BUILDFILE_SERVER)

build-nightly-server: $(BUILDFILE_NIGHTLY_SERVER)
.PHONY: build-nightly-server
$(BUILDFILE_NIGHTLY_SERVER): Makefile $(SERVER_SRC_FILE) $(SERVER_SOURCES)
	$(BUILD_CMD) \
		--build-arg=INSTALL_PACKAGES_FROM="samba-nightly" \
		--tag $(NIGHTLY_SERVER_NAME) --tag $(NIGHTLY_SERVER_REPO_NAME) \
		-f $(SERVER_SRC_FILE) $(SERVER_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(NIGHTLY_SERVER_NAME) > $(BUILDFILE_NIGHTLY_SERVER)

push-server: build-server
	$(PUSH_CMD) $(SERVER_REPO_NAME)
.PHONY: push-server

push-nightly-server: build-nightly-server
	$(PUSH_CMD) $(NIGHTLY_SERVER_REPO_NAME)
.PHONY: push-nightly-server

build-ad-server: $(BUILDFILE_AD_SERVER)
.PHONY: build-ad-server
$(BUILDFILE_AD_SERVER): Makefile $(AD_SERVER_SRC_FILE) $(AD_SERVER_SOURCES)
	$(BUILD_CMD) --tag $(AD_SERVER_NAME) --tag $(AD_SERVER_REPO_NAME) -f $(AD_SERVER_SRC_FILE) $(AD_SERVER_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(AD_SERVER_NAME) > $(BUILDFILE_AD_SERVER)

build-nightly-ad-server: $(BUILDFILE_NIGHTLY_AD_SERVER)
.PHONY: build-nightly-ad-server
$(BUILDFILE_NIGHTLY_AD_SERVER): Makefile $(AD_SERVER_SRC_FILE) $(AD_SERVER_SOURCES)
	$(BUILD_CMD) \
		--build-arg=INSTALL_PACKAGES_FROM="samba-nightly" \
		--tag $(NIGHTLY_AD_SERVER_NAME) --tag $(NIGHTLY_AD_SERVER_REPO_NAME) \
		-f $(AD_SERVER_SRC_FILE) $(AD_SERVER_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(NIGHTLY_AD_SERVER_NAME) > $(BUILDFILE_NIGHTLY_AD_SERVER)

push-ad-server: build-ad-server
	$(PUSH_CMD) $(AD_SERVER_REPO_NAME)
.PHONY: push-ad-server

push-nightly-ad-server: build-nightly-ad-server
	$(PUSH_CMD) $(NIGHTLY_AD_SERVER_REPO_NAME)
.PHONY: push-nightly-ad-server

build-client: $(BUILDFILE_CLIENT)
.PHONY: build-client
$(BUILDFILE_CLIENT): Makefile $(CLIENT_SRC_FILE)
	$(BUILD_CMD) --tag $(CLIENT_NAME) --tag $(CLIENT_REPO_NAME) -f $(CLIENT_SRC_FILE) $(CLIENT_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(CLIENT_NAME) > $(BUILDFILE_CLIENT)

push-client: build-client
	$(PUSH_CMD) $(CLIENT_REPO_NAME)
.PHONY: push-client

test: test-server test-nightly-server
.PHONY: test

test-server: build-server
	CONTAINER_CMD=$(CONTAINER_CMD) LOCAL_TAG=$(SERVER_NAME) tests/test-samba-container.sh
.PHONY: test-server

test-nightly-server: build-nightly-server
	CONTAINER_CMD=$(CONTAINER_CMD) LOCAL_TAG=$(NIGHTLY_SERVER_NAME) tests/test-samba-container.sh
.PHONY: test-nightly-server


build-toolbox: $(BUILDFILE_TOOLBOX)
.PHONY: build-toolbox
$(BUILDFILE_TOOLBOX): Makefile $(TOOLBOX_SRC_FILE)
	$(BUILD_CMD) --tag $(TOOLBOX_NAME) --tag $(TOOLBOX_REPO_NAME) -f $(TOOLBOX_SRC_FILE) $(TOOLBOX_DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(TOOLBOX_NAME) > $(BUILDFILE_TOOLBOX)

push-toolbox: build-toolbox
	$(PUSH_CMD) $(TOOLBOX_REPO_NAME)
.PHONY: push-toolbox


check: check-shell-scripts
.PHONY: check

# rule requires shellcheck and find to run
check-shell-scripts:
	$(SHELLCHECK) -P tests/ -eSC2181 -fgcc $$(find  -name '*.sh')
.PHONY: check-shell-scripts

clean:
	$(RM) $(BUILDFILE_SERVER) $(BUILDFILE_NIGHTLY_SERVER) $(BUILDFILE_AD_SERVER) $(BUILDFILE_NIGHTLY_AD_SERVER) $(BUILDFILE_CLIENT) $(BUILDFILE_TOOLBOX)
.PHONY: clean
