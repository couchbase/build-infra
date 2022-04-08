Trivial reverse-proxy, useful for redirecting web traffic from somewhere
we can't control (such as the itweb01 proxy) to a new host while testing
or waiting for DNS changes.

The https directory is configured for sending traffic intended for
"blackduck.build.couchbase.com" to a new IP. To build/run it, you need a
https certificate and key for *.build.couchbase.com (possibly
self-signed) in files named "cert.crt" and "cert.key".

The http directory is configured for sending traffic intended for
analytics.jenkins.couchbase.com and cv.jenkins.couchbase.com to mega4
(which uses traefik to redirect to the appropriate Docker Swarm
service).
