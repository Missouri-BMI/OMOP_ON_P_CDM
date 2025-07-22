CREATE TABLE {{ cdm_db }}.{{ vocabulary }}.cdm_source (
    cdm_source_name varchar(255) NOT NULL,
    cdm_source_abbreviation varchar(25) NOT NULL,
    cdm_holder varchar(255) NOT NULL,
    source_description TEXT NULL,
    source_documentation_reference varchar(255) NULL,
    cdm_etl_reference varchar(255) NULL,
    source_release_date date NOT NULL,
    cdm_release_date date NOT NULL,
    cdm_version varchar(10) NULL,
    cdm_version_concept_id integer NOT NULL,
    vocabulary_version varchar(20) NOT NULL
) AS
WITH SOURCE_VERSION AS (
    SELECT 
        MAX(REFRESH_ENCOUNTER_DATE) AS SOURCE_RELEASE_DATE 
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ harvest_table }}
)
SELECT
    'MU CDM Data' AS cdm_source_name,
    'MU' AS cdm_source_abbreviation,
    'MU NextGen BMI' AS cdm_holder,
    'PCORNET CDM IN OMOP CDM FORMAT' AS source_description,
    NULL AS source_documentation_reference,
    NULL AS cdm_etl_reference,
    sv.SOURCE_RELEASE_DATE AS source_release_date,
    CURRENT_DATE AS cdm_release_date,
    'v5.4' AS cdm_version,
    756265 AS cdm_version_concept_id,
    v.vocabulary_version
FROM {{ cdm_db }}.{{ vocabulary }}.vocabulary v
CROSS JOIN SOURCE_VERSION sv
WHERE v.vocabulary_id = 'None';
