FROM couchbasebuild/server-centos8-build:20210831

RUN set -x \
    && cd /etc/yum.repos.d \
    && rm -f /etc/yum.repos.d/github_git-lfs.repo \
    && sed -i '/mirrorlist/d' /etc/yum.repos.d/CentOS-* \
    && sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* \
    && yum update -y rpm-build

COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/healthcheck.sh /usr/sbin/
