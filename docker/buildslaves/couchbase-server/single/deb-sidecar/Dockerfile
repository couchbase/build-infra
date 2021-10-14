# Minimal Dockerfile that just knows how to build Debs

FROM debian:10

# QQQ Must get rid of ruby
# We have to install the system libraries Server depends on, unfortunately,
# so that dh_shlibdeps can identify the packages they belong to.
RUN set -x \
    && apt-get update \
    && apt-get install -y dpkg-dev debhelper \
    && apt-get install -y libtinfo5 \
    && apt-get install -y rubygems rake \
    && apt-get clean
