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

CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.condition_occurrence (
    condition_occurrence_id integer IDENTITY(1,1) NOT NULL,
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
);

INSERT INTO {{ cdm_db }}.{{ cdm_schema }}.condition_occurrence (
    person_id,
    condition_concept_id,
    condition_start_date,
    condition_start_datetime,
    condition_end_date,
    condition_end_datetime,
    condition_type_concept_id,
    condition_status_concept_id,
    stop_reason,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    condition_source_value,
    condition_source_concept_id,
    condition_status_source_value
)
SELECT
    {{ dx_person_id_expr }}                                           AS person_id,
    COALESCE(srctostdvm.target_concept_id, 0)::INTEGER                AS condition_concept_id,
    COALESCE(diagnosis.dx_date, diagnosis.admit_date)::DATE           AS condition_start_date,
    COALESCE(diagnosis.dx_date, diagnosis.admit_date)::TIMESTAMP      AS condition_start_datetime,
    NULL::DATE                                                        AS condition_end_date,
    NULL::TIMESTAMP                                                   AS condition_end_datetime,
    CASE
        WHEN diagnosis.dx_origin = 'OD' THEN 32817
        WHEN diagnosis.dx_origin = 'BI' THEN 32821
        WHEN diagnosis.dx_origin = 'CL' THEN 32810
        WHEN diagnosis.dx_origin = 'DR' THEN 45754907
        ELSE 44814653
    END::INTEGER                                                      AS condition_type_concept_id,
    CASE
        WHEN diagnosis.dx_source = 'AD' THEN 32890
        WHEN diagnosis.dx_source = 'DI' THEN 32896
        ELSE 44814653
    END::INTEGER                                                      AS condition_status_concept_id,
    NULL::VARCHAR(20)                                                 AS stop_reason,
    pm.provider_id                                                    AS provider_id,
    {{ dx_visit_occurrence_id_expr }}                                 AS visit_occurrence_id,
    {{ dx_visit_occurrence_id_expr }}                                 AS visit_detail_id,
    LEFT(diagnosis.dx, 50)::VARCHAR(50)                               AS condition_source_value,
    srctosrcvm.source_concept_id::INTEGER                             AS condition_source_concept_id,
    LEFT(COALESCE(diagnosis.dx_source::VARCHAR, ''), 50)::VARCHAR(50) AS condition_status_source_value
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ diagnosis_table }} diagnosis
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.provider_id_map pm
  ON pm.providerid_source = diagnosis.providerid
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
 AND srctostdvm.target_domain_id = 'Condition'
 AND srctostdvm.source_vocabulary_id = srctosrcvm.source_vocabulary_id
 AND srctostdvm.target_standard_concept = 'S'
WHERE COALESCE(diagnosis.dx_date, diagnosis.admit_date) IS NOT NULL

UNION ALL

SELECT
    {{ cond_person_id_expr }}                                         AS person_id,
    COALESCE(srctostdvm.target_concept_id, 0)::INTEGER                AS condition_concept_id,
    condition.report_date::DATE                                       AS condition_start_date,
    condition.report_date::TIMESTAMP                                  AS condition_start_datetime,
    condition.resolve_date::DATE                                      AS condition_end_date,
    condition.resolve_date::TIMESTAMP                                 AS condition_end_datetime,
    32827::INTEGER                                                    AS condition_type_concept_id,
    0::INTEGER                                                        AS condition_status_concept_id,
    NULL::VARCHAR(20)                                                 AS stop_reason,
    NULL::INTEGER                                                     AS provider_id,
    {{ cond_visit_occurrence_id_expr }}                               AS visit_occurrence_id,
    {{ cond_visit_occurrence_id_expr }}                               AS visit_detail_id,
    LEFT(condition.condition, 50)::VARCHAR(50)                        AS condition_source_value,
    srctosrcvm.source_concept_id::INTEGER                             AS condition_source_concept_id,
    LEFT(COALESCE(condition.condition_status::VARCHAR, ''), 50)::VARCHAR(50) AS condition_status_source_value
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
 AND srctostdvm.target_domain_id = 'Condition'
 AND srctostdvm.source_vocabulary_id = srctosrcvm.source_vocabulary_id
 AND srctostdvm.target_standard_concept = 'S'
WHERE condition.report_date IS NOT NULL;