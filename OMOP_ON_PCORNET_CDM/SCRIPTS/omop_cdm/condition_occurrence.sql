create or replace view {{ cdm_db }}.{{ cdm_schema }}.condition_occurrence as
SELECT
    {% if site in ['mu', 'mu-id'] %}
        diagnosis.diagnosisid::INTEGER AS condition_occurrence_id,
        diagnosis.patid::INTEGER AS person_id,
        diagnosis.providerid::INTEGER AS provider_id,
        diagnosis.encounterid::INTEGER AS visit_occurrence_id,
    {% elif site == 'gpc' %}
        ROW_NUMBER() OVER (ORDER BY diagnosis.diagnosisid)::INTEGER AS condition_occurrence_id,
        diagnosis.person_num::INTEGER AS person_id,
        -1::INTEGER AS provider_id,
        diagnosis.encounter_num::INTEGER AS visit_occurrence_id,
    {% else %}
        diagnosis.diagnosisid::INTEGER AS condition_occurrence_id,
        diagnosis.patid::INTEGER AS person_id,
        diagnosis.providerid::INTEGER AS provider_id,
        diagnosis.encounterid::INTEGER AS visit_occurrence_id,
    {% endif %}
    COALESCE(target_concept.concept_id, 44814650)::INTEGER AS condition_concept_id,
    COALESCE(diagnosis.dx_date, diagnosis.admit_date)::DATE AS condition_start_date,
    COALESCE(diagnosis.dx_date, diagnosis.admit_date)::timestamp AS condition_start_datetime,
    NULL::DATE AS condition_end_date,
    NULL::timestamp AS condition_end_datetime,
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
    NULL::varchar(20) AS stop_reason,
    'dx_icd_type:' || diagnosis.dx_type::varchar(50) || '|' || dx || ':' || diagnosis.dx::varchar(50) AS condition_source_value,
    COALESCE(source_concept.concept_id, 44814650)::INTEGER AS condition_source_concept_id,
    diagnosis.dx_source::varchar(50) AS condition_status_source_value
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ diagnosis_table }} diagnosis
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept source_concept 
    ON diagnosis.dx = source_concept.concept_code
    AND (
        (diagnosis.dx_type = '09' AND source_concept.vocabulary_id = 'ICD9CM') OR
        (diagnosis.dx_type = '10' AND source_concept.vocabulary_id = 'ICD10CM')
    )
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept_relationship cr
    ON source_concept.concept_id = cr.concept_id_1
    AND cr.relationship_id = 'Maps to'
    AND (cr.invalid_reason IS NULL OR cr.invalid_reason = '')
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept target_concept
    ON cr.concept_id_2 = target_concept.concept_id
    AND target_concept.standard_concept = 'S'
    AND (target_concept.invalid_reason IS NULL OR target_concept.invalid_reason = '');
