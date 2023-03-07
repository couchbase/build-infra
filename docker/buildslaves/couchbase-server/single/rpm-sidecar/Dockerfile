# Minimal Dockerfile that just knows how to build RPMs
FROM couchbasebuild/server-linux-build:latest as base_builder

FROM registry.access.redhat.com/ubi8/ubi

# QQQ Must get rid of ruby
RUN yum install -y rpm-build ruby rubygems rubygem-rake && yum clean all

# Ensure /var/lib/rpm matches the main Single Linux agent for the
# corresponding architecture, so that generated RPMs have correct
# package dependencies
RUN rm -rf /var/lib/rpm
COPY --from=base_builder /var/lib/rpm /var/lib/rpm
