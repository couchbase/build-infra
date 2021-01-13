FROM node:alpine

LABEL maintainer="build-team@couchbase.com"

COPY . /app

RUN set -x \
        && cd /app \
        && npm install \
        && npm run-script build

FROM nginx:alpine
COPY --from=0 /app/build/ /usr/share/nginx/html/
