create or replace view {cdm_db}.{cdm_schema}.condition_occurrence as
SELECT
    diagnosis.diagnosisid::INTEGER AS condition_occurrence_id,
    diagnosis.patid::INTEGER AS person_id,
    COALESCE(target_concept.concept_id, 44814650)::INTEGER AS condition_concept_id,
    coalesce(diagnosis.dx_date,diagnosis.admit_date)::DATE AS condition_start_date,
    coalesce(diagnosis.dx_date,diagnosis.admit_date)::timestamp AS condition_start_datetime,
    NULL::DATE AS condition_end_date,
    NULL::timestamp AS condition_end_datetime,
    case
            when dx_origin = 'OD' then 32817::int
            when dx_origin = 'BI' then 32821
            when dx_origin = 'CL' then 32810
            when dx_origin = 'DR' then 45754907
            when dx_origin = 'NI' then 44814650
            when dx_origin = 'UN' then 44814653
            when dx_origin = 'OT' then 44814649
            when dx_origin = '' then 44814653
            when dx_origin is null then 44814653
        end::INTEGER  as condition_type_concept_id,
    case
            when dx_source = 'AD' then 32890::int
            when dx_source = 'DI' then 32896
            when dx_source = 'FI' then 40492206
            when dx_source = 'IN' then 40492208
            when dx_source = 'NI' then 44814650
            when dx_source = 'UN' then 44814653
            when dx_source = 'OT' then 44814649
            when dx_source = '' then 44814653
            when dx_source is null then 44814653
        end::INTEGER AS condition_status_concept_id,   
    NULL::varchar(20) AS stop_reason,
    diagnosis.providerid::INTEGER AS provider_id,
    diagnosis.encounterid::INTEGER AS visit_occurrence_id,
    NULL::INTEGER AS visit_detail_id,
    'dx_icd_type:' || diagnosis.dx_type::varchar(50) || '|' || dx || ':' || diagnosis.dx::varchar(50) AS condition_source_value,
   COALESCE(source_concept.concept_id, 44814650)::INTEGER AS condition_source_concept_id,
    diagnosis.dx_source::varchar(50) AS condition_status_source_value

FROM {pcornet_db}.{pcornet_schema}.diagnosis diagnosis
LEFT JOIN {cdm_db}.{cdm_schema}.concept source_concept 
    ON diagnosis.dx = source_concept.concept_code
    AND (
        (diagnosis.dx_type = '09' AND source_concept.vocabulary_id = 'ICD9CM') OR
        (diagnosis.dx_type = '10' AND source_concept.vocabulary_id = 'ICD10CM') 
    )
LEFT JOIN {cdm_db}.{cdm_schema}.concept_relationship cr
    ON source_concept.concept_id = cr.concept_id_1
    AND cr.relationship_id = 'Maps to'
    AND (cr.invalid_reason IS NULL or cr.invalid_reason = '')
LEFT JOIN {cdm_db}.{cdm_schema}.concept target_concept
    ON cr.concept_id_2 = target_concept.concept_id
    AND target_concept.standard_concept = 'S'
    AND (target_concept.invalid_reason IS NULL or target_concept.invalid_reason = '');
;
