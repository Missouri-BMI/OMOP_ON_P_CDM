-- Procedure to drop OMOP CDM patient-related tables and views
CREATE OR REPLACE PROCEDURE {{ cdm_db }}.{{ cdm_schema }}.cleanup_omop_cdm_tables()
RETURNS STRING
LANGUAGE SQL
AS
DECLARE
    drop_stmt TEXT;
    table_type TEXT;
    cur CURSOR FOR  
        SELECT 
            TABLE_SCHEMA,
            TABLE_NAME,
            TABLE_TYPE
        FROM {{ cdm_db }}.INFORMATION_SCHEMA.TABLES
        WHERE UPPER(TABLE_NAME) IN (
            'PERSON', 'DEATH', 'PROVIDER', 'LOCATION', 'CARE_SITE', 
            'VISIT_OCCURRENCE', 'VISIT_DETAIL', 'PROCEDURE_OCCURRENCE',
            'CONDITION_OCCURRENCE', 'CONDITION_ERA', 'OBSERVATION',
            'OBSERVATION_PERIOD', 'MEASUREMENT', 'DRUG_EXPOSURE',
            'DEVICE_EXPOSURE', 'CDM_SOURCE'
        )
        AND TABLE_TYPE IN ('BASE TABLE', 'VIEW')
        AND TABLE_SCHEMA = '{{ cdm_schema }}';
BEGIN
    FOR rec IN cur 
    DO  
        table_type := rec.TABLE_TYPE;
        IF (table_type = 'BASE TABLE') THEN
            drop_stmt := 'DROP TABLE ' || '{{ cdm_db }}' || '.' || rec.TABLE_SCHEMA || '.' || rec.TABLE_NAME;
            EXECUTE IMMEDIATE :drop_stmt;
        ELSE
            drop_stmt := 'DROP VIEW ' || '{{ cdm_db }}' || '.' || rec.TABLE_SCHEMA || '.' || rec.TABLE_NAME;
            EXECUTE IMMEDIATE :drop_stmt;
        END IF;
    END FOR;
    RETURN 'OMOP CDM tables/views dropped successfully.';
END;


call {{ cdm_db }}.{{ cdm_schema }}.cleanup_omop_cdm_tables();