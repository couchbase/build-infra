FROM couchbasebuild/server-linux-build:20211005

LABEL maintainer=build-team@couchbase.com

ARG CLAMAV_VER=0.104.0
# The --replacefiles is necessary because the clamav RPM is broken - it
# claims ownership of /usr/local/lib64, which is owned by the stock
# Centos "filesystem" package. Normally this would be a terrible idea,
# but for a standalone Docker image it doesn't matter much.
RUN set -x \
    && cd /tmp \
    && curl -Lf -o clamav.rpm https://www.clamav.net/downloads/production/clamav-${CLAMAV_VER}.linux.x86_64.rpm \
    && rpm -i --replacefiles clamav.rpm \
    && rm clamav.rpm

# cvdupdate handles caching the updated Clamav databases, so we don't
# get rate-limited running "freshclam" all the time
RUN pip3 install cvdupdate

# Hook script to run "cvd serve" in the background; this agent also
# serves as the Clamav database mirror for the Windows Clamav job
COPY cvd-server-hook.sh /usr/sbin/couchhook.d/cvd-server-hook.sh
