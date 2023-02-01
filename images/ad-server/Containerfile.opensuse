# Defines the tag for OBS and build script builds:
#!BuildTag: opensuse/samba-ad-server:latest
#!BuildTag: opensuse/samba-ad-server:%%MINOR%%
#!BuildTag: opensuse/samba-ad-server:%%PKG_VERSION%%
#!BuildTag: opensuse/samba-ad-server:%%PKG_VERSION%%-%RELEASE%

# OBS doesn't allow a fully qualified image registry name for the offline build
FROM opensuse/tumbleweed
ARG SAMBA_SPECIFICS=

MAINTAINER David Mulder <dmulder@suse.com>

# labelprefix=org.opensuse.samba-ad-server
LABEL org.opencontainers.image.title="Samba ADDC container"
LABEL org.opencontainers.image.description="Samba ADDC container"
LABEL org.opencontainers.image.created="%BUILDTIME%"
LABEL org.opencontainers.image.version="%%PKG_VERSION%%-%RELEASE%"
LABEL org.opencontainers.image.vendor="Samba in Kubernetes"
LABEL org.openbuildservice.disturl="%DISTURL%"
LABEL org.opensuse.reference="registry.opensuse.org/opensuse/samba-ad-server:%%PKG_VERSION%%-%RELEASE%"
# endlabelprefix

RUN zypper --non-interactive install --no-recommends \
  findutils \
  python3-pip \
  python3-jsonschema \
  samba-python3 \
  python3-pyxattr \
  samba-ad-dc \
  procps \
  samba-client \
  samba-winbind \
  python3-dnspython \
  krb5-server \
  sambacc && \
  zypper clean;
RUN ln -sf /usr/share/sambacc/examples/addc.json /etc/samba/container.json
RUN rm -rf /etc/samba/smb.conf


ENV SAMBACC_CONFIG="/etc/samba/container.json:/etc/samba/users.json"
ENV SAMBA_CONTAINER_ID="demo"
ENV SAMBA_SPECIFICS="$SAMBA_SPECIFICS"
ENTRYPOINT ["samba-dc-container"]
CMD ["run", "--setup=provision", "--setup=populate"]

# vim:set syntax=dockerfile:
