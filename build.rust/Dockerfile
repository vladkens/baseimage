ARG RUST_VERSION=1.84

FROM rust:${RUST_VERSION}-alpine AS chef
LABEL org.opencontainers.image.source="https://github.com/vladkens/baseimage"

WORKDIR /app
ENV CARGO_INCREMENTAL=0
ENV PKG_CONFIG_SYSROOT_DIR=/
RUN apk add --no-cache musl-dev openssl-dev zig && \
  cargo install --locked cargo-zigbuild cargo-chef && \
  rustup target add x86_64-unknown-linux-musl aarch64-unknown-linux-musl && \
  rm -rf $CARGO_HOME/registry/

ADD build.sh /scripts/build
RUN chmod +x /scripts/build && mkdir -p /out
