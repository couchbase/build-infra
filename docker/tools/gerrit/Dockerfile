ARG GERRIT_VER

# Custom docker image for gerrit
FROM gerritcodereview/gerrit:${GERRIT_VER}

LABEL maintainer="Couchbase Build Team <build-team@couchbase.com>"

USER root

# Install Python3
RUN set -x \
    && yum install -y \
        python3 \
    && yum clean all

COPY requirements.txt /tmp/requirements.txt
RUN set -x \
    && python3 -m pip install --upgrade pip \
    && pip3 install -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

USER gerrit
