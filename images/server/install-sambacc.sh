#!/bin/bash

set -ex

# shellcheck source=images/common/install-sambacc-common.sh
. install-sambacc-common.sh
export DEFAULT_JSON_FILE=minimal.json
install_sambacc "$@"
