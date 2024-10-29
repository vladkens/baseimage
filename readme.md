# baseimage [![Actions](https://github.com/vladkens/baseimage/workflows/build/badge.svg)](https://github.com/vladkens/baseimage/actions)

Docker base images, inspired by [umputun/baseimage](https://github.com/umputun/baseimage).

## Rust Build Image

Rust has a long compile time for multi-arch images. A way to solve this problem was described in [this article](https://vnotes.pages.dev/fast-multi-arch-docker-for-rust/). Briefly, this image performs cross-compilation on native arch during build phase, after which the `bins` can be copied into runtime image with target arch. It is suitable for building web apps with multi-stage builds. Using this layer can reduce CI time by ~3 min.

- Image based on [rust:alpine](https://hub.docker.com/_/rust/)
- Pre-installed `cargo-chef`, `cargo-zigbuild`, `openssl-dev`
- Toolchains for `x86_64-unknown-linux-musl`, `aarch64-unknown-linux-musl`
- [`/scripts/build`](./build.rust/build.sh) command to reduce cargo-chef routine

`/scripts/build` have 3 commands:
- `prepare [recipe_file]` – preparing recipe file (used to cache compiled deps)
- `cook [recipe_file]` – install and compile deps
- `final <bin_name>` – build actual binary file

`final` command will copy binaries to `/out/<bin_name>/linux/{amd64,arm64}` to make it easier to copy in runtime stage with `TARGETPLATFORM` arg.

### Usage

```Dockerfile
FROM --platform=$BUILDPLATFORM baseimage/rust as chef

FROM chef AS planner
COPY Cargo.toml Cargo.lock .
RUN /scripts/build prepare ./recipe.json

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

EXPOSE ${PORT}
CMD ["/app/my-app"]
```
