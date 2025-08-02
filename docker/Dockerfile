FROM ubuntu:20.04

ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive 

RUN set -eux \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
        apt-transport-https=2.0.11 \
        dirmngr \
        gnupg \
        gpg \
        curl=7.68.0-1ubuntu2.25 \
        make=4.2.1-1.2 \
        ca-certificates=20240203~20.04.1 \
        software-properties-common=0.99.9.12 \
        s3cmd=2.0.2-1ubuntu1 \
        anacron=2.3-29 \
        cron=3.0pl1-136ubuntu1 \
        wget=1.20.3-1ubuntu2.1 \
        unzip=6.0-25ubuntu1.2 \
        jq=1.6-1ubuntu0.20.04.1
RUN set -eux \
    && apt-get update \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo \
         "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
         $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
         tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
        docker-ce-cli \
    && rm -rf /var/lib/apt/lists/* /var/cache/debconf \
    && apt-get clean

WORKDIR /
COPY docker/entrypoint.sh ./

WORKDIR /app
COPY docker/*.sh ./

RUN mkfifo --mode 0666 /var/log/cron.log

CMD ["/bin/sh", "/entrypoint.sh"]
