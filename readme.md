# baseimage [![Build](https://github.com/vladkens/baseimage/workflows/build/badge.svg)](https://github.com/vladkens/baseimage/actions)

Docker base image that compiles Rust binaries for `amd64` and `arm64` natively — no QEMU, no emulation slowdowns.

- **~5× faster builds.** Compiles on the native CPU via `cargo-zigbuild` instead of emulating the target arch with QEMU.
- **Saves 3–4 min of CI time.** Drop it into a multi-stage Dockerfile and cross-compilation is already configured.
- **Both targets, zero setup.** Pre-installed toolchains for `x86_64-unknown-linux-musl` and `aarch64-unknown-linux-musl`, `cargo-chef`, `cargo-zigbuild`, `openssl-dev`.
- **Layer caching built in.** `cargo-chef` splits dependency compilation from your own code, so deps are only rebuilt when `Cargo.lock` changes.
- **Static musl binaries.** Outputs are ready to drop into `FROM scratch` or any minimal runtime image.

Inspired by [umputun/baseimage](https://github.com/umputun/baseimage). Unlike a manual cross-compilation setup, this image wraps the full `cargo-chef` workflow into three commands so you don't repeat the boilerplate in every project.

## Install

```
ghcr.io/vladkens/baseimage/rust:latest   # latest stable Rust
ghcr.io/vladkens/baseimage/rust:1.94     # pinned version
```

Rebuilt weekly. Available versions: `1.92`, `1.93`, `1.94`.

## Usage

```dockerfile
FROM --platform=$BUILDPLATFORM ghcr.io/vladkens/baseimage/rust:latest AS chef

FROM chef AS planner
COPY Cargo.toml Cargo.lock .
RUN /scripts/build prepare          # → recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN /scripts/build cook             # compiles deps for both targets
COPY . .
RUN /scripts/build final my-app     # → /out/my-app/linux/{amd64,arm64}

FROM alpine:latest AS runtime
WORKDIR /app
ARG TARGETPLATFORM
COPY --from=builder /out/my-app/${TARGETPLATFORM} /app/my-app
EXPOSE 8080
CMD ["/app/my-app"]
```

### `/scripts/build` commands

| Command | What it does |
|---|---|
| `prepare [recipe_file]` | Runs `cargo chef prepare` — snapshots the dependency tree into `recipe.json` |
| `cook [recipe_file]` | Runs `cargo chef cook` — compiles all deps for both musl targets |
| `final <bin_name>` | Builds the binary and copies it to `/out/<bin_name>/linux/amd64` and `/out/<bin_name>/linux/arm64` |

The `final` output layout matches Docker's `$TARGETPLATFORM` variable, so copying the right binary in the runtime stage is a one-liner.
