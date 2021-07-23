# Docker container for Centos 6.9

FROM couchbasebuild/python-centos6-build:20200211

COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
RUN yum install -y rsync openssh-clients

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /
COPY build/couchbuilder_start.sh /usr/sbin/
