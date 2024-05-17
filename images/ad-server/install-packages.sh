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
# reserve package_selection. keep args consistent with server image script.
# unused for ad image (for now)
# package_selection="$4"

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


# Assorted packages that must be installed in the container image to
# support the functioning of the container
support_packages=(\
    findutils \
    python-pip \
    python3-samba \
    python3-pyxattr \
    tdb-tools \
    procps-ng \
    /usr/bin/smbclient)
# Packages belonging to the samba install. If a samba_version_suffix is given
# all the samba_packages must share that version
samba_packages=(samba-dc)

# Assign version suffix to samba packages
samba_versioned_packages=()
for p in "${samba_packages[@]}"; do
    samba_versioned_packages+=("${p}${samba_version_suffix}")
done

dnf_cmd=(dnf)
if [[ "${OS_BASE}" = centos ]]; then
    dnf install -y epel-next-release
    dnf_cmd+=(--enablerepo=crb)
fi

"${dnf_cmd[@]}" \
    install --setopt=install_weak_deps=False -y \
    "${support_packages[@]}" \
    "${samba_versioned_packages[@]}"
dnf clean all

rm -rf /etc/samba/smb.conf
