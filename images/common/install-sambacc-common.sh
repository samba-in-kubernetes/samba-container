#!/bin/bash

install_sambacc() {
    local distdir="$1"
    local sambacc_version_suffix="$2"
    if ! [ -d "${distdir}" ]; then
        echo "warning: no directory: ${distdir}" >&2
    else
        mapfile -d '' artifacts < \
            <(find "${distdir}" -type f -print0)
    fi

    local wheels=()
    local rpmfiles=()
    local rpmextras=()
    local repofiles=()
    for artifact in "${artifacts[@]}" ; do
        if [[ ${artifact} =~ sambacc.*\.whl$ ]]; then
            wheels+=("${artifact}")
        fi
        if [[ ${artifact} =~ python.?-sambacc-.*\.noarch\.rpm$ ]]; then
            rpmfiles+=("${artifact}")
        fi
        if [[ ${artifact} =~ python.?-sambacc+.*\.noarch\.rpm$ ]]; then
            rpmextras+=("${artifact}")
        fi
        if [[ ${artifact} =~ sambacc.*\.repo$ ]]; then
            repofiles+=("${artifact}")
        fi
    done


    local action="" 
    echo "INFO: determining sambacc installation source." 
    if [ "${#wheels[@]}" -gt 0 ]; then
        echo "INFO: wheel found"
        if [ "${#wheels[@]}" -gt 1 ]; then
            echo "ERROR: more than one wheel file found"
            exit 1
        elif [ "${#wheels[@]}" -eq 1  ]; then
            action=install-wheel
        fi
    fi
    if [ "${#rpmfiles[@]}" -gt 0 ]; then
        echo "INFO: rpm file found"
        if [ "${#rpmfiles[@]}" -gt 1 ]; then
            echo "ERROR: more than one sambacc rpm file found"
            exit 1
        elif [ "${#rpmfiles[@]}" -eq 1 ]; then
            action=install-rpm
        fi
    fi
    if [ "${#repofiles[@]}" -gt 0 ]; then
       echo  "INFO: repo file found"
       if [ "${#repofiles[@]}" -gt 1 ]; then
           echo "ERROR: more than one repo file found"
           exit 1
       elif [ "${#repofiles[@]}" -eq 1 ]; then
           action=install-from-repo
       fi
    fi
    if [ -z "${action}" ]; then

        echo "INFO: no local sambacc installation source found. falling back to copr install."
        action=install-from-copr-repo
    fi

    echo "INFO: selected installation method: '${action}'"
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
            dnf install -y "${rpmfiles[0]}" "${rpmextras[@]}"
            dnf clean all
            container_json_file="/usr/share/sambacc/examples/${DEFAULT_JSON_FILE}"
        ;;
        install-from-repo)
            local tgt="${repofiles[0]}"
            cp "${tgt}" /etc/yum.repos.d/"$(basename "${tgt}")"
            dnf install -y "python3-sambacc${sambacc_version_suffix}"
            dnf clean all
            container_json_file="/usr/share/sambacc/examples/${DEFAULT_JSON_FILE}"
        ;;
        install-from-copr-repo)
            # shellcheck disable=SC1091
            OS_BASE="$(. /etc/os-release && echo "${ID}")"
            dnf install -y 'dnf-command(copr)'

            copr_args=("phlogistonjohn/sambacc")
            if [ "$OS_BASE" = centos ]; then
                # centos needs a little help determining what repository
                # within the copr to use. By default it only wants
                # to add `epel-9-$arch`.
                copr_args+=("centos-stream+epel-next-9-$(uname -p)")
            fi
            dnf copr enable -y "${copr_args[@]}"
            dnf install -y "python3-sambacc${sambacc_version_suffix}"
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
