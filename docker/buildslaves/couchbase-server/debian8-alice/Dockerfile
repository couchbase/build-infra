# This Dockerfile exists only to update the repo tool from the older
# image. We don't want to rebuild some of the older historic images and
# risk raising unexpected issues when rebuilding older releases.

FROM couchbasebuild/server-debian8-build:20201214

RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

RUN rm -rf /home/couchbase/.ssh

COPY build/couchbuilder_start.sh /usr/sbin/