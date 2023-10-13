#!/usr/bin/env bash

set -e -u -x -o pipefail

TAG=2023061400
IMAGE=ghcr.io/kjaleshire/mysql-b2-backup

docker build -t $IMAGE:$TAG .
docker push $IMAGE:$TAG
