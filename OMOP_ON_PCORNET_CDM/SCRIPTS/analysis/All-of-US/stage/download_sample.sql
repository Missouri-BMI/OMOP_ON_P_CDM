
CREATE OR REPLACE FILE FORMAT {{ FILE_FORMAT }}
TYPE = CSV
FIELD_DELIMITER = ','
EMPTY_FIELD_AS_NULL = true 
TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
NULL_IF = ('NULL')
COMPRESSION=NONE
FIELD_OPTIONALLY_ENCLOSED_BY='"'; -- file format

CREATE OR REPLACE STAGE {{ SNOWFLAKE_STAGE }} FILE_FORMAT = {{ FILE_FORMAT }}; --stage


COPY INTO @{{ SNOWFLAKE_STAGE }}/person.csv FROM (SELECT * FROM person {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/death.csv FROM (SELECT * FROM death {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};

COPY INTO @{{ SNOWFLAKE_STAGE }}/location.csv FROM (SELECT * FROM location {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/care_site.csv FROM (SELECT * FROM care_site {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/visit_occurrence.csv FROM (SELECT * FROM visit_occurrence {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/visit_detail.csv FROM (SELECT * FROM visit_detail {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/procedure_occurrence.csv FROM (SELECT * FROM procedure_occurrence {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/condition_occurrence.csv FROM (SELECT * FROM condition_occurrence {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/condition_era.csv FROM (SELECT * FROM condition_era {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/observation.csv FROM (SELECT * FROM observation {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/observation_period.csv FROM (SELECT * FROM observation_period {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/measurement.csv FROM (SELECT * FROM measurement {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/drug_exposure.csv FROM (SELECT * FROM drug_exposure {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};

COPY INTO @{{ SNOWFLAKE_STAGE }}/cdm_source.csv FROM (SELECT * FROM cdm_source {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};


GET @{{ SNOWFLAKE_STAGE }}/person.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/death.csv {{ LOCAL_STAGE }};

GET @{{ SNOWFLAKE_STAGE }}/location.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/care_site.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/visit_occurrence.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/visit_detail.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/procedure_occurrence.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/condition_occurrence.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/condition_era.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/observation.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/observation_period.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/measurement.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/drug_exposure.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/cdm_source.csv {{ LOCAL_STAGE }};
