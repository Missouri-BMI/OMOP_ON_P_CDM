
CREATE OR REPLACE FILE FORMAT {{ FILE_FORMAT }}
TYPE = CSV
FIELD_DELIMITER = ','
EMPTY_FIELD_AS_NULL = true 
TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
NULL_IF = ('NULL')
COMPRESSION=NONE
FIELD_OPTIONALLY_ENCLOSED_BY='"'; -- file format

CREATE OR REPLACE STAGE {{ SNOWFLAKE_STAGE }} FILE_FORMAT = {{ FILE_FORMAT }}; --stage

CREATE OR REPLACE PROCEDURE download_sample_tables()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    table_cursor CURSOR FOR 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = CURRENT_SCHEMA()
          AND table_name IN ('PERSON','DEATH','LOCATION','CARE_SITE','VISIT_OCCURRENCE',
                             'VISIT_DETAIL','PROCEDURE_OCCURRENCE','CONDITION_OCCURRENCE',
                             'CONDITION_ERA','OBSERVATION','OBSERVATION_PERIOD',
                             'MEASUREMENT','DRUG_EXPOSURE','CDM_SOURCE');
    table_name VARCHAR;
    copy_sql VARCHAR;
BEGIN
    FOR table_record IN table_cursor DO
        table_name := table_record.table_name;
        copy_sql := 'COPY INTO @{{ SNOWFLAKE_STAGE }}/' || LOWER(table_name) || '.csv ' ||
                    'FROM (SELECT * FROM ' || table_name || ' {{ LIMIT_PARAM }}) ' ||
                    '{{ COPY_PARAMETERS }};';
        EXECUTE IMMEDIATE copy_sql;
    END FOR;

    RETURN 'Files written to @{{ SNOWFLAKE_STAGE }}';
END;
$$;


-- Call the stored procedure
CALL download_sample_tables();

-- Now download from stage to local folder
GET @{{ SNOWFLAKE_STAGE }}/ {{ LOCAL_STAGE }}
  PATTERN='.*\.csv(\.gz)?$'
  OVERWRITE=TRUE;


