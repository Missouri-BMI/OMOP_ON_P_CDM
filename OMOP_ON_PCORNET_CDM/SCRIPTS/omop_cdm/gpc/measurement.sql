create or replace table {cdm_db}.{cdm_schema}.measurement
AS
SELECT
   lab.lab_result_cm_id::INTEGER AS measurement_id,

   lab.patient_num::INTEGER AS person_id,

   NULL::INTEGER AS measurement_concept_id,

   NULL::DATE AS measurement_date,

   NULL::TIMESTAMP AS measurement_datetime,

   NULL::VARCHAR(10) AS measurement_time,

   NULL::INTEGER AS measurement_type_concept_id,

   NULL::INTEGER AS operator_concept_id,

   NULL::NUMERIC AS value_as_number,

   NULL::INTEGER AS value_as_concept_id,

   NULL::INTEGER AS unit_concept_id,

   NULL::NUMERIC AS range_low,

   NULL::NUMERIC AS range_high,

   NULL::INTEGER AS provider_id,

   lab.encounter_num::INTEGER AS visit_occurrence_id,

   NULL::INTEGER AS visit_detail_id,

   NULL::VARCHAR(50) AS measurement_source_value,

   NULL::INTEGER AS measurement_source_concept_id,

   NULL::VARCHAR(50) AS unit_source_value,

   NULL::INTEGER AS unit_source_concept_id,

   NULL::VARCHAR(50) AS value_source_value,

   NULL::INTEGER AS measurement_event_id,

   NULL::INTEGER AS meas_event_field_concept_id

FROM {pcornet_db}.{pcornet_schema}.GPC_DEID_lab_result_cm lab
;