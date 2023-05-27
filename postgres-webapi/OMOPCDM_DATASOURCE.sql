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