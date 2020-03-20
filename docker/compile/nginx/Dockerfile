# May as well use our existing Centos 7 buildslave since it has essential build
# tools in it already.

# Build instructions taken in part from
# https://www.vultr.com/docs/how-to-compile-nginx-from-source-on-ubuntu-16-04
# and
# https://www.nginx.com/resources/wiki/modules/fancy_index/

FROM couchbasebuild/server-centos7-build:20200211

ARG NGINX_VER=1.16.1
ARG PCRE_VER=8.44
ARG ZLIB_VER=1.2.11
ARG OPENSSL_VER=1.1.1e
ARG FANCYIDX_VER=0.4.4

RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -LO https://nginx.org/download/nginx-${NGINX_VER}.tar.gz && tar xzf nginx-${NGINX_VER}.tar.gz && \
    curl -LO https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VER}.tar.gz && tar xzf pcre-${PCRE_VER}.tar.gz && \
    curl -LO https://www.zlib.net/zlib-${ZLIB_VER}.tar.gz && tar xzf zlib-${ZLIB_VER}.tar.gz && \
    curl -LO https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz && tar xzf openssl-${OPENSSL_VER}.tar.gz && \
    curl -LO https://github.com/aperezdc/ngx-fancyindex/releases/download/v${FANCYIDX_VER}/ngx-fancyindex-${FANCYIDX_VER}.tar.xz && tar xf ngx-fancyindex-${FANCYIDX_VER}.tar.xz && \
    cd nginx-${NGINX_VER} && \
    ./configure \
        --add-module=../ngx-fancyindex-${FANCYIDX_VER} \
        --with-openssl=../openssl-${OPENSSL_VER} \
        --with-openssl-opt=enable-ec_nistp_64_gcc_128 \
        --with-openssl-opt=no-nextprotoneg \
        --with-openssl-opt=no-weak-ssl-ciphers \
        --with-openssl-opt=no-ssl3 \
        --with-pcre=../pcre-${PCRE_VER} \
        --with-pcre-jit \
        --with-zlib=../zlib-${ZLIB_VER} \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --prefix=/usr/local/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
        --http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
        --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \
        --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi \
        --http-scgi-temp-path=/var/lib/nginx/tmp/scgi \
        --pid-path=/run/nginx.pid \
        --lock-path=/run/lock/subsys/nginx \
        --user=nginx --group=nginx \
        --with-ipv6 \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-stream_ssl_preread_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_secure_link_module \
        --with-http_degradation_module \
        --with-http_slice_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-stream_ssl_module \
        --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic' \
        --with-ld-opt='-Wl,-z,relro -Wl,-E' && \
    make -j && \
    make install && \
    strip /usr/local/nginx/sbin/nginx && \
    cd /tmp && \
    rm -rf deploy

USER couchbase
ENTRYPOINT []
CMD ["cp", "-av", "/usr/local/nginx/sbin/nginx", "/out"]
