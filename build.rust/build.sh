#!/bin/sh

set -x
RECIPE_FILE=${2:-recipe.json}

case "$1" in
  prepare)
    mkdir src && echo "fn main() {}" > src/main.rs
    cargo chef prepare --recipe-path "$RECIPE_FILE"
    ;;
  
  cook)
    cargo chef cook --recipe-path "$RECIPE_FILE" --release --zigbuild \
      --target x86_64-unknown-linux-musl --target aarch64-unknown-linux-musl
    ;;
  
  final)
    mkdir -p /out/$2/linux
    cargo zigbuild --release --bin $2 \
      --target x86_64-unknown-linux-musl --target aarch64-unknown-linux-musl
    cp target/x86_64-unknown-linux-musl/release/$2 /out/$2/linux/amd64
    cp target/aarch64-unknown-linux-musl/release/$2 /out/$2/linux/arm64
    ;;
  
  *)
    echo "Unknown command. Use 'prepare', 'cook', or 'final'."
    exit 1
    ;;
esac
