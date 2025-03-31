Create or replace view {cdm_db}.{cdm_schema}.condition_era
AS
SELECT
   NULL::INTEGER AS condition_era_id,
   NULL::INTEGER AS person_id,
   NULL::INTEGER AS condition_concept_id,
   NULL::DATE AS condition_era_start_date,
   NULL::DATE AS condition_era_end_date,
   NULL::INTEGER AS condition_occurrence_count
FROM {pcornet_db}.{pcornet_schema}.CONDITION
;
