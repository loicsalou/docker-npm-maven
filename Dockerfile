# using latest node alpine image https://hub.docker.com/_/node/


FROM node:12-alpine
LABEL maintainer="dev.salou@gmail.com"

## ===============================================
## START install git
RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

## END install git

## ===============================================
## START locale customization
#RUN locale-gen en_US.UTF-8
ENV LANG=fr_FR.UTF-8 \
    LANGUAGE=fr_FR.UTF-8 \
    LC_CTYPE=fr_FR.UTF-8 \
    LC_ALL=fr_FR.UTF-8
RUN apk add --update --no-cache socat curl tzdata findutils

ENV TZ=Europe/Paris
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

## END locale customization

## ===============================================
## START of https://hub.docker.com/_/openjdk/ (openjdk from alpine : https://github.com/docker-library/openjdk/blob/master/8/jdk/alpine/Dockerfile)
#FROM alpine:3.8

# A few reasons for installing distribution-provided OpenJDK:
#
#  1. Oracle.  Licensing prevents us from redistributing the official JDK.
#
#  2. Compiling OpenJDK also requires the JDK to be installed, and it gets
#     really hairy.
#
#     For some sample build times, see Debian's buildd logs:
#       https://buildd.debian.org/status/logs.php?pkg=openjdk-8

# Default to UTF-8 file.encoding
#ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_VERSION 8u171
ENV JAVA_ALPINE_VERSION 8.232.09-r0

RUN set -x \
	&& apk add --no-cache \
		openjdk8="$JAVA_ALPINE_VERSION" \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

# If you're reading this and have any feedback on how this image could be
# improved, please open an issue or a pull request so we can discuss it!
#
#   https://github.com/docker-library/openjdk/issues

## ===============================================
## START add python

RUN apk add --update \
    python \
    python-dev \
    py-pip \
    build-base && rm -rf /var/cache/apk/*

## END add python

## ===============================================
## START add JQ and danger

RUN apk update \
 && apk add jq \
 && rm -rf /var/cache/apk/*

RUN \
  # update packages
  apk update && apk upgrade && \

  # install ruby
  apk --no-cache add ruby ruby-dev ruby-bundler ruby-json ruby-irb ruby-rake ruby-bigdecimal ruby-rdoc && \

  # clear after installation
  rm -rf /var/cache/apk/*

RUN gem install danger && \
    gem install danger-commit_lint && \
    gem install danger-prose

## END add JQ and danger

## ===============================================
## START of maven from alpine (https://github.com/carlossg/docker-maven/blob/master/jdk-8-alpine/Dockerfile)

#FROM openjdk:8-jdk-alpine

RUN apk add --no-cache curl tar bash procps

ARG MAVEN_VERSION=3.5.4
ARG USER_HOME_DIR="/root"
ARG SHA=ce50b1c91364cb77efe3776f756a6d92b76d9038b0a0782f7d53acf1e997a14d
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

COPY mvn-entrypoint.sh /usr/local/bin/mvn-entrypoint.sh
COPY settings-docker.xml /usr/share/maven/ref/

ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]
CMD ["mvn"]

## END of maven from alpine
