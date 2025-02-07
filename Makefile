.PHONY: build clean

tag=baseimage/rust:latest
ver=1.84

build:
	docker build --build-arg RUST_VERSION=$(ver) -t $(tag) -f build.rust/Dockerfile build.rust
	docker images -q $(tag) | xargs docker inspect -f '{{.Size}}' | xargs numfmt --to=iec

clean:
	docker rmi --force $(shell docker images -f "dangling=true" -q)
