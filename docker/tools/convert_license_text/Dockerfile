# Docker container for converting license text to required formats

FROM ubuntu:16.04
MAINTAINER build-team@couchbase.com

USER root

# Update perl and install txt2html
RUN apt-get update && \
    apt-get install -y perl build-essential && \
    perl -MCPAN -e "CPAN::Shell->notest('install', 'HTML::TextToHTML')" && \
    apt-get purge -y build-essential && \
    apt-get --purge autoremove -y && \
    apt-get clean

COPY entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]
