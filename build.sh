#!/usr/bin/env bash

docker build --build-arg http_proxy=http://proxy-bvcol.admin.ch:8080 --build-arg https_proxy=http://proxy-bvcol.admin.ch:8080 -t loicsalou/docker-npm-maven:1.3.0 .
