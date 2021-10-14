# Minimal Dockerfile that just knows how to build RPMs

FROM registry.access.redhat.com/ubi8/ubi

# QQQ Must get rid of ruby
RUN yum install -y rpm-build ruby rubygems rubygem-rake && yum clean all
