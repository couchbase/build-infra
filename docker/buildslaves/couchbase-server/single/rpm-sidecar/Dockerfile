# Minimal Dockerfile that just knows how to build RPMs

# Slightly insane that this works, but nothing simpler seems to.
# In particular, "COPY --from" won't accept any kind of build args,
# so we have to arrange for a single "FROM .. as foo" to end up
# with architecture-specific contents.
ARG SINGLE_LINUX_IMAGE_amd64
ARG SINGLE_LINUX_IMAGE_arm64
FROM --platform=amd64 ${SINGLE_LINUX_IMAGE_amd64} as base_builder_amd64
FROM --platform=arm64 ${SINGLE_LINUX_IMAGE_arm64} as base_builder_arm64
FROM --platform=$TARGETPLATFORM base_builder_$TARGETARCH as base_builder

FROM registry.access.redhat.com/ubi8/ubi

# QQQ Must get rid of ruby
RUN yum install -y rpm-build ruby rubygems rubygem-rake && yum clean all

# Ensure /var/lib/rpm matches the main Single Linux agent for the
# corresponding architecture, so that generated RPMs have correct
# package dependencies
RUN rm -rf /var/lib/rpm
COPY --from=base_builder /var/lib/rpm /var/lib/rpm
