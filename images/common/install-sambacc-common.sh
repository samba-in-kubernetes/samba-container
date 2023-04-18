#!/bin/bash

install_sambacc() {
    wheeldir="$1"
    if ! [ -d "${wheeldir}" ]; then
        echo "no directory: ${wheeldir}"
        exit 2
    fi

    mapfile -d '' wheels < \
        <(find "${wheeldir}" -type f -name 'sambacc-*.whl' -print0)
    mapfile -d '' rpmfiles < \
        <(find "${wheeldir}" -type f -name '*sambacc-*.noarch.rpm' -print0)


    if [ "${#wheels[@]}" -gt 1 ]; then
        echo "more than one wheel file found"
        exit 1
    elif [ "${#wheels[@]}" -eq 1 ]; then
        action=install-wheel
    fi

    if [ "${#rpmfiles[@]}" -gt 1 ]; then
        echo "more than one rpm file found"
        exit 1
    elif [ "${#rpmfiles[@]}" -eq 1 ]; then
        action=install-rpm
    fi

    if [ -z "${DEFAULT_JSON_FILE}" ]; then
        echo "DEFAULT_JSON_FILE value unset"
        exit 1
    fi

    case $action in
        install-wheel)
            pip install "${wheels[0]}"
            container_json_file="/usr/local/share/sambacc/examples/${DEFAULT_JSON_FILE}"
        ;;
        install-rpm)
            dnf install -y "${rpmfiles[0]}"
            dnf clean all
            container_json_file="/usr/share/sambacc/examples/${DEFAULT_JSON_FILE}"
        ;;
        *)
            echo "no install package(s) found"
            exit 1
        ;;
    esac

    if [ "$container_json_file" ]; then
        ln -sf "$container_json_file" /etc/samba/container.json
    fi
}
