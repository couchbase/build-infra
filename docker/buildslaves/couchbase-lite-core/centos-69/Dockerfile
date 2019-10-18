# Docker container for Centos 6.9

FROM centos:6.9
MAINTAINER build-team@couchbase.com

USER root

RUN yum clean all && \
    yum install --setopt=keepcache=0 -y \
		deltarpm \
		git \
    glibc-devel \
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

# Jenkins Swarm jar and JDK for Jenkins.
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%2B11/OpenJDK11U-jre_x64_linux_hotspot_11.0.4_11.tar.gz -o openjre.tar.gz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/openjre.tar.gz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.13/swarm-client-3.13.jar \
    -o /usr/local/lib/swarm-client.jar

# * repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Expose SSH daemon and run our builder startup script
EXPOSE 22
RUN mkdir /home/couchbase/.ssh && chown couchbase:couchbase /home/couchbase/.ssh
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "default" ]

# Start with a new enough version of GCC to build clang
# GCC (from couchbasebuild/centos-8-gcc)
COPY build/local /usr/local
RUN echo "/usr/local/lib64" > /etc/ld.so.conf.d/gcc.conf && ldconfig

# Python 2.7.9 (for building LLVM)
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -LO https://www.python.org/ftp/python/2.7.16/Python-2.7.16.tgz && \
    tar -xvf Python-2.7.16.tgz && \
    cd Python-2.7.16 && \
    ./configure && make -j8 && make altinstall && \
    cd /tmp && \
    rm -rf deploy

# * CMake (from cmake.org)
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v3.13/cmake-3.13.0-Linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# Clang - this is slow to include here, but I couldn't find a good way to
# save it into a separate build image like we do gcc
RUN yum install --setopt=keepcache=0 -y subversion && \
    mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_391/final llvm_RELEASE_391 && \
    cd llvm_RELEASE_391/tools && \
    svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_391/final clang && \
    cd ../projects && \
    svn co http://llvm.org/svn/llvm-project/compiler-rt/tags/RELEASE_391/final compiler-rt && \
    svn co http://llvm.org/svn/llvm-project/libcxx/tags/RELEASE_391/final libcxx && \
    svn co http://llvm.org/svn/llvm-project/libcxxabi/tags/RELEASE_391/final libcxxabi && \
    cd .. && \
    svn update && \
    mkdir /tmp/deploy/llvm_RELEASE_391_build && \
    cd /tmp/deploy/llvm_RELEASE_391_build && \
    cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ../llvm_RELEASE_391 && \
    make -j8 && \
    make install && \
    cd /tmp && \
    rm -rf deploy
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/clang.conf && ldconfig
RUN rm /usr/local/bin/c++ && \
    update-alternatives --install /usr/local/bin/cc clang /usr/local/bin/clang 100 && \
    update-alternatives --install /usr/local/bin/c++ clang++ /usr/local/bin/clang++ 100

# Install Couchbase Lite Core toolchain requirements
RUN yum install -y --setopt=keepcache=0 glibc-devel tar openssl-devel make redhat-lsb-core wget unzip zip

# * ccache (from source)
RUN mkdir /tmp/deploy && \
    curl -L https://www.samba.org/ftp/ccache/ccache-3.3.4.tar.xz -o /tmp/deploy/ccache.tar.xz && \
    cd /tmp/deploy && tar -xf ccache.tar.xz && \
    cd ccache-3.3.4 && ./configure --prefix=/usr/local && make -j8 && make install && \
    rm -fr /tmp/deploy

# fr_FR locale for LiteCore testing
RUN sudo localedef -v -c -i fr_FR -f UTF-8 fr_FR || true
