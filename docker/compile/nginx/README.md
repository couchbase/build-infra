Builds a static version of nginx including the 'fancy index' plugin. This
tool is deployed on the new SAN cnt-s231.sc.couchbase.com.

The nginx configuration parameters were drawn from several locations,
including:
https://www.vultr.com/docs/how-to-compile-nginx-from-source-on-ubuntu-16-04
https://www.nginx.com/resources/wiki/modules/fancy_index/

as well as the configuration parameters reported by `nginx -V` from the
stock Centos 7 installation of nginx. The configuration and systemd files in
`conf` are also derived (and stripped down) from that package.

Running `./go` will build the Docker image, which compiles nginx. It will
then create a tarball named `deploy.tar.gz` which can be unpacked into / on
a Centos 7 VM. From there you should be able to just type

    systemctl enable nginx
    systemctl start nginx
