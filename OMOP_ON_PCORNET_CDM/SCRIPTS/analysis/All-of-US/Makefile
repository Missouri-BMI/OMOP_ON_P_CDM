IMAGE_NAME=allofus-analysis
CONTAINER_NAME=allofus-analysis-container
HOST_VOLUME=$(PWD)/stage/cdm
CONTAINER_VOLUME=/home/cdm

.PHONY: stage build run clean

stage: 
	cd stage && python stage_snowflake.py

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