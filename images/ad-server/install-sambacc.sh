#!/bin/bash

set -ex

# shellcheck source=images/common/install-sambacc-common.sh
. install-sambacc-common.sh
export DEFAULT_JSON_FILE=addc.json
install_sambacc "$@"
