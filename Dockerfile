# syntax=docker/dockerfile:1.27
FROM alpine:3.24.1

# alpine-package: name=bash repo=main
ARG BASH_VERSION=5.3.9-r1
# alpine-package: name=catatonit repo=community
ARG CATATONIT_VERSION=0.2.1-r0
# alpine-package: name=fio repo=main
ARG FIO_VERSION=3.41-r0
# alpine-package: name=jq repo=main
ARG JQ_VERSION=1.8.1-r0
# alpine-package: name=nfs-utils repo=main
ARG NFS_UTILS_VERSION=2.6.4-r6
# alpine-package: name=procps-ng repo=main
ARG PROCPS_NG_VERSION=4.0.6-r0
# alpine-package: name=util-linux repo=main
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

