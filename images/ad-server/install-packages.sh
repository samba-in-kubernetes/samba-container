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
    dnf install -y epel-next-release
    dnf_cmd+=(--enablerepo=crb)
fi

packages=(\
    findutils \
    python-pip \
    python3-samba \
    python3-pyxattr \
    tdb-tools \
    "samba-dc${samba_version_suffix}" \
    procps-ng \
    /usr/bin/smbclient)
"${dnf_cmd[@]}" \
    install --setopt=install_weak_deps=False -y \
    "${packages[@]}"
dnf clean all

rm -rf /etc/samba/smb.conf
