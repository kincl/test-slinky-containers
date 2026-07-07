ARG PARENT_IMAGE=registry.access.redhat.com/ubi9:latest

FROM ${PARENT_IMAGE} AS build

ARG SLURM_VERSION=26.05.0
ARG SLURM_TAR="slurm-${SLURM_VERSION}"

SHELL ["bash", "-c"]

WORKDIR /root

ADD https://download.schedmd.com/slurm/${SLURM_TAR}.tar.bz2 ${SLURM_TAR}.tar.bz2

# Ref: https://slurm.schedmd.com/quickstart_admin.html#rpmbuild
RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
dnf -q -y install rpm-build https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --enable crb || dnf config-manager --enable codeready-builder-for-rhel-9-x86_64-rpms
rpmbuild -tp ${SLURM_TAR}.tar.bz2
dnf -y builddep \
  -D '_with_cgroupv2 1' \
  -D '_with_slurmrestd 1' \
  -D '_with_jwt 1' \
  -D '_with_yaml 1' \
  -D '_with_hwloc --with-hwloc' \
  -D '_with_numa 1' \
  -D '_with_pmix --with-pmix' \
  -D '_with_ucx --with-ucx' \
  -D '_with_lua yes' \
  -D '_with_freeipmi 1' \
  -D '_with_hdf5 yes' \
  -D '_with_libcurl yes' \
  -D '_enable_debug 1' \
  /root/rpmbuild/BUILD/slurm-${SLURM_VERSION}/slurm.spec
rpmbuild -ta \
  --with slurmrestd \
  --with jwt \
  --with pmix \
  --with ucx \
  ${SLURM_TAR}.tar.bz2
EOR

FROM ${PARENT_IMAGE} AS base

SHELL ["bash", "-c"]

ARG SLURM_VERSION
ENV SLURM_VERSION=${SLURM_VERSION}

USER root
WORKDIR /tmp/

ARG SLURM_USER=slurm
ARG SLURM_USER_UID=401
ARG SLURM_USER_GID=401

RUN <<EOR
# Create SlurmUser
set -xeuo pipefail
groupadd --system --gid=${SLURM_USER_GID} ${SLURM_USER}
useradd --system --no-log-init --uid=${SLURM_USER_UID} --gid=${SLURM_USER_GID} --shell=/usr/sbin/nologin ${SLURM_USER}
EOR

COPY --from=build /root/rpmbuild/RPMS/**/*.rpm /tmp/

RUN --mount=type=cache,target=/var/cache/dnf,sharing=locked <<EOR
curl -sL https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux-amd64-rhel9.tar.gz | \
  tar -xzC /usr/local/bin

# Install Dependencies
# For: Slurm RPM Dependencies
dnf config-manager --enable crb || dnf config-manager --enable codeready-builder-for-rhel-9-x86_64-rpms
dnf -y -q install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

set -xeuo pipefail
# Init System
dnf -q -y install supervisor tini
# Debug
dnf -q -y install procps-ng iputils ncurses

# Install Slurm Packages
set -xeuo pipefail
dnf -q -y install --setopt='install_weak_deps=False' \
  socat \
  ./slurm-slurmctld-[0-9]*.rpm \
  ./slurm-slurmdbd-[0-9]*.rpm \
  ./slurm-slurmrestd-[0-9]*.rpm \
  ./slurm-sackd-[0-9]*.rpm \
  gawk  \
  openssh-server \
  authselect sssd sssd-ad sssd-ldap \
  ./slurm-devel-[0-9]*.rpm \
  ./slurm-libpmi-[0-9]*.rpm \
  ./slurm-pam_slurm-[0-9]*.rpm \
  ./slurm-slurmd-[0-9]*.rpm \
  ./slurm-[0-9]*.rpm
rm *.rpm
EOR

ENTRYPOINT ["entrypoint.sh"]
