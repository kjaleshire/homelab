# MySQL repo doesn't support bookworm just yet
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y bash bzip2 ca-certificates curl git gnupg lsb-release rclone wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install mysql client
RUN curl -s -S -L -O https://dev.mysql.com/get/mysql-apt-config_0.8.25-1_all.deb && \
    dpkg -i mysql-apt-config_0.8.25-1_all.deb && \
    rm -rf mysql-apt-config_0.8.25-1_all.deb && \
    apt-get update && \
    apt-get install -y mysql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash"]
