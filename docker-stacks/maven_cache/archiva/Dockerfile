FROM openjdk:8-slim

ENV ARCHIVA_VERSION=2.2.5
ENV ARCHIVA_BASE=/var/archiva

WORKDIR /tmp

RUN groupadd --gid 1000 archiva \
    && useradd --gid 1000 -g archiva archiva

RUN apt update \
    && apt install -y procps curl unzip rsync \
    && apt clean \
    && curl -LO http://mirrors.ukfast.co.uk/sites/ftp.apache.org/archiva/${ARCHIVA_VERSION}/binaries/apache-archiva-${ARCHIVA_VERSION}-bin.zip \
    && unzip apache-archiva-${ARCHIVA_VERSION}-bin.zip

RUN mv apache-archiva-${ARCHIVA_VERSION} /app \
    && chown -R archiva:archiva /app

COPY archiva.xml /app/conf/

COPY entrypoint.sh /
RUN chown archiva:archiva /entrypoint.sh \
    && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8080
