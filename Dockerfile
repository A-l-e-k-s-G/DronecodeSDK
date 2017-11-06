#
# Development environment for DroneCore
#
# Author: Julian Oes <julian@oes.ch>
#

FROM ubuntu:xenial
MAINTAINER Julian Oes <julian@oes.ch>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
	&& apt-get -y --quiet --no-install-recommends install \
		cmake \
		build-essential \
		colordiff \
		astyle \
		git \
		libcurl4-openssl-dev \
		doxygen \
        autoconf \
        libtool \
        ca-certificates \
        autoconf \
        automake \
        python \
        python-pip \
        libtinyxml2-dev \
	&& apt-get -y autoremove \
	&& apt-get clean autoclean \
	&& rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

RUN pip install grpcio grpcio-tools

# Install gRPC according to https://github.com/grpc/grpc/blob/v1.6.x/INSTALL.md
# And to fix build error https://github.com/grpc/grpc/issues/12316
# Install gRPC and protobuf into /opt in order not to mess up the host system.
# Also, we need to patch the Makefile because it install the libraries with
# wrong versions.

RUN mkdir /opt/grpc && chown $USER:$USER /opt/grpc
RUN mkdir /opt/protobuf && chown $USER:$USER /opt/protobuf

ADD grpc/0001-Makefile-fix-wrong-SHARED-version-suffix.patch 0001-Makefile-fix-wrong-SHARED-version-suffix.patch

RUN git clone -b v1.6.x https://github.com/grpc/grpc \
    && cd grpc \
    && git submodule update --init \
    && git apply ../0001-Makefile-fix-wrong-SHARED-version-suffix.patch \
    && make -j8 HAS_SYSTEM_PROTOBUF=false \
    && make prefix=/opt/grpc install \
    && cd third_party/protobuf \
    && make clean \
    && ./configure --prefix=/opt/protobuf \
    && make -j8 \
    && make install \
    && cd ../../.. \
    && rm -rf grpc

ENV GRPC_DIR=/opt/grpc
ENV PROTOBUF_DIR=/opt/protobuf

CMD ["/bin/bash"]

WORKDIR "/home/docker1000/src/DroneCore"
