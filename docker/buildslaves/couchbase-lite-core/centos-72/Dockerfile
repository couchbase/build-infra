# Docker container for Centos 7.2

FROM centos:7.2.1511
MAINTAINER build-team@couchbase.com

USER root
RUN yum clean all && yum swap -y fakesystemd systemd

RUN yum install --setopt=keepcache=0 -y \
		deltarpm \
		git \
		openssh-server \
		sudo \
		which \
    yum-plugin-ovl

# Set up for SSH daemon
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config && \
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

# Oracle JDK (for Jenkins and Analytics).
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz -o jdk.tgz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/jdk.tgz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy
ENV JAVA_HOME=/usr/local/java

# * repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Expose SSH daemon and run our builder startup script
EXPOSE 22
RUN mkdir /home/couchbase/.ssh && chown couchbase:couchbase /home/couchbase/.ssh
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "default" ]

# FPM packaging tool.  Need this before install clang as it will override c++
RUN yum install -y ruby-devel gcc make rpm-build rubygems && \
    gem install fpm

# Install Clang from Fedora Copr
RUN curl -o /etc/yum.repos.d/alonid.repo \
  https://copr.fedorainfracloud.org/coprs/alonid/llvm-3.9.1/repo/epel-7/alonid-llvm-3.9.1-epel-7.repo && \
  yum install -y --setopt=keepcache=0 clang-3.9.1 llvm-3.9.1-devel

# Make clang-3.9.1 the default, overriding GCC, and fix up CMake stuff
RUN update-alternatives --install /usr/bin/clang++ clang++ /opt/llvm-3.9.1/bin/clang++ 100 && \
    update-alternatives --install /usr/bin/clang clang /opt/llvm-3.9.1/bin/clang 100 && \
    rm /usr/bin/c++ && \
    update-alternatives --install /usr/bin/c++ c++ /opt/llvm-3.9.1/bin/clang++ 100 && \
    update-alternatives --install /usr/bin/cc cc /opt/llvm-3.9.1/bin/clang 100 && \
    ln -s /opt/llvm-3.9.1/bin/llvm-config /usr/bin/llvm-config && \
    mkdir -p /opt/llvm-3.9.1/share/llvm && \
    ln -s /opt/llvm-3.9.1/lib64/cmake/llvm /opt/llvm-3.9.1/share/llvm/cmake

# Install Couchbase Lite Core toolchain requirements
RUN yum install -y --setopt=keepcache=0 tar openssl-devel make redhat-lsb-core wget unzip zip

# * ccache (from source)
RUN mkdir /tmp/deploy && \
    curl -L https://www.samba.org/ftp/ccache/ccache-3.3.4.tar.xz -o /tmp/deploy/ccache.tar.xz && \
    cd /tmp/deploy && tar -xf ccache.tar.xz && \
    cd ccache-3.3.4 && ./configure --prefix=/usr/local && make -j8 && make install && \
    ln -s ccache /usr/local/bin/clang && \
    ln -s ccache /usr/local/bin/clang++ && \
    ln -s ccache /usr/local/bin/cc && \
    ln -s ccache /usr/local/bin/c++ && \
    ln -s ccache /usr/local/bin/gcc && \
    ln -s ccache /usr/local/bin/g++ && \
    rm -fr /tmp/deploy

# * CMake (from cmake.org)
RUN mkdir /tmp/deploy && \
    curl -L https://cmake.org/files/v3.13/cmake-3.13.0-Linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm /usr/local/bin/cmake-gui && \
    rm -rf /tmp/deploy

# Android SDK
RUN mkdir -p /opt && \
    cd /opt && \
    curl -L http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz -o android-sdk.tgz && \
    tar xzf android-sdk.tgz && \
    rm -rf android-sdk.tgz && \
    (echo y | android-sdk-linux/tools/android -s update sdk --no-ui --filter platform-tools,tools -a ) && \
    (echo y | android-sdk-linux/tools/android -s update sdk --no-ui --filter extra-android-m2repository,extra-android-support,extra-google-google_play_services,extra-google-m2repository -a) && \
    (echo y | android-sdk-linux/tools/android -s update sdk --no-ui --filter build-tools-26.0.0,android-26 -a) && \
    chown -R couchbase:couchbase android-sdk-linux && \
    chmod 755 android-sdk-linux

## Android NDK
RUN cd /opt && \
    curl -L https://dl.google.com/android/repository/android-ndk-r15b-linux-x86_64.zip -o android-ndk-r15b.zip && \
    unzip -qq android-ndk-r15b.zip && \
    chown -R couchbase:couchbase android-ndk-r15b && \
    chmod 755 android-ndk-r15b && \
    rm -rf android-ndk-r15b.zip