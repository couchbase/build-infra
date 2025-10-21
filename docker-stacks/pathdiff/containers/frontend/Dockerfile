FROM node:lts-alpine3.19

ENV REACT_APP_API=pathdiff.build.couchbase.com:5000

COPY . /app
WORKDIR /app

RUN set -x \
    && yarn install \
    && yarn build

FROM nginx:1.21.3
RUN rm -rf /usr/share/nginx/html/*
COPY --from=0 /app/build /usr/share/nginx/html
