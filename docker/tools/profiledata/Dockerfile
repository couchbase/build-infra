FROM alpine
LABEL maintainer="build-team@couchbase.com"

RUN set -x \
        && apk add --no-cache openssh rsync

RUN set -x \
        && addgroup -g 901 -S couchbase \
        && adduser -u 901 -D couchbase -G couchbase \
        && passwd -d couchbase \
        && chmod 755 /home/couchbase

COPY sshd_config /tmp/sshd_config

RUN set -x \
        && mv /tmp/sshd_config /etc/ssh \
        && echo "" > /etc/motd

USER couchbase
RUN set -x \
        && mkdir ~/.ssh \
        && chmod 700 ~/.ssh
USER root

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D"]
EXPOSE 4000
