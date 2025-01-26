#FROM 5keeve/pocketbook-sdk:6.3.0-b288-v1
FROM pbdev

LABEL maintainer="https://github.com/Skeeve"

#ARG GOLANG_VERSION=17.2
ENV GOLANG_VERSION=23.5

RUN apt-get install apt-transport-https ca-certificates && \
    apt-get update && \
    apt-get install -y xz-utils git curl && \
    apt-get clean

# download Pocketbook SDK
ADD ./patches/* /tmp/

# download specified Go binary release that will act as a bootstrap compiler for Go toolchain
# download sources for that release and apply the patch
# build a new toolchain and remove an old one
WORKDIR /gosrc

RUN curl https://dl.google.com/go/go1.$GOLANG_VERSION.linux-amd64.tar.gz | tar xzf - --directory=/ \
 && curl https://dl.google.com/go/go1.$GOLANG_VERSION.src.tar.gz         | tar xzf - --directory=/gosrc
 
RUN patch /gosrc/go/src/cmd/go/internal/work/exec.go < /tmp/go-pb.patch
#RUN patch /gosrc/go/src/net/dnsconfig_unix.go < /tmp/dns-pb.patch
RUN cd /gosrc/go/src && GOROOT_BOOTSTRAP=/go ./make.bash
RUN rm -r /go && mv /gosrc/go /go && rm -r /gosrc

WORKDIR /app
VOLUME /app

ENTRYPOINT ["/go/bin/go"]
CMD ["build"]

ADD ./go.mod ./go.sum ./*.go ./*.c ./*.h /gopath/src/github.com/dennwc/inkview/

ARG CC=${SDK_BASE}/usr/bin/arm-obreey-linux-gnueabi-clang
ARG GOOS=linux
ARG GOARCH=arm
ARG GOARM=7
ARG CGO_ENABLED=1

ENV GOROOT=/go GOPATH=/gopath PATH="/go/bin:${SDK_BASE}/usr/bin:$PATH" CC=${CC} GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} CGO_ENABLED=${CGO_ENABLED}

RUN apt install libtinfo5
