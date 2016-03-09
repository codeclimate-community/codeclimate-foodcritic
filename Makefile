.PHONY: image

IMAGE_NAME ?= codeclimate/codeclimate-foodcritic

image:
	docker build --tag $(IMAGE_NAME) .

citest:
	docker run --rm \
	  --volume $(PWD)/spec:/usr/src/app/spec \
	  --workdir /usr/src/app $(IMAGE_NAME) rspec

test: image citest
