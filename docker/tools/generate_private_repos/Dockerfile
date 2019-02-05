# Docker container for generate closed source

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

COPY requirements.txt /tmp
WORKDIR /tmp
RUN pip3.6 install -r requirements.txt

COPY $HOME/build-tools /home/couchbase/build-tools
COPY $HOME/manifest /home/couchbase/manifest
COPY gen-private-repo.sh /gen-private-repo.sh
CMD ["/gen-private-repo.sh"]
