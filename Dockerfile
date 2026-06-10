FROM alpine:3.24@sha256:a2d49ea686c2adfe3c992e47dc3b5e7fa6e6b5055609400dc2acaeb241c829f4 AS base

RUN apk --no-cache add openjdk25

FROM base AS build-vnu

RUN apk add git python3 apache-ant maven

RUN git clone -n https://github.com/validator/validator.git

RUN cd validator \
    && git fetch \
    && git checkout 23f090a11bab8d0d4e698f1ffc197a4fe226a9cd

RUN cd validator \
    && sed -i 's/jetty-version" value="11.0.20"/jetty-version" value="11.0.25"/' build/build.xml \
    && sed -i 's/commons-fileupload-version" value="2.0.0-M2"/commons-fileupload-version" value="2.0.0-M4"/' build/build.xml

RUN cd validator \
    && JAVA_HOME=/usr/lib/jvm/java-25-openjdk python checker.py dldeps

RUN cd validator \
    && JAVA_HOME=/usr/lib/jvm/java-25-openjdk python checker.py --offline build jar

FROM base

RUN apk --no-cache add build-base linux-headers ruby-dev
RUN apk --no-cache add curl jq
RUN gem install html-proofer -v 5.2.0

RUN apk --no-cache add bash

COPY --from=build-vnu /validator/build/dist/vnu.jar /bin/vnu.jar

COPY entrypoint.sh proof-html.rb /

ENTRYPOINT ["/entrypoint.sh"]
