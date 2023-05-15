SELF = $(lastword $(MAKEFILE_LIST))
ROOT_DIR = $(realpath $(dir $(SELF)))

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

ALT_BIN=$(CURDIR)/.bin
SHELLCHECK=$(shell command -v shellcheck || echo $(ALT_BIN)/shellcheck)
GITLINT=$(shell command -v gitlint || echo $(ALT_BIN)/gitlint)

COMMON_DIR:=images/common
SERVER_DIR:=images/server
AD_SERVER_DIR:=images/ad-server
CLIENT_DIR:=images/client
TOOLBOX_DIR:=images/toolbox

OS_NAME=
SRC_OS_NAME=$(if $(OS_NAME),$(OS_NAME),fedora)

SERVER_SRC_FILE=$(SERVER_DIR)/Containerfile.$(SRC_OS_NAME)
SERVER_SOURCES=\
	$(SERVER_DIR)/smb.conf \
	$(SERVER_DIR)/install-packages.sh \
	$(SERVER_DIR)/install-sambacc.sh
AD_SERVER_SRC_FILE=$(AD_SERVER_DIR)/Containerfile.$(SRC_OS_NAME)
AD_SERVER_SOURCES=\
	$(AD_SERVER_DIR)/install-packages.sh \
	$(AD_SERVER_DIR)/install-sambacc.sh
CLIENT_SRC_FILE=$(CLIENT_DIR)/Containerfile.$(SRC_OS_NAME)
TOOLBOX_SRC_FILE=$(TOOLBOX_DIR)/Containerfile.$(SRC_OS_NAME)


BUILDFILE_PREFIX=.build
BUILDFILE_SERVER:=$(BUILDFILE_PREFIX).server
BUILDFILE_NIGHTLY_SERVER:=$(BUILDFILE_PREFIX).nightly-server
BUILDFILE_AD_SERVER:=$(BUILDFILE_PREFIX).ad-server
BUILDFILE_NIGHTLY_AD_SERVER:=$(BUILDFILE_PREFIX).nightly-ad-server
BUILDFILE_CLIENT:=$(BUILDFILE_PREFIX).client
BUILDFILE_TOOLBOX:=$(BUILDFILE_PREFIX).toolbox
OS_PREFIX=$(addsuffix -,$(OS_NAME))
TAG=$(OS_PREFIX)latest
NIGHTLY_TAG=$(OS_PREFIX)nightly


SERVER_NAME=samba-server:$(TAG)
NIGHTLY_SERVER_NAME=samba-server:$(NIGHTLY_TAG)
AD_SERVER_NAME= samba-ad-server:$(TAG)
NIGHTLY_AD_SERVER_NAME=samba-ad-server:$(NIGHTLY_TAG)
CLIENT_NAME=samba-client:$(TAG)
NIGHTLY_CLIENT_NAME=samba-client:$(NIGHTLY_TAG)
TOOLBOX_NAME=samba-toolbox:$(TAG)
NIGHTLY_TOOLBOX_NAME=samba-toolbox:$(NIGHTLY_TAG)

REPO_BASE=quay.io/samba.org/
SERVER_REPO_NAME=$(REPO_BASE)$(SERVER_NAME)
NIGHTLY_SERVER_REPO_NAME=$(REPO_BASE)$(NIGHTLY_SERVER_NAME)
AD_SERVER_REPO_NAME=$(REPO_BASE)$(AD_SERVER_NAME)
NIGHTLY_AD_SERVER_REPO_NAME=$(REPO_BASE)$(NIGHTLY_AD_SERVER_NAME)
CLIENT_REPO_NAME=$(REPO_BASE)$(CLIENT_NAME)
NIGHTLY_CLIENT_REPO_NAME=$(REPO_BASE)$(NIGHTLY_CLIENT_NAME)
TOOLBOX_REPO_NAME=$(REPO_BASE)$(TOOLBOX_NAME)
NIGHTLY_TOOLBOX_REPO_NAME=$(REPO_BASE)$(NIGHTLY_TOOLBOX_NAME)

BUILDFILE_PREFIX=.build
BUILDFILE_SERVER=$(BUILDFILE_PREFIX).$(OS_PREFIX)server
BUILDFILE_NIGHTLY_SERVER=$(BUILDFILE_PREFIX).$(OS_PREFIX)nightly-server
BUILDFILE_AD_SERVER=$(BUILDFILE_PREFIX).$(OS_PREFIX)ad-server
BUILDFILE_NIGHTLY_AD_SERVER=$(BUILDFILE_PREFIX).$(OS_PREFIX)nightly-ad-server
BUILDFILE_CLIENT=$(BUILDFILE_PREFIX).$(OS_PREFIX)client
BUILDFILE_NIGHTLY_CLIENT=$(BUILDFILE_PREFIX).$(OS_PREFIX)nightly-client
BUILDFILE_TOOLBOX=$(BUILDFILE_PREFIX).$(OS_PREFIX)toolbox
BUILDFILE_NIGHTLY_TOOLBOX=$(BUILDFILE_PREFIX).$(OS_PREFIX)nightly-toolbox

HOST_ARCH:=$(shell arch)
HOST_ARCH:=$(subst x86_64,amd64,$(HOST_ARCH))
HOST_ARCH:=$(subst aarch64,arm64,$(HOST_ARCH))

# build_fqin is a function macro for building a "Fully Qualified Image Name".
# Usage: $(call build_fqin,<base-name>,<pkg-source>,<os-name>,<arch>,[<extra>])
#   base-name: the last part of the repo name eg. 'samba-server'
#   pkg-source: source for samba packages (default or nightly)
#   os-name: base os name
#   arch: architecture of image (amd64, arm64, etc.)
#   extra: (optional) an additional unique suffix for the tag
#          typically meant for use by devs building custom images
build_fqin=$(REPO_BASE)$(1):$(2)-$(3)-$(4)$(if $(5),-$(5))

# get_imagename is a function macro for getting only the base image name
# without the tag part.
# Usage: $(call get_imagename,<image-name>)
get_imagename=$(firstword $(subst :, ,$1))

# get_pkgsource is a function macro that, given an images name returns
# the name of the package source. Currently only understands the
# difference between default (os packages) and nightly (SIT packages).
# Usage: $(call, get_pkgsource,<image-name>)
get_pkgsource=$(if $(findstring nightly,$1),nightly,default)


build: build-server build-nightly-server build-ad-server build-client \
	build-toolbox
.PHONY: build


.PHONY: debug-vars
debug-vars:
	@echo OS_NAME: $(OS_NAME)
	@echo OS_PREFIX: $(OS_PREFIX)
	@echo TAG: $(TAG)
	@echo NIGHTLY_TAG: $(NIGHTLY_TAG)
	@echo SERVER_NAME: $(SERVER_NAME)
	@echo SERVER_REPO_NAME: $(SERVER_REPO_NAME)
	@echo NIGHTLY_SERVER_REPO_NAME: $(NIGHTLY_SERVER_REPO_NAME)
	@echo NIGHTLY_SERVER_NAME: $(NIGHTLY_SERVER_NAME)
	@echo AD_SERVER_NAME: $(AD_SERVER_NAME)
	@echo AD_SERVER_REPO_NAME: $(AD_SERVER_REPO_NAME)
	@echo NIGHTLY_AD_SERVER_NAME: $(NIGHTLY_AD_SERVER_NAME)
	@echo NIGHTLY_AD_SERVER_NAME: $(NIGHTLY_AD_SERVER_NAME)
	@echo NIGHTLY_AD_SERVER_REPO_NAME: $(NIGHTLY_AD_SERVER_REPO_NAME)
	@echo CLIENT_NAME: $(CLIENT_NAME)
	@echo CLIENT_REPO_NAME: $(CLIENT_REPO_NAME)
	@echo NIGHTLY_CLIENT_NAME: $(NIGHTLY_CLIENT_NAME)
	@echo NIGHTLY_CLIENT_REPO_NAME: $(NIGHTLY_CLIENT_REPO_NAME)
	@echo TOOLBOX_NAME: $(TOOLBOX_NAME)
	@echo TOOLBOX_REPO_NAME: $(TOOLBOX_REPO_NAME)
	@echo NIGHTLY_TOOLBOX_NAME: $(NIGHTLY_TOOLBOX_NAME)
	@echo NIGHTLY_TOOLBOX_REPO_NAME: $(NIGHTLY_TOOLBOX_REPO_NAME)

	@echo BUILDFILE_SERVER: $(BUILDFILE_SERVER)
	@echo BUILDFILE_AD_SERVER: $(BUILDFILE_AD_SERVER)
	@echo BUILDFILE_NIGHTLY_AD_SERVER: $(BUILDFILE_iNIGHTLY_AD_SERVER)
	@echo BUILDFILE_NIGHTLY_SERVER: $(BUILDFILE_NIGHTLY_SERVER)
	@echo BUILDFILE_CLIENT: $(BUILDFILE_CLIENT)
	@echo BUILDFILE_TOOLBOX: $(BUILDFILE_TOOLBOX)
	@echo BUILDFILE_NIGHTLY_TOOLBOX: $(BUILDFILE_NIGHTLY_TOOLBOX)

	@echo SERVER_SRC_FILE: $(SERVER_SRC_FILE)
	@echo AD_SERVER_SRC_FILE: $(AD_SERVER_SRC_FILE)
	@echo CLIENT_SERVER_SRC_FILE: $(CLIENT_SRC_FILE)
	@echo TOOLBOX_SRC_FILE: $(TOOLBOX_SRC_FILE)


### Image Build and Push Rules ###

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

push-server: build-server
	$(PUSH_CMD) $(SERVER_REPO_NAME)
.PHONY: push-server

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

push-ad-server: build-ad-server
	$(PUSH_CMD) $(AD_SERVER_REPO_NAME)
.PHONY: push-ad-server

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


### Test Rules: executes test scripts ###

test: test-server test-nightly-server
.PHONY: test

test-server: build-server
	CONTAINER_CMD=$(CONTAINER_CMD) LOCAL_TAG=$(SERVER_NAME) tests/test-samba-container.sh
.PHONY: test-server

test-nightly-server: build-nightly-server
	CONTAINER_CMD=$(CONTAINER_CMD) LOCAL_TAG=$(NIGHTLY_SERVER_NAME) tests/test-samba-container.sh
.PHONY: test-nightly-server


### Check Rules: static checks, quality tools ###

check: check-shell-scripts
.PHONY: check

# rule requires shellcheck and find to run
check-shell-scripts: $(filter $(ALT_BIN)%,$(SHELLCHECK))
	$(SHELLCHECK) -P tests/ -eSC2181 -fgcc $$(find $(ROOT_DIR) -name "*.sh")
.PHONY: check-shell-scripts

# not included in check to not disrupt wip branches
check-gitlint: $(filter $(ALT_BIN)%,$(GITLINT))
	$(GITLINT) -C .gitlint --commits origin/master.. lint
.PHONY: check-gitlint

### Misc. Rules ###

clean:
	$(RM) $(BUILDFILE_PREFIX)*
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
_img_build: $(DIR)/.common
	$(BUILD_CMD) \
		$(BUILD_ARGS) \
		$(if $(filter-out $(HOST_ARCH),$(BUILD_ARCH)),--arch $(BUILD_ARCH)) \
		$(EXTRA_BUILD_ARGS) \
		--tag $(SHORT_NAME) \
		--tag $(REPO_NAME) \
		--tag $(call build_fqin,$(call get_imagename,$(SHORT_NAME)),$(call get_pkgsource,$(SHORT_NAME)),$(SRC_OS_NAME),$(if $(BUILD_ARCH),$(BUILD_ARCH),$(HOST_ARCH)),$(EXTRA_TAG)) \
		-f $(SRC_FILE) \
		$(DIR)
	$(CONTAINER_CMD) inspect -f '{{.Id}}' $(SHORT_NAME) > $(BUILDFILE)
.PHONY: _img_build

$(DIR)/.common: $(COMMON_DIR)
	$(RM) -r $(DIR)/.common
	cp -r $(COMMON_DIR) $(DIR)/.common

$(ALT_BIN)/%:
	$(CURDIR)/hack/install-tools.sh --$* $(ALT_BIN)

clean-altbin:
	$(RM) -r $(ALT_BIN)
.PHONY: clean-altbin
