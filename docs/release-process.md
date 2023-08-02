# samba-container Release Process

## Preparation

The samba-container project has a dedicated branch, called `release`, for
release versions. This is done to update certain files which control
dependencies and versioning. Tags are applied directly to this branch
and only this branch.


### Tagging

Prior to tagging, check out the `release` branch and merge `master` into it.
Example:

```
git checkout master
git pull --ff-only
git checkout release
git pull --ff-only
git merge master
# resolve any conflicts
```

Now we need to "pin" the appropriate versions of samba and sambacc so that only
explicitly specified versions of those packages will be included on release
branch builds. Set `SAMBA_VERSION_SUFFIX` and `SAMBACC_VERSION_SUFFIX` in the
container files in `images/`. Currently, only the fedora based images are
included in the release. Thus you must set those variables in the fedora
container files for server and ad-server. Commit these changes to the `release`
branch. Currently, there is no PR process for release branches so make the
commits directly to the `release` branch and push them. This implies that
releases must be managed by users with the rights to push directly to the
project's release branch.

At this point, an optional but recommended step is to do a test build before
tagging.  Run `make build-ad-server build-server build-client build-toolbox`.
You do not need to build the nightly package variants or other OS bases as
these are not part of the released images. You can push the images to quay.io
under your own repos to perform a early security scan as well.

If you are happy with the content of the `release` branch, tag it. Example:

```
git checkout release
git tag -a -m 'Release v0.3' v0.3
```

This creates an annotated tag. Release tags must be annotated tags.

### Build

Using the tagged `release` branch, the container images for release will be
built. It is very important to ensure that base images are up-to-date.
It is very important to ensure that you perform the next set of steps with
clean new builds and do not use cached images. To accomplish both tasks it
is recommended to purge your local container engine of cached images
(Example: `podman image rm --all`). You should have no images named like
`quay.io/samba.org` in your local cache.

Build the images from scratch. Example:
```
make build-ad-server build-server build-client build-toolbox
```

For each image that was just built, apply a temporary pre-release tag
to it. Example:
```
for img_name in ad-server server client toolbox ; do
    podman tag quay.io/samba.org/samba-${img_name}:{latest,v0.3pre1}
done
```

Log into quay.io.  Push the images to quay.io using the temporary tag. Example:
```
for img_name in ad-server server client toolbox ; do
    podman push quay.io/samba.org/samba-${img_name}:v0.3pre1
done
```

Wait for the security scan to complete. There shouldn't be any issues if you
properly updated the base images before building. If there are issues and you
are sure you used the newest base images, check the base images on quay.io and
make sure that the number of issues are identical. The security scan can take
some time, while it runs you may want to do other things.


## GitHub Release

When you are satisfied that the tagged version is suitable for release, you
can push the tag to the public repo:
```
git push --follow-tags
```

Draft a new set of release notes. Select the recently pushed tag. Start with
the auto-generated release notes from GitHub (activate the `Generate release
notes` button/link). Add an introductory section (see previous notes for an
example). Add a "Highlights" section if there are any notable features or fixes
in the release. The Highlights section can be skipped if the content of the
release is unremarkable (e.g. few changes occurred since the previous release).

Because this is a container based release we do not provide any build artifacts
on GitHub (beyond the sources automatically provided there). Instead we add
a Downloads section that notes the exact tags and digests that the images can
be found at on quay.io.

Use the following partial snippet as an example:
```
Images built for this release can be obtained from the quay.io image registry.

### samba-server
* By tag: quay.io/samba.org/samba-server:v0.3
* By digest: quay.io/samba.org/samba-server@sha256:09c867343af39b237230f94a734eacc8313f2330c7d934994522ced46b740715
### samba-ad-server
* By tag: quay.io/samba.org/samba-ad-server:v0.3
* By digest: quay.io/samba.org/samba-ad-server@sha256:a1d901f44be2af5a516b21e45dbd6ebd2f64500dfbce112886cdce09a5c3cbd5
```
... and so on for each image that was pushed earlier

The tag is pretty obvious - it should match the image tag (minus any pre-release
marker). You can get the digest from the tag using the quay.io UI (do not use
any local digest hashes). Click on the SHA256 link and then copy the full
manifest hash using the UI widget that appears.

Perform a final round of reviews, as needed, for the release notes and then
publish the release.

Once the release notes are drafted and then either immediately before or after
publishing them, use the quay.io UI to copy each pre-release tag to the "latest"
tag and a final "vX.Y" tag. Delete the temporary pre-release tags using the
quay.io UI as they are no longer needed.
