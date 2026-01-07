# Set the current user's UID for Airflow
AIRFLOW_UID := $(shell id -u)

# Download docker-compose.yaml if it doesn't exist
airflow-omop-build:
	@echo "Checking for docker-compose.yaml..."
	@if [ ! -f docker-compose.yaml ]; then \
		echo "Downloading docker-compose.yaml..."; \
		curl -LfO 'https://airflow.apache.org/docs/apache-airflow/3.0.2/docker-compose.yaml'; \
	else \
		echo "docker-compose.yaml already exists."; \
	fi
	@echo "AIRFLOW_UID=$(AIRFLOW_UID)" > .env
	docker compose up airflow-init --build

# Start all Airflow services
airflow-omop-deploy:
	docker compose up -d

airflow-omop-connections:
	@echo "Creating datasource connections..."
	docker compose exec airflow-apiserver bash -c '\
		set -euo pipefail; \
		BASE_DIR="/opt/airflow/env"; \
		echo "=== Installing Airflow connections (Snowflake) ==="; \
		for acct_dir in "$$BASE_DIR"/*/; do \
			acct="$$(basename "$$acct_dir")"; \
			script="$$acct_dir/connections.sh"; \
			if [ -f "$$script" ]; then \
				echo ""; \
				echo ">>> Running connection script for account: $$acct"; \
				bash "$$script"; \
			else \
				echo "!!! Skipping $$acct (connections.sh not found)"; \
			fi; \
		done; \
		echo ""; \
		echo "✅ Done installing all connections." \
	'
airflow-omop-stop:
	docker compose down

airflow-omop-clean:
	docker compose down --volumes --rmi all

# Launch Jupyter Lab
jupyter:
	jupyter lab --allow-root --no-browser --NotebookApp.token=''
