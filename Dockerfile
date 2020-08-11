FROM frolvlad/alpine-glibc

RUN apk update && \
    apk add --no-cache bash mongodb-tools groff less curl sudo && \
    rm /var/cache/apk/* && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install

RUN mkdir -p /backup/data

COPY run.sh /backup/run

WORKDIR /backup

ENTRYPOINT ["./run"]
CMD ["backup"]
