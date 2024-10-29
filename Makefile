tag=baseimage/rust:latest

build:
	docker build -t $(tag) -f build.rust/Dockerfile build.rust
	docker images -q $(tag) | xargs docker inspect -f '{{.Size}}' | xargs numfmt --to=iec
