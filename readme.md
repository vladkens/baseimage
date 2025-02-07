# baseimage [![Actions](https://github.com/vladkens/baseimage/workflows/build/badge.svg)](https://github.com/vladkens/baseimage/actions)

Docker base images, inspired by [umputun/baseimage](https://github.com/umputun/baseimage).

## Rust Build Image

Rust has a long compile time for multi-arch images. A way to solve this problem was described in [this article](https://vnotes.pages.dev/fast-multi-arch-docker-for-rust/). Briefly, this image prepares cross-compilation flow to perform compilation on native CPU architecture rather than using QEMU, which dramatically increases building speed (~5x). Suitable for building web apps with multi-stage builds. Using this layer can reduce CI time by 3-4 min compare to manual cross-compilation setup.

- Image based on [rust:alpine](https://hub.docker.com/_/rust/)
- Pre-installed `cargo-chef`, `cargo-zigbuild`, `openssl-dev`
- Toolchains for `x86_64-unknown-linux-musl`, `aarch64-unknown-linux-musl`
- [`/scripts/build`](./build.rust/build.sh) command to reduce cargo-chef routine

`/scripts/build` has three commands:

- `prepare [recipe_file]` – Prepares recipe file (dependencies tree)
- `cook [recipe_file]` – Installs and compiles dependencies
- `final <bin_name>` – Builds actual binary file

`final` command will copy binaries to `/out/<bin_name>/linux/{amd64,arm64}`, making it easier to copy binary during runtime stage using `TARGETPLATFORM` argument.

### Usage

```Dockerfile
FROM --platform=$BUILDPLATFORM ghcr.io/vladkens/baseimage/rust:latest as chef

FROM chef AS planner
COPY Cargo.toml Cargo.lock .
RUN /scripts/build prepare

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN /scripts/build cook
COPY . .
RUN /scripts/build final my-app

# actual docker image, can use any baseimage
FROM alpine:latest AS runtime
WORKDIR /app
ARG TARGETPLATFORM
COPY --from=builder /out/my-app/${TARGETPLATFORM} /app/my-app

EXPOSE 8080
CMD ["/app/my-app"]
```
