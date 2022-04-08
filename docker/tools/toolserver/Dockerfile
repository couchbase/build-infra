FROM httpd:2.4.41-alpine

LABEL maintainer=build-team@couchbase.com

RUN apk update ; apk add curl jq coreutils openssl

COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY cgi-bin/ /usr/local/apache2/cgi-bin/
COPY static/ /usr/local/apache2/htdocs/
COPY forward_env_start_httpd /usr/local/apache2/

CMD ["/usr/local/apache2/forward_env_start_httpd"]
