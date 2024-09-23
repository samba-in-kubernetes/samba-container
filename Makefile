SELF = $(lastword $(MAKEFILE_LIST))
ROOT_DIR = $(realpath $(dir $(SELF)))

CONTAINER_CMD ?=

ALT_BIN=$(CURDIR)/.bin
SHELLCHECK=$(shell command -v shellcheck || echo $(ALT_BIN)/shellcheck)
GITLINT=$(shell command -v gitlint || echo $(ALT_BIN)/gitlint)
YAMLLINT_CMD=$(shell command -v yamllint || echo $(ALT_BIN)/yamllint)
BUILD_IMAGE=$(ROOT_DIR)/hack/build-image --without-repo-bases


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
BUILDFILE_SERVER=$(shell $(call _BUILD_KP,server,default,--print-buildfile))
BUILDFILE_NIGHTLY_SERVER=$(shell $(call _BUILD_KP,server,nightly,--print-buildfile))
BUILDFILE_AD_SERVER=$(shell $(call _BUILD_KP,ad-server,default,--print-buildfile))
BUILDFILE_NIGHTLY_AD_SERVER=$(shell $(call _BUILD_KP,ad-server,nightly,--print-buildfile))
BUILDFILE_CLIENT=$(shell $(call _BUILD_KP,client,default,--print-buildfile))
BUILDFILE_TOOLBOX=$(shell $(call _BUILD_KP,toolbox,default,--print-buildfile))
DYN_BUILDFILE=$(shell $(call _BUILD_KP,$(KIND),$(if $(PACKAGE_SOURCE),$(PACKAGE_SOURCE),default),--print-buildfile) 2>/dev/null || echo invalid)

REPO_BASE=quay.io/samba.org/

_BUILD_KP=$(BUILD_IMAGE) $(if $(CONTAINER_CMD),--container-engine=$(CONTAINER_CMD)) $(BI_PREFIX_ARGS) --kind=$1 --package-source=$2 --distro-base=$(SRC_OS_NAME)  --repo-base=$(REPO_BASE) $3


build: build-server build-nightly-server build-ad-server build-client \
	build-toolbox
.PHONY: build


.PHONY: debug-vars
debug-vars:
	@echo OS_NAME: $(OS_NAME)
	@echo TAG: $(TAG)
	@echo NIGHTLY_TAG: $(NIGHTLY_TAG)
	@echo SERVER_NAME: $(SERVER_NAME)
	@echo NIGHTLY_SERVER_NAME: $(NIGHTLY_SERVER_NAME)
	@echo AD_SERVER_NAME: $(AD_SERVER_NAME)

	@echo BUILDFILE_SERVER: $(BUILDFILE_SERVER)
	@echo BUILDFILE_AD_SERVER: $(BUILDFILE_AD_SERVER)
	@echo BUILDFILE_NIGHTLY_AD_SERVER: $(BUILDFILE_iNIGHTLY_AD_SERVER)
	@echo BUILDFILE_NIGHTLY_SERVER: $(BUILDFILE_NIGHTLY_SERVER)
	@echo BUILDFILE_CLIENT: $(BUILDFILE_CLIENT)
	@echo BUILDFILE_TOOLBOX: $(BUILDFILE_TOOLBOX)

	@echo SERVER_SRC_FILE: $(SERVER_SRC_FILE)
	@echo AD_SERVER_SRC_FILE: $(AD_SERVER_SRC_FILE)
	@echo CLIENT_SERVER_SRC_FILE: $(CLIENT_SRC_FILE)
	@echo TOOLBOX_SRC_FILE: $(TOOLBOX_SRC_FILE)


### Image Build and Push Rules ###

build-image: $(DYN_BUILDFILE)
.PHONY: build-image

$(DYN_BUILDFILE):
	@[ "$(KIND)" ] || (echo "KIND must be specfied"; exit 1)
	$(call _BUILD_KP,$(KIND),$(if $(PACKAGE_SOURCE),$(PACKAGE_SOURCE),default)) $(EXTRA_BUILD_ARGS)

build-server: $(BUILDFILE_SERVER)
.PHONY: build-server
$(BUILDFILE_SERVER): Makefile $(SERVER_SRC_FILE) $(SERVER_SOURCES)
	$(call _BUILD_KP,server,default) $(EXTRA_BUILD_ARGS)

push-server: build-server
	$(call _BUILD_KP,server,default,--push)
.PHONY: push-server

build-nightly-server: $(BUILDFILE_NIGHTLY_SERVER)
.PHONY: build-nightly-server
$(BUILDFILE_NIGHTLY_SERVER): Makefile $(SERVER_SRC_FILE) $(SERVER_SOURCES)
	$(call _BUILD_KP,server,nightly) $(EXTRA_BUILD_ARGS)

push-nightly-server: build-nightly-server
	$(call _BUILD_KP,server,nightly,--push)
.PHONY: push-nightly-server

build-ad-server: $(BUILDFILE_AD_SERVER)
.PHONY: build-ad-server
$(BUILDFILE_AD_SERVER): Makefile $(AD_SERVER_SRC_FILE) $(AD_SERVER_SOURCES)
	$(call _BUILD_KP,ad-server,default) $(EXTRA_BUILD_ARGS)

push-ad-server: build-ad-server
	$(call _BUILD_KP,ad-server,default,--push)
.PHONY: push-ad-server

build-nightly-ad-server: $(BUILDFILE_NIGHTLY_AD_SERVER)
.PHONY: build-nightly-ad-server
$(BUILDFILE_NIGHTLY_AD_SERVER): Makefile $(AD_SERVER_SRC_FILE) $(AD_SERVER_SOURCES)
	$(call _BUILD_KP,ad-server,nightly) $(EXTRA_BUILD_ARGS)

push-nightly-ad-server: build-nightly-ad-server
	$(call _BUILD_KP,ad-server,nightly,--push)
.PHONY: push-nightly-ad-server

build-client: $(BUILDFILE_CLIENT)
.PHONY: build-client
$(BUILDFILE_CLIENT): Makefile $(CLIENT_SRC_FILE)
	$(call _BUILD_KP,client,default) $(EXTRA_BUILD_ARGS)

push-client: build-client
	$(call _BUILD_KP,client,default,--push)
.PHONY: push-client

build-toolbox: $(BUILDFILE_TOOLBOX)
.PHONY: build-toolbox
$(BUILDFILE_TOOLBOX): Makefile $(TOOLBOX_SRC_FILE)
	$(call _BUILD_KP,toolbox,default) $(EXTRA_BUILD_ARGS)

push-toolbox: build-toolbox
	$(call _BUILD_KP,toolbox,default,--push)
.PHONY: push-toolbox


### Test Rules: executes test scripts ###

test: test-server test-nightly-server
.PHONY: test

test-server: build-server
	CONTAINER_CMD=$(CONTAINER_CMD) \
		LOCAL_TAG=$(shell cat $(BUILDFILE_SERVER) |cut -d' ' -f2) \
		tests/test-samba-container.sh
.PHONY: test-server

test-nightly-server: $(BUILDFILE_NIGHTLY_SERVER)
	CONTAINER_CMD=$(CONTAINER_CMD) \
		LOCAL_TAG=$(shell cat $(BUILDFILE_NIGHTLY_SERVER) |cut -d' ' -f2) \
		tests/test-samba-container.sh
.PHONY: test-nightly-server


### Check Rules: static checks, quality tools ###

check: check-shell-scripts check-yaml
.PHONY: check
# rule requires shellcheck and find to run
check-shell-scripts: $(filter $(ALT_BIN)%,$(SHELLCHECK))
	$(SHELLCHECK) -P tests/ -eSC2181 -fgcc $$(find $(ROOT_DIR) -name "*.sh")
.PHONY: check-shell-scripts


check-yaml: $(filter $(ALT_BIN)%,$(YAMLLINT_CMD))
	$(YAMLLINT_CMD) -c $(CURDIR)/.yamllint.yaml $(CURDIR)
.PHONY: check-yaml

# not included in check to not disrupt wip branches
check-gitlint: $(filter $(ALT_BIN)%,$(GITLINT))
	$(GITLINT) -C .gitlint --commits origin/master.. lint
.PHONY: check-gitlint


### Misc. Rules ###

$(ALT_BIN)/%:
	$(CURDIR)/hack/install-tools.sh --$* $(ALT_BIN)

clean: clean-buildfiles clean-altbin
.PHONY: clean

clean-buildfiles:
	$(RM) $(BUILDFILE_PREFIX)*
.PHONY:  clean-buildfiles

clean-altbin:
	$(RM) -r $(ALT_BIN)
.PHONY: clean-altbin
