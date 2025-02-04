# OMOP_ON_P_CDM

steps:

## Deploy docker containers
    
- docker-compose up --build

## Shut down containers
- docker-compose down 
--Note: Clear volume if you want to populate database again "docker volume rm <volume-name>"

## Generate synthetic data
https://github.com/OHDSI/ETL-Synthea
```
java -jar synthea-with-dependencies.jar -p 100 --exporter.csv.export true
```
## Download vocabulary from Github:
/ETO_OMOP/output/

## Perform Achillies


-o myfile.txt

psql -a -U "$POSTGRES_USER" -d omop_cdm  -f /scripts/OMOPCDM_GENERATED.sql
psql -a -U "$POSTGRES_USER" -d ohdsi_webapi -c 'set search_path to webapi;' -f /scripts/OMOPCDM_DATASOURCE.sql


####

aws sso login --profile <profile_name>
aws ecr get-login-password --profile <profile_name> | docker login --username AWS --password-stdin 500206249851.dkr.ecr.us-east-2.amazonaws.com

docker build --platform=linux/amd64 --no-cache -t 500206249851.dkr.ecr.us-east-2.amazonaws.com/ohdsi-atlas .
docker push 500206249851.dkr.ecr.us-east-2.amazonaws.com/ohdsi-atlas


docker build --platform=linux/amd64 --no-cache -t 500206249851.dkr.ecr.us-east-2.amazonaws.com/ohdsi-webapi .
docker push 500206249851.dkr.ecr.us-east-2.amazonaws.com/ohdsi-webapi


## snowflake
curl -X GET "https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/ddl/achilles?dialect=snowflake&schema=results&vocabSchema=VOCABULARY" -o ACHILLES_SNOWFLAKE.sql

curl -X GET "https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/ddl/results?dialect=snowflake&schema=results&vocabSchema=VOCABULARY&tempSchema=temp&initConceptHierarchy=true" -o RESULTS_SNOWFLAKE.sql


WEBAPI_URL https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/

## Health Checks
curl -X GET "https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/info"

curl -X GET https://atlas-dev.nextgenbmi.umsystem.edu/atlas
curl -X GET https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/info
curl -X GET https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/source/refresh
curl -X GET https://ohdsi-webapi-dev.nextgenbmi.umsystem.edu/WebAPI/source/sources