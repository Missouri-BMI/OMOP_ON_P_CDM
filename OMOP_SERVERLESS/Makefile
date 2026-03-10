# ==========================================
# Environment Configuration
# ==========================================
# Default to 'dev' if ENV is not passed in the command line
ENV ?= dev

ifeq ($(ENV), prod)
    AWS_ACCOUNT_ID := 063312575449
    AWS_PROFILE    := mhmcb-prod
    WEBAPI_URL     := https://ohdsi-webapi.nextgenbmi.umsystem.edu/WebAPI/
    ATLAS_URL      := https://atlas.nextgenbmi.umsystem.edu/atlas
else
    AWS_ACCOUNT_ID := 500206249851
    AWS_PROFILE    := mhmcb
    WEBAPI_URL     := https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/
    ATLAS_URL      := https://atlas-dev.nextgenbmi.umsystem.edu/atlas
endif

# Common AWS & ECR Variables
AWS_REGION := us-east-2
ECR_REPO   := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
TAG        := latest

# Ares Variables
IMAGE_NAME         := ohdsi-ares
CONTAINER_NAME     := ohdsi-ares
HOST_DATA_DIR      := $(abspath ../OMOP_ON_PCORNET_CDM/output/data)
CONTAINER_DATA_DIR := /usr/share/nginx/html/ares/data


# ==========================================
# AWS & Docker Login
# ==========================================
aws-login:
	aws sso login --profile $(AWS_PROFILE)

docker-login:
	aws ecr get-login-password --region $(AWS_REGION) --profile $(AWS_PROFILE) | \
	docker login --username AWS --password-stdin $(ECR_REPO)


# ==========================================
# Atlas & WebAPI Build
# ==========================================
atlas:
	docker build --platform=linux/amd64 \
		-t $(ECR_REPO)/ohdsi-atlas:$(TAG) \
		--no-cache \
		--build-arg WEBAPI_URL=$(WEBAPI_URL) \
		Atlas

webapi:
	docker build --platform=linux/amd64 \
		-t $(ECR_REPO)/ohdsi-webapi:$(TAG) \
		--no-cache \
		--build-arg ENV=$(ENV) \
		WebAPI


# ==========================================
# Utilities & Health Checks
# ==========================================
snowflake-ddl-results:
	curl -X GET "$(WEBAPI_URL)ddl/results?dialect=snowflake&schema=results&vocabSchema=cdm&tempSchema=temp&initConceptHierarchy=true" -o RESULTS_SNOWFLAKE.sql

snowflake-ddl-achilles:
	curl -X GET "$(WEBAPI_URL)ddl/achilles?dialect=snowflake&schema=results&vocabSchema=cdm" -o ACHILLES_SNOWFLAKE.sql

webapi-refresh:
	curl -X GET "$(WEBAPI_URL)source/refresh"

webapi-sources:
	curl -X GET "$(WEBAPI_URL)source/sources"

health-check-webapi:
	curl -X GET "$(WEBAPI_URL)info"

health-check-atlas:
	curl -X GET "$(ATLAS_URL)"


# ==========================================
# Ares Local Container
# ==========================================
ares-build:
	docker build --rm -t $(IMAGE_NAME) Ares

ares-run:
	@echo "Checking for existing container..."
	-docker stop $(CONTAINER_NAME) >/dev/null 2>&1
	-docker rm $(CONTAINER_NAME) >/dev/null 2>&1
	@if [ ! -d "$(HOST_DATA_DIR)" ]; then \
		echo "ERROR: Host data directory does not exist: $(HOST_DATA_DIR)"; \
		exit 1; \
	fi
	@echo "Starting $(CONTAINER_NAME) mounting $(HOST_DATA_DIR)..."
	docker run --name $(CONTAINER_NAME) \
		-p 8081:80 \
		-v "$(HOST_DATA_DIR):$(CONTAINER_DATA_DIR):ro" \
		-d $(IMAGE_NAME)
	@echo "Ares is running at http://localhost:8081"

ares-stop:
	docker stop $(CONTAINER_NAME)

ares-clean:
	-docker rm -f $(CONTAINER_NAME)
	-docker rmi $(IMAGE_NAME)