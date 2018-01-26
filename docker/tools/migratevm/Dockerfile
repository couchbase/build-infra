FROM perl:5.26.1
MAINTAINER ceej@couchbase.com

RUN cpan App::cpanminus
RUN cpanm RPC::XML IO::Prompt Number::Format IO::Socket::SSL LWP::Protocol::https

COPY migrate-vm /usr/src/myapp
WORKDIR /usr/src/myapp
ENTRYPOINT [ "perl", "./migratevm.pl" ]
