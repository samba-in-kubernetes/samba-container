# Defines the tag for OBS and build script builds:
#!BuildTag: opensuse/samba-toolbox:latest
#!BuildTag: opensuse/samba-toolbox:%%MINOR%%
#!BuildTag: opensuse/samba-toolbox:%%PKG_VERSION%%
#!BuildTag: opensuse/samba-toolbox:%%PKG_VERSION%%-%RELEASE%

# OBS doesn't allow a fully qualified image registry name for the offline build
FROM opensuse/tumbleweed
MAINTAINER David Mulder <dmulder@suse.com>

# labelprefix=org.opensuse.samba-toolbox
LABEL org.opencontainers.image.title="Samba Toolbox container"
LABEL org.opencontainers.image.description="Samba Toolbox container"
LABEL org.opencontainers.image.created="%BUILDTIME%"
LABEL org.opencontainers.image.version="%%PKG_VERSION%%-%RELEASE%"
LABEL org.opencontainers.image.vendor="Samba in Kubernetes"
LABEL org.openbuildservice.disturl="%DISTURL%"
LABEL org.opensuse.reference="registry.opensuse.org/opensuse/samba-toolbox:%%PKG_VERSION%%-%RELEASE%"
# endlabelprefix

RUN zypper --non-interactive install --no-recommends samba-client samba-test && zypper clean
