--- Postgresql
INSERT INTO source (source_id, source_name, source_key, source_connection, source_dialect) 
SELECT nextval('source_sequence'), 'My Cdm', 'MY_CDM', 'jdbc:postgresql://ohdsi-atlas.ctsvcfrduobf.us-east-2.rds.amazonaws.com:5432/omop_cdm?user=mhmcb&password=Password123&OpenSourceSubProtocolOverride=true', 'postgresql';

INSERT INTO source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) 
SELECT nextval('source_daimon_sequence'), source_id, 0, 'cdm', 0
FROM source
WHERE source_key = 'MY_CDM'
;

INSERT INTO source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) 
SELECT nextval('source_daimon_sequence'), source_id, 1, 'cdm', 1
FROM source
WHERE source_key = 'MY_CDM'
;

INSERT INTO source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) 
SELECT nextval('source_daimon_sequence'), source_id, 2, 'results', 1
FROM source
WHERE source_key = 'MY_CDM'
;

INSERT INTO source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) 
SELECT nextval('source_daimon_sequence'), source_id, 5, 'temp', 0
FROM source
WHERE source_key = 'MY_CDM'
;


----SNOWFLAKE----
INSERT INTO webapi.source (source_id, source_name, source_key, source_connection, source_dialect,username, password) 
SELECT nextval('webapi.source_sequence'), 'MU PCORNET CDM', 'PCORNET_CDM', 'jdbc:snowflake://xp02744.us-east-2.aws.snowflakecomputing.com/?db=OMOP_CDM&schema=RESULTS&warehouse=ATLAS_WH&role=OMOP_ATLAS&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true', 'snowflake', 'SERVICE_USER_ATLAS', 'XGU$4<uf}H#8}3N';

INSERT INTO webapi.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) 
SELECT nextval('webapi.source_daimon_sequence'), source_id, 0, 'CDM', 0
FROM webapi.source
WHERE source_key = 'PCORNET_CDM'
;

INSERT INTO webapi.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) 
SELECT nextval('webapi.source_daimon_sequence'), source_id, 1, 'VOCABULARY', 1
FROM webapi.source
WHERE source_key = 'PCORNET_CDM'
;

INSERT INTO webapi.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) 
SELECT nextval('webapi.source_daimon_sequence'), source_id, 2, 'RESULTS', 1
FROM webapi.source
WHERE source_key = 'PCORNET_CDM'
;

INSERT INTO webapi.source_daimon (source_daimon_id, source_id, daimon_type, table_qualifier, priority) 
SELECT nextval('webapi.source_daimon_sequence'), source_id, 5, 'TEMP', 0
FROM webapi.source
WHERE source_key = 'PCORNET_CDM'
;