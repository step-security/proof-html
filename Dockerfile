FROM alpine:3.23@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659 AS base

RUN apk --no-cache add openjdk25

FROM base AS build-vnu

RUN apk add git python3 apache-ant maven

RUN git clone -n https://github.com/validator/validator.git

RUN cd validator \
    && git fetch \
    && git checkout 23f090a11bab8d0d4e698f1ffc197a4fe226a9cd

RUN cd validator \
    && sed -i 's/jetty-version" value="11.0.20"/jetty-version" value="11.0.25"/' build/build.xml \
    && sed -i 's/commons-fileupload-version" value="2.0.0-M2"/commons-fileupload-version" value="2.0.0-M4"/' build/build.xml \

RUN cd validator \
    && JAVA_HOME=/usr/lib/jvm/java-25-openjdk python checker.py dldeps

RUN cd validator \
    && JAVA_HOME=/usr/lib/jvm/java-25-openjdk python checker.py --offline build jar

FROM base

RUN apk --no-cache add build-base linux-headers ruby-dev
RUN apk --no-cache add curl
RUN gem install html-proofer -v 5.2.0

RUN apk --no-cache add bash

COPY --from=build-vnu /validator/build/dist/vnu.jar /bin/vnu.jar

COPY entrypoint.sh proof-html.rb /

ENTRYPOINT ["/entrypoint.sh"]
