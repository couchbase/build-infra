FROM amazonlinux:2 as seed

FROM scratch
COPY --from=seed /usr/local /usr/local
