# Variables
REGION := us-east-2
DEV_ACCOUNT := 500206249851
PROD_ACCOUNT := 063312575449
REPO_NAME := pgadmin-readonly

# Determine Account ID based on environment
ifeq ($(ENV), prod)
    ACCOUNT_ID := $(PROD_ACCOUNT)
else ifeq ($(ENV), dev)
    ACCOUNT_ID := $(DEV_ACCOUNT)
else
    # Default to error if ENV is not provided correctly
    ACCOUNT_ID := UNKNOWN
endif

IMAGE_URI := $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(REPO_NAME)

.PHONY: build check-env

# Guard to ensure ENV is set correctly
check-env:
	@if [ "$(ACCOUNT_ID)" = "UNKNOWN" ]; then \
		echo "Error: Please specify ENV=dev or ENV=prod"; \
		exit 1; \
	fi

## Build the docker image
build: check-env
	docker build --platform=linux/amd64 \
		-t $(IMAGE_URI) \
		--no-cache \
		.