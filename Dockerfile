FROM alpine:latest

RUN apk add --no-cache --update bash curl git texlive && \
    rm -rf /var/cache/apk/*

WORKDIR /project