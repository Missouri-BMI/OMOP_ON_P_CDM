create or replace table {cdm_db}.{cdm_schema}.OBSERVATION_PERIOD(
	OBSERVATION_PERIOD_ID,
	PERSON_ID,
	OBSERVATION_PERIOD_START_DATE,
	OBSERVATION_PERIOD_END_DATE,
	PERIOD_TYPE_CONCEPT_ID
) as
(
SELECT
	ROW_NUMBER() OVER (ORDER BY enrl.patient_num) ::INTEGER AS observation_period_id,
	patient_num::INTEGER AS person_id,
	ENR_START_DATE::date AS observation_period_start_date,
	ENR_END_DATE::date AS observation_period_end_date,
	44814722::INTEGER AS period_type_concept_id
FROM {pcornet_db}.{pcornet_schema}.GPC_DEID_enrollment enrl
);