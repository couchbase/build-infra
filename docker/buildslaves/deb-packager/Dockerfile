# Simple image that only knows how to package debs
FROM debian:11-slim AS debian-packager-compile

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       dpkg-dev debhelper fakeroot libtinfo5 \
    && apt-get clean
RUN set -x \
    && cd /usr/lib \
    && find . -type f -print0 | xargs -0 -n 50 strip || true
RUN set -x \
    && rm -rf /var/lib/apt \
    && rm -rf /var/log/* \
    && rm -rf /var/cache/{apt,man} \
    && rm -rf /usr/share/{doc,info,man}
RUN groupadd -g 1000 couchbase && useradd -g couchbase -u 1000 couchbase

# Flatten the image
FROM scratch
COPY --from=debian-packager-compile / /
