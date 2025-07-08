CREATE TABLE  {{ cdm_db }}.{{ cdm_schema }}.provider (
    provider_id integer NOT NULL,
    provider_name varchar(255) NULL,
    npi varchar(20) NULL,
    dea varchar(20) NULL,
    specialty_concept_id integer NULL,
    care_site_id integer NULL,
    year_of_birth integer NULL,
    gender_concept_id integer NULL,
    provider_source_value varchar(50) NULL,
    specialty_source_value varchar(50) NULL,
    specialty_source_concept_id integer NULL,
    gender_source_value varchar(50) NULL,
    gender_source_concept_id integer NULL
) AS
SELECT
    NULL AS provider_id,
    NULL AS provider_name,
    NULL AS npi,
    NULL AS dea,
    NULL AS specialty_concept_id,
    NULL AS care_site_id,
    NULL AS year_of_birth,
    NULL AS gender_concept_id,
    NULL AS provider_source_value,
    NULL AS specialty_source_value,
    NULL AS specialty_source_concept_id,
    NULL AS gender_source_value,
    NULL AS gender_source_concept_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ provider_table }}
WHERE 1=0;  -- Create an empty table with the same structure;
