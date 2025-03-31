FROM apache/airflow:2.10.0-python3.12


# Install Python dependencies
ADD requirements.txt .
RUN pip install apache-airflow==${AIRFLOW_VERSION} -r requirements.txt
