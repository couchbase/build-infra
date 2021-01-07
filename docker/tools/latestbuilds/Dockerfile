FROM nginx:alpine

RUN apk add --no-cache openssh-server openssh-sftp-server runit

RUN adduser -u 1000 couchbase -D -s /bin/sh && \
    echo 'couchbase:couchbase' | chpasswd

RUN ssh-keygen -A

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
COPY scripts/nginx-run /etc/service/nginx/run
COPY scripts/sshd-run /etc/service/sshd/run

COPY conf/default.conf /etc/nginx/conf.d/default.conf

ENTRYPOINT ["/entrypoint.sh"]
