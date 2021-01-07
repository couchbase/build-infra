#!/bin/sh

# Copy in htpasswd from AWS secret
echo "${htpasswd}" > /etc/nginx/htpasswd

exec /sbin/runsvdir /etc/service
