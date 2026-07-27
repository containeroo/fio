# syntax=docker/dockerfile:1.23
FROM alpine:3.24.1

# renovate: datasource=repology depName=alpine_3_24/bash versioning=apk
ARG BASH_VERSION=5.3.9-r1
# renovate: datasource=repology depName=alpine_3_24/catatonit versioning=apk
ARG CATATONIT_VERSION=0.2.1-r0
# renovate: datasource=repology depName=alpine_3_24/fio versioning=apk
ARG FIO_VERSION=3.41-r0
# renovate: datasource=repology depName=alpine_3_24/jq versioning=apk
ARG JQ_VERSION=1.8.1-r0
# renovate: datasource=repology depName=alpine_3_24/nfs-utils versioning=apk
ARG NFS_UTILS_VERSION=2.6.4-r6
# renovate: datasource=repology depName=alpine_3_24/procps-ng versioning=apk
ARG PROCPS_NG_VERSION=4.0.6-r0
# renovate: datasource=repology depName=alpine_3_24/util-linux versioning=apk
ARG UTIL_LINUX_VERSION=2.42.1-r0

RUN apk add --no-cache \
  "bash=${BASH_VERSION}" \
  "catatonit=${CATATONIT_VERSION}" \
  "fio=${FIO_VERSION}" \
  "jq=${JQ_VERSION}" \
  "nfs-utils=${NFS_UTILS_VERSION}" \
  "procps-ng=${PROCPS_NG_VERSION}" \
  "util-linux=${UTIL_LINUX_VERSION}"

# ---- Runtime identity is chosen at build time ----
# default = non-root user 10001 with group 0 (OpenShift-friendly)
ARG RUNTIME_USER=10001
ARG RUNTIME_GROUP=0

# Writable work dir that works for both fixed UID and OpenShift arbitrary UID
ENV APP_HOME=/work
RUN mkdir -p "${APP_HOME}" \
  && chown -R ${RUNTIME_USER}:${RUNTIME_GROUP} "${APP_HOME}" \
  && chmod -R g=u "${APP_HOME}"
WORKDIR ${APP_HOME}

# Switch user (numeric IDs; no passwd entry required)
USER ${RUNTIME_USER}:${RUNTIME_GROUP}

STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/bin/catatonit", "--"]
# Replace with your real process if needed
CMD ["/bin/bash", "-lc", "sleep infinity"]


