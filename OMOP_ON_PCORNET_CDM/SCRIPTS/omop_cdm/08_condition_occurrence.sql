CREATE TABLE  {{ cdm_db }}.{{ cdm_schema }}.condition_occurrence (
    condition_occurrence_id integer NOT NULL,
     person_id integer NOT NULL,
     condition_concept_id integer NOT NULL,
     condition_start_date date NOT NULL,
     condition_start_datetime TIMESTAMP NULL,
     condition_end_date date NULL,
     condition_end_datetime TIMESTAMP NULL,
     condition_type_concept_id integer NOT NULL,
     condition_status_concept_id integer NULL,
     stop_reason varchar(20) NULL,
     provider_id integer NULL,
     visit_occurrence_id integer NULL,
     visit_detail_id integer NULL,
     condition_source_value varchar(50) NULL,
     condition_source_concept_id integer NULL,
     condition_status_source_value varchar(50) NULL
) AS
SELECT
     -- DDL order:
     -- condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_start_datetime,
     -- condition_end_date, condition_end_datetime, condition_type_concept_id, condition_status_concept_id,
     -- stop_reason, provider_id, visit_occurrence_id, visit_detail_id, condition_source_value,
     -- condition_source_concept_id, condition_status_source_value
     {% if site in ['mu', 'mu-id'] %}
          ROW_NUMBER() OVER (ORDER BY diagnosis.patid)::INTEGER AS condition_occurrence_id,
          diagnosis.patid::INTEGER AS person_id,
     {% elif site == 'gpc' %}
          ROW_NUMBER() OVER (ORDER BY diagnosis.patient_num)::INTEGER AS condition_occurrence_id,
          diagnosis.patient_num::INTEGER AS person_id,
     {% else %}
          ROW_NUMBER() OVER (ORDER BY diagnosis.patid)::INTEGER AS condition_occurrence_id,
          diagnosis.patid::INTEGER AS person_id,
     {% endif %}
     COALESCE(srctostdvm.target_concept_id, srctosrcvm.target_concept_id) AS condition_concept_id,
     COALESCE(diagnosis.dx_date, diagnosis.admit_date)::DATE AS condition_start_date,
     COALESCE(diagnosis.dx_date, diagnosis.admit_date)::TIMESTAMP AS condition_start_datetime,
     NULL::DATE AS condition_end_date,
     NULL::TIMESTAMP AS condition_end_datetime,
     CASE
          WHEN dx_origin = 'OD' THEN 32817
          WHEN dx_origin = 'BI' THEN 32821
          WHEN dx_origin = 'CL' THEN 32810
          WHEN dx_origin = 'DR' THEN 45754907
          WHEN dx_origin = 'NI' THEN 44814650
          WHEN dx_origin = 'UN' THEN 44814653
          WHEN dx_origin = 'OT' THEN 44814649
          WHEN dx_origin = '' THEN 44814653
          WHEN dx_origin IS NULL THEN 44814653
     END::INTEGER AS condition_type_concept_id,
     CASE
          WHEN dx_source = 'AD' THEN 32890
          WHEN dx_source = 'DI' THEN 32896
          WHEN dx_source = 'FI' THEN 40492206
          WHEN dx_source = 'IN' THEN 40492208
          WHEN dx_source = 'NI' THEN 44814650
          WHEN dx_source = 'UN' THEN 44814653
          WHEN dx_source = 'OT' THEN 44814649
          WHEN dx_source = '' THEN 44814653
          WHEN dx_source IS NULL THEN 44814653
     END::INTEGER AS condition_status_concept_id,
     NULL::VARCHAR(20) AS stop_reason,
     {% if site in ['mu', 'mu-id'] %}
          diagnosis.providerid::INTEGER AS provider_id,
          diagnosis.encounterid::INTEGER AS visit_occurrence_id,
     {% elif site == 'gpc' %}
          -1::INTEGER AS provider_id,
          diagnosis.encounter_num::INTEGER AS visit_occurrence_id,
     {% else %}
          diagnosis.providerid::INTEGER AS provider_id,
          diagnosis.encounterid::INTEGER AS visit_occurrence_id,
     {% endif %}
     NULL::INTEGER AS visit_detail_id,
     diagnosis.dx::VARCHAR AS condition_source_value,
     srctosrcvm.source_concept_id AS condition_source_concept_id,
     diagnosis.dx_source::VARCHAR(50) AS condition_status_source_value
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ diagnosis_table }} diagnosis
JOIN {{ cdm_db }}.{{ vocabulary }}.source_to_source_vocab_map srctosrcvm
     ON srctosrcvm.source_code = diagnosis.dx
     AND srctosrcvm.source_vocabulary_id = 
          CASE 
                WHEN diagnosis.dx_type = '09' THEN 'ICD9CM'
                WHEN diagnosis.dx_type = '10' THEN 'ICD10CM'
                WHEN diagnosis.dx_type = 'SM' THEN 'SNOMED'
          END
     AND srctosrcvm.source_domain_id = 'Condition'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.source_to_standard_vocab_map srctostdvm
     ON srctostdvm.source_code = srctosrcvm.source_code
     AND srctostdvm.target_domain_id = srctosrcvm.source_domain_id 
     AND srctostdvm.source_vocabulary_id = srctosrcvm.source_vocabulary_id
     AND srctostdvm.target_standard_concept = 'S'
     AND srctostdvm.target_invalid_reason IS NULL

UNION ALL

SELECT
     {% if site in ['mu', 'mu-id'] %}
          ROW_NUMBER() OVER (ORDER BY condition.patid)::INTEGER AS condition_occurrence_id,
          condition.patid::INTEGER AS person_id,
     {% elif site == 'gpc' %}
          ROW_NUMBER() OVER (ORDER BY condition.patient_num)::INTEGER AS condition_occurrence_id,
          condition.patient_num::INTEGER AS person_id,
     {% else %}
          ROW_NUMBER() OVER (ORDER BY condition.patid)::INTEGER AS condition_occurrence_id,
          condition.patid::INTEGER AS person_id,
     {% endif %}
     COALESCE(srctostdvm.target_concept_id, srctosrcvm.target_concept_id) AS condition_concept_id,
     condition.report_date::DATE AS condition_start_date,
     condition.report_date::TIMESTAMP AS condition_start_datetime,
     condition.resolve_date::DATE AS condition_end_date,
     condition.resolve_date::TIMESTAMP AS condition_end_datetime,
     32827 AS condition_type_concept_id,
     0 AS condition_status_concept_id,
     NULL::VARCHAR(20) AS stop_reason,
     0 AS provider_id,
     {% if site == 'gpc' %}
          condition.encounter_num::INTEGER AS visit_occurrence_id,
     {% else %}
          condition.encounterid::INTEGER AS visit_occurrence_id,
     {% endif %}
     NULL::INTEGER AS visit_detail_id,
     condition.condition::VARCHAR AS condition_source_value,
     srctosrcvm.source_concept_id AS condition_source_concept_id,
     condition.condition_status::VARCHAR(50) AS condition_status_source_value
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ condition_table }} condition
JOIN {{ cdm_db }}.{{ vocabulary }}.source_to_source_vocab_map srctosrcvm
     ON srctosrcvm.source_code = condition.condition
     AND srctosrcvm.source_vocabulary_id = 
          CASE 
                WHEN condition.condition_type = '09' THEN 'ICD9CM'
                WHEN condition.condition_type = '10' THEN 'ICD10CM'
                WHEN condition.condition_type = 'SM' THEN 'SNOMED'
          END
     AND srctosrcvm.source_domain_id = 'Condition'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.source_to_standard_vocab_map srctostdvm
     ON srctostdvm.source_code = srctosrcvm.source_code
     AND srctostdvm.target_domain_id = srctosrcvm.source_domain_id 
     AND srctostdvm.source_vocabulary_id = srctosrcvm.source_vocabulary_id
     AND srctostdvm.target_standard_concept = 'S'
     AND srctostdvm.target_invalid_reason IS NULL
WHERE condition.report_date IS NOT NULL;
