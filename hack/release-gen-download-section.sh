#!/usr/bin/env bash
# Requires `skopeo` and `jq` to be installed.

set -e

sk_digest() {
    skopeo inspect "docker://${1}" | jq -r .Digest
}

image_info() {
    curr_img="quay.io/samba.org/${1}:${2}"
    digest=$(sk_digest "${curr_img}")
    # strip preN from tag name
    final_tag=${2/%pre[0-9]*/}
    tag_img="quay.io/samba.org/${1}:${final_tag}"
    dst_img="quay.io/samba.org/${1}@${digest}"

    echo "### $1"
    echo "* By tag: $tag_img"
    echo "* By digest: $dst_img"
    echo ""
}

wip_tag=$1
if [ -z "${wip_tag}" ] ; then
    echo "No tag provided!" >&2
    exit 1
fi

echo "## Downloads"
echo ""
echo "Images built for this release can be acquired from the quay.io image registry."
echo ""
for component in samba-server samba-ad-server samba-client samba-toolbox; do
    image_info "${component}" "${wip_tag}"
done

