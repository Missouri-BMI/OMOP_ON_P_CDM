{% if site in ['mu', 'mu-id'] %}
  {% set dx_person_id_expr = "diagnosis.patid::INTEGER" %}
  {% set dx_visit_occurrence_id_expr = "diagnosis.encounterid::INTEGER" %}
  {% set cond_person_id_expr = "condition.patid::INTEGER" %}
  {% set cond_visit_occurrence_id_expr = "condition.encounterid::INTEGER" %}
{% elif site == 'gpc' %}
  {% set dx_person_id_expr = "diagnosis.patient_num::INTEGER" %}
  {% set dx_visit_occurrence_id_expr = "diagnosis.encounter_num::INTEGER" %}
  {% set cond_person_id_expr = "condition.patient_num::INTEGER" %}
  {% set cond_visit_occurrence_id_expr = "condition.encounter_num::INTEGER" %}
{% else %}
  {% set dx_person_id_expr = "diagnosis.patid::INTEGER" %}
  {% set dx_visit_occurrence_id_expr = "diagnosis.encounterid::INTEGER" %}
  {% set cond_person_id_expr = "condition.patid::INTEGER" %}
  {% set cond_visit_occurrence_id_expr = "condition.encounterid::INTEGER" %}
{% endif %}

CREATE OR REPLACE TABLE {{ cdm_db }}.{{ cdm_schema }}.condition_occurrence_map AS
WITH keys AS (

  -- DIAGNOSIS keys
  SELECT DISTINCT
    'DIAGNOSIS'::VARCHAR                                            AS src,
    {{ dx_person_id_expr }}                                         AS person_id,
    diagnosis.dx::VARCHAR                                           AS condition_source_value,
    COALESCE(diagnosis.dx_date, diagnosis.admit_date)::DATE         AS start_date,
    {{ dx_visit_occurrence_id_expr }}                               AS visit_occurrence_id

  FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ diagnosis_table }} diagnosis
  WHERE diagnosis.dx IS NOT NULL

  UNION ALL

  -- CONDITION keys
  SELECT DISTINCT
    'CONDITION'::VARCHAR                                            AS src,
    {{ cond_person_id_expr }}                                       AS person_id,
    condition.condition::VARCHAR                                    AS condition_source_value,
    condition.report_date::DATE                                     AS start_date,
    {{ cond_visit_occurrence_id_expr }}                             AS visit_occurrence_id

  FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ condition_table }} condition
  WHERE condition.condition IS NOT NULL
)
SELECT
  src,
  person_id,
  condition_source_value,
  start_date,
  visit_occurrence_id,
  ROW_NUMBER() OVER (
    ORDER BY src, person_id, start_date, visit_occurrence_id, condition_source_value
  )::INTEGER                                                        AS condition_occurrence_id
FROM keys;

CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.condition_occurrence (
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

-- ---------------- DIAGNOSIS rows ----------------
SELECT
  m.condition_occurrence_id::INTEGER                                AS condition_occurrence_id,
  m.person_id::INTEGER                                              AS person_id,
  COALESCE(srctostdvm.target_concept_id, srctosrcvm.target_concept_id)::INTEGER
                                                                    AS condition_concept_id,
  m.start_date::DATE                                                AS condition_start_date,
  m.start_date::TIMESTAMP                                           AS condition_start_datetime,
  NULL::DATE                                                        AS condition_end_date,
  NULL::TIMESTAMP                                                   AS condition_end_datetime,

  CASE
    WHEN diagnosis.dx_origin = 'OD' THEN 32817
    WHEN diagnosis.dx_origin = 'BI' THEN 32821
    WHEN diagnosis.dx_origin = 'CL' THEN 32810
    WHEN diagnosis.dx_origin = 'DR' THEN 45754907
    WHEN diagnosis.dx_origin = 'NI' THEN 44814650
    WHEN diagnosis.dx_origin = 'UN' THEN 44814653
    WHEN diagnosis.dx_origin = 'OT' THEN 44814649
    WHEN diagnosis.dx_origin = ''   THEN 44814653
    WHEN diagnosis.dx_origin IS NULL THEN 44814653
  END::INTEGER                                                      AS condition_type_concept_id,

  CASE
    WHEN diagnosis.dx_source = 'AD' THEN 32890
    WHEN diagnosis.dx_source = 'DI' THEN 32896
    WHEN diagnosis.dx_source = 'FI' THEN 40492206
    WHEN diagnosis.dx_source = 'IN' THEN 40492208
    WHEN diagnosis.dx_source = 'NI' THEN 44814650
    WHEN diagnosis.dx_source = 'UN' THEN 44814653
    WHEN diagnosis.dx_source = 'OT' THEN 44814649
    WHEN diagnosis.dx_source = ''   THEN 44814653
    WHEN diagnosis.dx_source IS NULL THEN 44814653
  END::INTEGER                                                      AS condition_status_concept_id,

  NULL::VARCHAR(20)                                                 AS stop_reason,
  {% if site == 'gpc' %}-1{% else %}diagnosis.providerid{% endif %}::INTEGER
                                                                    AS provider_id,
  m.visit_occurrence_id::INTEGER                                    AS visit_occurrence_id,
  NULL::INTEGER                                                     AS visit_detail_id,
  LEFT(COALESCE(m.condition_source_value, ''), 50)::VARCHAR(50)     AS condition_source_value,
  srctosrcvm.source_concept_id::INTEGER                             AS condition_source_concept_id,
  LEFT(COALESCE(diagnosis.dx_source::VARCHAR, ''), 50)::VARCHAR(50) AS condition_status_source_value

FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ diagnosis_table }} diagnosis
JOIN {{ cdm_db }}.{{ cdm_schema }}.condition_occurrence_map m
  ON m.src = 'DIAGNOSIS'
 AND m.person_id = {{ dx_person_id_expr }}
 AND m.condition_source_value = diagnosis.dx
 AND m.start_date = COALESCE(diagnosis.dx_date, diagnosis.admit_date)::DATE
 AND m.visit_occurrence_id = {{ dx_visit_occurrence_id_expr }}

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

-- ---------------- CONDITION rows ----------------
SELECT
  m.condition_occurrence_id::INTEGER                                AS condition_occurrence_id,
  m.person_id::INTEGER                                              AS person_id,
  COALESCE(srctostdvm.target_concept_id, srctosrcvm.target_concept_id)::INTEGER
                                                                    AS condition_concept_id,
  m.start_date::DATE                                                AS condition_start_date,
  m.start_date::TIMESTAMP                                           AS condition_start_datetime,
  condition.resolve_date::DATE                                      AS condition_end_date,
  condition.resolve_date::TIMESTAMP                                 AS condition_end_datetime,
  32827::INTEGER                                                    AS condition_type_concept_id,
  0::INTEGER                                                        AS condition_status_concept_id,
  NULL::VARCHAR(20)                                                 AS stop_reason,
  0::INTEGER                                                        AS provider_id,
  m.visit_occurrence_id::INTEGER                                    AS visit_occurrence_id,
  NULL::INTEGER                                                     AS visit_detail_id,
  LEFT(COALESCE(m.condition_source_value, ''), 50)::VARCHAR(50)     AS condition_source_value,
  srctosrcvm.source_concept_id::INTEGER                             AS condition_source_concept_id,
  LEFT(COALESCE(condition.condition_status::VARCHAR, ''), 50)::VARCHAR(50)
                                                                    AS condition_status_source_value
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ condition_table }} condition
JOIN {{ cdm_db }}.{{ cdm_schema }}.condition_occurrence_map m
  ON m.src = 'CONDITION'
 AND m.person_id = {{ cond_person_id_expr }}
 AND m.condition_source_value = condition.condition
 AND m.start_date = condition.report_date::DATE
 AND m.visit_occurrence_id = {{ cond_visit_occurrence_id_expr }}

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
;
