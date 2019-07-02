# Docker container for generate commit count program on Ubuntu 16.04
#
# Contains the following:
#  - generate_commit_count source code from build-tools

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

COPY requirements.txt /tmp
WORKDIR /tmp
RUN pip3.6 install -r requirements.txt

COPY gen-commit-count.sh /gen-commit-count.sh
CMD ["/gen-commit-count.sh"]
