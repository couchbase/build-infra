# Simple image that only knows how to package rpms
FROM rockylinux:8 AS rpm-packager-compile

RUN set -x \
    && ulimit -n 1024 \
    && dnf install -y --setopt=install_weak_deps=False rpm-build \
    && dnf clean all
RUN set -x \
    && rm -rf /var/cache/dnf \
    && rm -rf /usr/share/{doc,info,man} \
    && find / --name __pycache__ -print0 | xargs -0 rm -rf
RUN groupadd -g 1000 couchbase && useradd -g couchbase -u 1000 couchbase

# Flatten the image
FROM scratch
COPY --from=rpm-packager-compile / /
