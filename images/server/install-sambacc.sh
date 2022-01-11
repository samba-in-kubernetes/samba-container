#!/bin/bash

set -ex

wheeldir="$1"
container_json_file="$2"

wheeldir=/tmp
wheel="$(find "${wheeldir}" -type f -name 'sambacc-*.whl')" \

if ! [ "$(echo "$wheel" | wc -l)" = 1 ]; then
    echo "more than one wheel file found"
    exit 1
fi

pip install "$wheel"
rm -f "$wheel"

if [ "$container_json_file" ]; then
    ln -sf "$container_json_file" /etc/samba/container.json
fi
