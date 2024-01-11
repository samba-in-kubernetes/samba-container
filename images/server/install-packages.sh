#!/bin/bash

set -ex

get_custom_repo() {
    url="$1"
    fname="$(basename "$url")"
    dest="/etc/yum.repos.d/${fname}"
    dnf install --setopt=install_weak_deps=False -y /usr/bin/curl
    curl -L "$url" -o "$dest"
}

install_packages_from="$1"
samba_version_suffix="$2"
install_custom_repo="$3"

# shellcheck disable=SC1091
OS_BASE="$(. /etc/os-release && echo "${ID}")"

case "${install_packages_from}" in
    samba-nightly)
        get_custom_repo "https://artifacts.ci.centos.org/samba/pkgs/master/${OS_BASE}/samba-nightly-master.repo"
    ;;
    custom-repo)
        get_custom_repo "${install_custom_repo}"
    ;;
esac


dnf_cmd=(dnf)
if [[ "${OS_BASE}" = centos ]]; then
    dnf_cmd+=(--enablerepo=crb --enablerepo=resilientstorage)
fi

packages=(\
    findutils \
    python-pip \
    python3-samba \
    python3-pyxattr \
    "samba${samba_version_suffix}" \
    "samba-client${samba_version_suffix}" \
    "samba-winbind${samba_version_suffix}" \
    "samba-winbind-clients${samba_version_suffix}" \
    "samba-vfs-iouring${samba_version_suffix}" \
    tdb-tools \
    "ctdb${samba_version_suffix}")
if [[ "${OS_BASE}" = fedora ]]; then
    packages+=(\
        "samba-vfs-cephfs${samba_version_suffix}" \
        "samba-vfs-glusterfs${samba_version_suffix}" \
    )
fi
"${dnf_cmd[@]}" \
    install --setopt=install_weak_deps=False -y \
    "${packages[@]}"
dnf clean all

cp --preserve=all /etc/ctdb/functions /usr/share/ctdb/functions
cp --preserve=all /etc/ctdb/notify.sh /usr/share/ctdb/notify.sh
