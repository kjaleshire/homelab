FROM ruby:3-slim-bookworm

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y bash build-essential ca-certificates curl \
        default-libmysqlclient-dev nano ruby-dev && \
    gem install mysql2 telegram-bot && \
    apt-get remove -y build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
