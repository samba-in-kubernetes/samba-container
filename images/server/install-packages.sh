#!/bin/bash

set -ex


need_curl() {
    if command -v curl >/dev/null ; then
        return 0
    fi
    dnf install --setopt=install_weak_deps=False -y /usr/bin/curl
}

get_custom_repo() {
    url="$1"
    fname="$(basename "$url")"
    dest="/etc/yum.repos.d/${fname}"
    need_curl
    curl -L "$url" -o "$dest"
}

generate_repo_from_shaman() {
    url="$1"
    dest="/etc/yum.repos.d/$2"
    need_curl
    tmpfile=/tmp/shaman.json
    curl -L "$url" -o "${tmpfile}" && python3 <<EOF
json_file = "${tmpfile}"
dest = "${dest}"
import json
r = json.load(open(json_file))
url = r[0]["url"]
ref = r[0]["ref"]
with open(dest, "w") as out:
    print(f"[ceph-{ref}]", file=out)
    print(f"name=Ceph Development Build ({ref})", file=out)
    print(f"baseurl={url}/x86_64", file=out)
    print("enabled=1", file=out)
    print("gpgcheck=0", file=out)
EOF
    rm -rf "${tmpfile}"
}

install_packages_from="$1"
samba_version_suffix="$2"
install_custom_repo="$3"
package_selection="$4"

# shellcheck disable=SC1091
OS_BASE="$(. /etc/os-release && echo "${ID}")"

case "${install_packages_from}" in
    samba-nightly)
        get_custom_repo "https://artifacts.ci.centos.org/samba/pkgs/master/${OS_BASE}/samba-nightly-master.repo"
        if [[ "${OS_BASE}" = centos ]]; then
            dnf install --setopt=install_weak_deps=False -y \
                epel-release centos-release-ceph-reef
        fi
        package_selection=${package_selection:-nightly}
    ;;
    devbuilds)
        # devbuilds - samba nightly dev builds and ceph dev builds
        get_custom_repo "https://artifacts.ci.centos.org/samba/pkgs/master/${OS_BASE}/samba-nightly-master.repo"
        generate_repo_from_shaman "https://shaman.ceph.com/api/search/?project=ceph&distros=${OS_BASE}/9/x86_64&flavor=default&ref=main&sha1=latest" ceph-main.repo
        dnf install --setopt=install_weak_deps=False -y epel-release
        package_selection=${package_selection:-devbuilds}
    ;;
    custom-repo)
        get_custom_repo "${install_custom_repo}"
    ;;
esac


dnf_cmd=(dnf)
if [[ "${OS_BASE}" = centos ]]; then
    dnf_cmd+=(--enablerepo=crb --enablerepo=resilientstorage)
fi


# Assorted packages that must be installed in the container image to
# support the functioning of the container
support_packages=(\
    findutils \
    python-pip \
    python3-samba \
    python3-pyxattr \
    tdb-tools)
# Packages belonging to the samba install. If a samba_version_suffix is given
# all the samba_packages must share that version
samba_packages=(\
    samba \
    samba-client \
    samba-winbind \
    samba-winbind-clients \
    samba-vfs-iouring \
    ctdb)
case "${package_selection}-${OS_BASE}" in
    *-fedora|allvfs-*)
        samba_packages+=(samba-vfs-cephfs samba-vfs-glusterfs)
    ;;
    nightly-centos|devbuilds-centos|forcedevbuilds-*)
        dnf_cmd+=(--enablerepo=epel)
        samba_packages+=(samba-vfs-cephfs)
        # these packages should be installed as deps. of sambacc extras
        # however, the sambacc builds do not enable the extras on centos atm.
        # Once this is fixed this line ought to be removed.
        support_packages+=(python3-pyyaml python3-tomli python3-rados)
    ;;
esac

# Assign version suffix to samba packages
samba_versioned_packages=()
for p in "${samba_packages[@]}"; do
    samba_versioned_packages+=("${p}${samba_version_suffix}")
done


"${dnf_cmd[@]}" \
    install --setopt=install_weak_deps=False -y \
    "${support_packages[@]}" \
    "${samba_versioned_packages[@]}"
dnf clean all

cp --preserve=all /etc/ctdb/functions /usr/share/ctdb/functions
cp --preserve=all /etc/ctdb/notify.sh /usr/share/ctdb/notify.sh
