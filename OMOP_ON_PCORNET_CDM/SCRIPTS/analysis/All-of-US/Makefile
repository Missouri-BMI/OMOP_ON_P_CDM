IMAGE_NAME=allofus-analysis
CONTAINER_NAME=allofus-analysis-container
HOST_VOLUME=$(PWD)/stage/cdm
CONTAINER_VOLUME=/home/cdm

.PHONY: build run clean

build:
	docker build --platform linux/amd64 -t $(IMAGE_NAME) .

run:
	docker run --rm -it \
		--platform linux/amd64 \
		--name $(CONTAINER_NAME) \
		-v $(HOST_VOLUME):$(CONTAINER_VOLUME) \
		$(IMAGE_NAME)

clean:
	docker rmi $(IMAGE_NAME) || true