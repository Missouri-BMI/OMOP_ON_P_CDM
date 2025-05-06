FROM apache/airflow:3.0.0


# Install Python dependencies
ADD requirements.txt .
RUN pip install apache-airflow==${AIRFLOW_VERSION} -r requirements.txt
