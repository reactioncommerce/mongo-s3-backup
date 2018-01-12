FROM alpine:latest

RUN apk update && \
    apk add --no-cache bash mongodb-tools groff less python py-pip && \
    pip install awscli && \
    apk del --purge py-pip && \
    rm /var/cache/apk/*

RUN mkdir -p /backup/data

COPY run.sh /backup/run

WORKDIR /backup

ENTRYPOINT ["./run"]
CMD ["backup"]
