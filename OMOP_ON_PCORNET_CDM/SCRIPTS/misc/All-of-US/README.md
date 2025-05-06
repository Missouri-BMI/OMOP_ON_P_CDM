aws s3 cp s3://mu-ohdsi-atlas/csv/csv/ ./csv --recursive --profile mhmcb

docker-compose --env-file ./env/dev/.env up --build