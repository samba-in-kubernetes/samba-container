# Development Guide


## Building samba containers with unreleased sambacc code

Changes to `sambacc` are validated by a suite of unit tests to ensure a minium
level of quality, but that is often not enough to fully validate a
work-in-progress feature, especially one that needs to interact with components
from Samba in complex ways. One may want to try out an unreleased branch of
sambacc code as part of a samba container image. Two methods of doing this are:
* Build sambacc RPMs and put them in a yum/dnf repo
* Customize the Containerfile to use a sambacc build stage

Both methods make use of the sambacc build image. The files needed to build the
image are part of the [sambacc
repo](https://github.com/samba-in-kubernetes/sambacc) and already-created
images are available at quay.io:
[quay.io/samba.org/sambacc](https://quay.io/repository/samba.org/sambacc).

### RPMs

One can build rpms using the sambacc test-and-build container.
In this example we assume you have a git checkout of sambacc as the
local path. Create a new directory to store build artifacts in:
```
mkdir -p _build
```

Then run the container command like follows:
```
podman run -v $PWD:/var/tmp/build/sambacc  -v $PWD/_build:/srv/dist/:z -e SAMBACC_DISTNAME=dev  quay.io/samba.org/sambacc:latest
```

Breaking it down, we're mounting the current dir at `/var/tmp/build/sambacc`,
mounting the build dir at `/srv/dist` and telling the build container
to store artifacts under the "distribution name" of `dev`. This should
result in rpms, whl files and other artifacts in `_build/dev`. You can
name your "dist" anything.

Now you have a directory with rpms in it you can run `createrepo` on them
and/or publish them on the web. Managing the rpms is an exercise left to the
reader.

To get them into a samba-container image, like the samba-server or
samba-ad-server image, we need to get or create a repo file pointing to the
repo hosting your rpms. The repo file must be saved into the build container at
a path named like `/tmp/sambacc-dist-latest/sambacc*.repo`, so that the
`install-sambacc.sh` script that is run during the image build can find it.

Typically this means modifying the Containerfile. Here's an example modification
to the `images/server/Containerfile.fedora` file:
```
COPY .common/install-sambacc-common.sh /usr/local/bin/install-sambacc-common.sh
COPY install-sambacc.sh /usr/local/bin/install-sambacc.sh
# Add an ADD command to copy our repofile into the build
ADD https://my-cool-repo.example.org/mystuff/sambacc.repo /tmp/sambacc-dist-latest
RUN /usr/local/bin/install-sambacc.sh \
    "/tmp/sambacc-dist-latest" \
    "${SAMBACC_VERSION_SUFFIX}"
```

Now build the image the usual way. It should contain your specific sambacc rpms.


### Build Stage

Rather than building the sambacc RPMs and creating a repo for them, the build
steps can be combined by modifying the `Containerfile`s to add a specific build
stage. First add the build stage to the top of the Containerfile:
```
# --- new stuff ---
FROM quay.io/samba.org/sambacc:latest AS sccbuilder
ARG SAMBACC_VER=my-cool-branch
ARG SAMBACC_REPO=https://github.com/example-user/sambacc
RUN SAMBACC_DISTNAME=latest \
    /usr/local/bin/build.sh ${SAMBACC_VER} ${SAMBACC_REPO}
# --- end new stuff ---

FROM registry.fedoraproject.org/fedora:38
```

The variables `SAMBACC_VER` and `SAMBACC_REPO` can be overridden on the command
line so you don't have to keep modifying the Containerfile to set them, unless
you want to. `SAMBACC_VER` takes a git ref and that can be a barnch name or a
commit hash. Using a commit hash can be handy to avoid caching issues.

Next, we need to make a modification to the RUN command that executes
`install-sambacc.sh`:
```
# add the --mount argument to map the dist dir of the sccbuilder
# container to the /tmp/sambacc-dist-latest dir in the current build
# container.
RUN --mount=type=bind,from=sccbuilder,source=/srv/dist/latest,destination=/tmp/sambacc-dist-latest bash -x /usr/local/bin/install-sambacc.sh \
    "/tmp/sambacc-dist-latest" \
    "${SAMBACC_VERSION_SUFFIX}"
```

Very old versions of podman and docker may not support `--mount`. As an
alternative, you can add a `COPY` command to copy the rpms from one container
to the other.
