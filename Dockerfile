FROM rust:bookworm

# Otherwise the `source` below won't work (default shell is `/bin/sh`)
SHELL ["/bin/bash", "-c"] 

ARG TARGET
ARG RELEASE
ARG DPKG_ARCHITECTURE

COPY . /makedeb
WORKDIR /makedeb/PKGBUILD

RUN apt-get update && apt-get install --no-install-recommends -y git jq curl ca-certificates libapt-pkg-dev asciidoctor

RUN touch /makedeb/PKGBUILD
RUN TARGET=${TARGET} RELEASE=${RELEASE} ./pkgbuild.sh > PKGBUILD

# We need this to extract the `depends` and `makedepends`
RUN source PKGBUILD
RUN apt-get install --no-install-recommends -y ${depends[@]}
RUN apt-get install --no-install-recommends -y ${makedepends[@]}

# Install `just`
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/bin

WORKDIR /makedeb
RUN VERSION=${pkgver}-${pkgrel} RELEASE=${RELEASE} TARGET=${TARGET} BUILD_COMMIT=$(git rev-parse HEAD) just prepare
RUN DPKG_ARCHITECTURE=${DPKG_ARCHITECTURE} just build
CMD [ "just", "package" ]
