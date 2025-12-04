FROM alpine:3.23@sha256:51183f2cfa6320055da30872f211093f9ff1d3cf06f39a0bdb212314c5dc7375 AS base

RUN apk --no-cache add openjdk21

FROM base AS build-vnu

RUN apk add git python3 apache-ant

RUN git clone -n https://github.com/validator/validator.git \
    && cd validator \
    && git checkout 73476a51eaa3edc43acd5466b48bddcba77c7844 \
    && sed -i 's/jetty-version" value="11.0.20"/jetty-version" value="11.0.25"/' build/build.xml \
    && sed -i 's/commons-fileupload-version" value="2.0.0-M2"/commons-fileupload-version" value="2.0.0-M4"/' build/build.xml \
    && sed -i 's/9.2.25.v20180606/9.4.56.v20240826/' langdetect/pom.xml \
    && JAVA_HOME=/usr/lib/jvm/java-21-openjdk python checker.py dldeps build jar

FROM base

RUN apk --no-cache add build-base linux-headers ruby-dev
RUN apk --no-cache add curl
RUN gem install html-proofer -v 5.0.10

RUN apk --no-cache add bash

COPY --from=build-vnu /validator/build/dist/vnu.jar /bin/vnu.jar

COPY entrypoint.sh proof-html.rb /

ENTRYPOINT ["/entrypoint.sh"]
