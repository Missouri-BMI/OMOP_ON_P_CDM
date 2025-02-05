create or replace table {cdm_db}.{cdm_schema}.provider
AS
SELECT
  NULL::INTEGER AS provider_id,
  NULL::VARCHAR(255) AS provider_name,
  NULL::VARCHAR(20) AS npi,
  NULL::VARCHAR(20) AS dea,
  NULL::INTEGER AS specialty_concept_id,
  NULL::INTEGER AS care_site_id,
  NULL::INTEGER AS year_of_birth,
  NULL::INTEGER AS gender_concept_id,
  NULL::VARCHAR(50) AS provider_source_value,
  NULL::VARCHAR(50) AS specialty_source_value,
  NULL::INTEGER AS specialty_source_concept_id,
  NULL::VARCHAR(50) AS gender_source_value,
  NULL::INTEGER AS gender_source_concept_id
FROM {pcornet_db}.{pcornet_schema}.GPC_DEID_provider
;
