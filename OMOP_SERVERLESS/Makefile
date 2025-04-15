# Variables for Atlas
ATLAS_DEV_REPO=500206249851.dkr.ecr.us-east-2.amazonaws.com/ohdsi-atlas
ATLAS_PROD_REPO=063312575449.dkr.ecr.us-east-2.amazonaws.com/ohdsi-atlas
ATLAS_DEV_WEBAPI_URL=https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/
ATLAS_PROD_WEBAPI_URL=https://ohdsi-webapi.nextgenbmi.umsystem.edu/WebAPI/

# Variables for WebAPI
WEBAPI_DEV_REPO=500206249851.dkr.ecr.us-east-2.amazonaws.com/ohdsi-webapi
WEBAPI_PROD_REPO=063312575449.dkr.ecr.us-east-2.amazonaws.com/ohdsi-webapi

# Variables
AWS_PROFILE_DEV := mhmcb
AWS_PROFILE_PROD := mhmcb-prod
AWS_REGION := us-east-2
ECR_REPO_DEV :=  500206249851.dkr.ecr.us-east-2.amazonaws.com
ECR_REPO_PROD := 063312575449.dkr.ecr.us-east-2.amazonaws.com

TAG := latest

# AWS Login
aws-login-dev:
	aws sso login --profile $(AWS_PROFILE_DEV)

aws-login-prod:
	aws sso login --profile $(AWS_PROFILE_PROD)

# Docker Login
docker-login-dev:
	aws ecr get-login-password --region $(AWS_REGION) --profile $(AWS_PROFILE_DEV) | docker login --username AWS --password-stdin $(ECR_REPO_DEV)

docker-login-prod:
	aws ecr get-login-password --region $(AWS_REGION) --profile $(AWS_PROFILE_PROD) | docker login --username AWS --password-stdin $(ECR_REPO_PROD)

# Targets for Atlas
atlas-dev:
	docker build --platform=linux/amd64 \
		-t $(ATLAS_DEV_REPO) \
		--no-cache \
		--build-arg WEBAPI_URL=$(ATLAS_DEV_WEBAPI_URL) \
		Atlas

atlas-prod:
	docker build --platform=linux/amd64 \
		-t $(ATLAS_PROD_REPO) \
		--no-cache \
		--build-arg WEBAPI_URL=$(ATLAS_PROD_WEBAPI_URL) \
		Atlas

# Targets for WebAPI
webapi-dev:
	docker build --platform=linux/amd64 \
		-t $(WEBAPI_DEV_REPO) \
		--no-cache \
		--build-arg ENV=dev \
		WebAPI

webapi-prod:
	docker build --platform=linux/amd64 \
		-t $(WEBAPI_PROD_REPO) \
		--no-cache \
		--build-arg ENV=prod \
		WebAPI


# Snowflake DDL Scripts
snowflake-ddl-results:
	curl -X GET "https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/ddl/results?dialect=snowflake&schema=results&vocabSchema=cdm&tempSchema=temp&initConceptHierarchy=true" -o RESULTS_SNOWFLAKE.sql

snowflake-ddl-achilles:
	curl -X GET "https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/ddl/achilles?dialect=snowflake&schema=results&vocabSchema=cdm" -o ACHILLES_SNOWFLAKE.sql

webapi-refresh:
	curl -X GET "https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/source/refresh"

webapi-sources:
	curl -X GET "https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/source/sources"

# Health Checks
health-check-webapi:
	curl -X GET "https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/info"

health-check-atlas:
	curl -X GET "https://atlas-dev.nextgenbmi.umsystem.edu/atlas"
