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
SERVER_NAME:=samba-container:$(TAG)
NIGHTLY_SERVER_NAME:=samba-container:nightly
AD_SERVER_NAME:=samba-ad-container:$(TAG)
NIGHTLY_AD_SERVER_NAME:=samba-ad-container:nightly
CLIENT_NAME:=samba-client-container:$(TAG)
TOOLBOX_NAME:=samba-toolbox-container:$(TAG)

SERVER_REPO_NAME:=quay.io/samba.org/samba-server:$(TAG)
NIGHTLY_SERVER_REPO_NAME:=quay.io/samba.org/samba-server:nightly
AD_SERVER_REPO_NAME:=quay.io/samba.org/samba-ad-server:$(TAG)
NIGHTLY_AD_SERVER_REPO_NAME:=quay.io/samba.org/samba-ad-server:nightly
CLIENT_REPO_NAME:=quay.io/samba.org/samba-client:$(TAG)
TOOLBOX_REPO_NAME:=quay.io/samba.org/samba-toolbox:$(TAG)

BUILDFILE_SERVER:=.build.server
BUILDFILE_NIGHTLY_SERVER:=.build.nightly-server
BUILDFILE_AD_SERVER:=.build.ad-server
BUILDFILE_NIGHTLY_AD_SERVER:=.build.nightly-ad-server
BUILDFILE_CLIENT:=.build.client
BUILDFILE_TOOLBOX:=.build.toolbox

build: build-server build-nightly-server build-ad-server build-client \
	build-toolbox
.PHONY: build

build-server: $(BUILDFILE_SERVER)
.PHONY: build-server
$(BUILDFILE_SERVER): Makefile $(SERVER_SRC_FILE) $(SERVER_SOURCES)
	$(MAKE) _img_build \
		BUILD_ARGS=""  \
		EXTRA_BUILD_ARGS="$(EXTRA_BUILD_ARGS)" \
		SHORT_NAME=$(SERVER_NAME) \
		REPO_NAME=$(SERVER_REPO_NAME) \
		SRC_FILE=$(SERVER_SRC_FILE) \
		DIR=$(SERVER_DIR) \
		BUILDFILE=$(BUILDFILE_SERVER)

build-nightly-server: $(BUILDFILE_NIGHTLY_SERVER)
.PHONY: build-nightly-server
$(BUILDFILE_NIGHTLY_SERVER): Makefile $(SERVER_SRC_FILE) $(SERVER_SOURCES)
	$(MAKE) _img_build \
		BUILD_ARGS="--build-arg=INSTALL_PACKAGES_FROM='samba-nightly'"  \
		EXTRA_BUILD_ARGS="$(EXTRA_BUILD_ARGS)" \
		SHORT_NAME=$(NIGHTLY_SERVER_NAME) \
		REPO_NAME=$(NIGHTLY_SERVER_REPO_NAME) \
		SRC_FILE=$(SERVER_SRC_FILE) \
		DIR=$(SERVER_DIR) \
		BUILDFILE=$(BUILDFILE_NIGHTLY_SERVER)

push-server: build-server
	$(PUSH_CMD) $(SERVER_REPO_NAME)
.PHONY: push-server

push-nightly-server: build-nightly-server
	$(PUSH_CMD) $(NIGHTLY_SERVER_REPO_NAME)
.PHONY: push-nightly-server

build-ad-server: $(BUILDFILE_AD_SERVER)
.PHONY: build-ad-server
$(BUILDFILE_AD_SERVER): Makefile $(AD_SERVER_SRC_FILE) $(AD_SERVER_SOURCES)
	$(MAKE) _img_build \
		BUILD_ARGS="" \
		EXTRA_BUILD_ARGS="$(EXTRA_BUILD_ARGS)" \
		SHORT_NAME=$(AD_SERVER_NAME) \
		REPO_NAME=$(AD_SERVER_REPO_NAME) \
		SRC_FILE=$(AD_SERVER_SRC_FILE) \
		DIR=$(AD_SERVER_DIR) \
		BUILDFILE=$(BUILDFILE_AD_SERVER)

build-nightly-ad-server: $(BUILDFILE_NIGHTLY_AD_SERVER)
.PHONY: build-nightly-ad-server
$(BUILDFILE_NIGHTLY_AD_SERVER): Makefile $(AD_SERVER_SRC_FILE) $(AD_SERVER_SOURCES)
	$(MAKE) _img_build \
		BUILD_ARGS="--build-arg=INSTALL_PACKAGES_FROM='samba-nightly'" \
		EXTRA_BUILD_ARGS="$(EXTRA_BUILD_ARGS)" \
		SHORT_NAME=$(NIGHTLY_AD_SERVER_NAME) \
		REPO_NAME=$(NIGHTLY_AD_SERVER_REPO_NAME) \
		SRC_FILE=$(AD_SERVER_SRC_FILE) \
		DIR=$(AD_SERVER_DIR) \
		BUILDFILE=$(BUILDFILE_NIGHTLY_AD_SERVER)

push-ad-server: build-ad-server
	$(PUSH_CMD) $(AD_SERVER_REPO_NAME)
.PHONY: push-ad-server

push-nightly-ad-server: build-nightly-ad-server
	$(PUSH_CMD) $(NIGHTLY_AD_SERVER_REPO_NAME)
.PHONY: push-nightly-ad-server

build-client: $(BUILDFILE_CLIENT)
.PHONY: build-client
$(BUILDFILE_CLIENT): Makefile $(CLIENT_SRC_FILE)
	$(MAKE) _img_build \
		BUILD_ARGS="" \
		EXTRA_BUILD_ARGS="$(EXTRA_BUILD_ARGS)" \
		SHORT_NAME=$(CLIENT_NAME) \
		REPO_NAME=$(CLIENT_REPO_NAME) \
		SRC_FILE=$(CLIENT_SRC_FILE) \
		DIR=$(CLIENT_DIR) \
		BUILDFILE=$(BUILDFILE_CLIENT)

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
	$(MAKE) _img_build \
		BUILD_ARGS="" \
		EXTRA_BUILD_ARGS="$(EXTRA_BUILD_ARGS)" \
		SHORT_NAME=$(TOOLBOX_NAME) \
		REPO_NAME=$(TOOLBOX_REPO_NAME) \
		SRC_FILE=$(TOOLBOX_SRC_FILE) \
		DIR=$(TOOLBOX_DIR) \
		BUILDFILE=$(BUILDFILE_TOOLBOX)

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

# _img_build is an "internal" rule to make the building of samba-container
# images regular and more "self documenting". A makefile.foo that includes
# this Makefile can add build rules using _img_build as a building block.
#
# The following arguments are expected to be supplied when "calling" this rule:
# BUILD_ARGS: the default build arguments
# EXTRA_BUILD_ARGS: build args supplied by the user at "runtime"
# SHORT_NAME: a local name for the image
# REPO_NAME: a global name for the image
# SRC_FILE: path to the Containerfile (Dockerfile)
# DIR: path to the directory holding image contents
# BUILDFILE: path to a temporary file tracking build state
_img_build:
	$(BUILD_CMD) \
		$(BUILD_ARGS) \
		$(EXTRA_BUILD_ARGS) \
		--tag $(SHORT_NAME) \
		--tag $(REPO_NAME) \
		-f $(SRC_FILE) \
		$(DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(SHORT_NAME) > $(BUILDFILE)
.PHONY: _img_build
