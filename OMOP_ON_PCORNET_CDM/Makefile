# Set the current user's UID for Airflow
AIRFLOW_UID := $(shell id -u)

# Declare targets that are not actual files
.PHONY: build deploy jupyter

# Download docker-compose.yaml if it doesn't exist
build:
	@echo "Checking for docker-compose.yaml..."
	@if [ ! -f docker-compose.yaml ]; then \
		echo "Downloading docker-compose.yaml..."; \
		curl -LfO 'https://airflow.apache.org/docs/apache-airflow/stable/docker-compose.yaml'; \
	else \
		echo "docker-compose.yaml already exists."; \
	fi
	@echo "AIRFLOW_UID=$(AIRFLOW_UID)" > .env
	docker compose up airflow-init --build

# Start all Airflow services
deploy:
	docker compose up -d

stop:
	docker compose down

# Launch Jupyter Lab
jupyter:
	jupyter lab --allow-root --no-browser --NotebookApp.token=''
