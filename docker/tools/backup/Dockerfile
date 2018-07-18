# Docker container for backup Xen's VM

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

RUN pip install XenAPI==1.2 requests==2.0.0 ago==0.0.5 && \
    pip3 install pyyaml==3.12  &&\
    apt-get install s3cmd -y

COPY $HOME/xenbackup /xenbackup
COPY xen-credential-yaml-to-json.py /xen-credential-yaml-to-json.py
COPY xenbackup.sh /xenbackup.sh
CMD ["/xenbackup.sh"]
