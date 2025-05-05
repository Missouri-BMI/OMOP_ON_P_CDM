CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.procedure_occurrence AS
SELECT
    {% if site in ['mu', 'mu-id'] %}
        procedures.proceduresid::INTEGER AS procedure_occurrence_id,
        procedures.patid::INTEGER AS person_id,
        procedures.providerid::INTEGER AS provider_id,
        procedures.encounterid::INTEGER AS visit_occurrence_id,
    {% elif site == 'gpc' %}
        ROW_NUMBER() OVER (ORDER BY procedures.proceduresid)::INTEGER AS procedure_occurrence_id,
        procedures.person_num::INTEGER AS person_id,
        -1::INTEGER AS provider_id,
        procedures.encounter_num::INTEGER AS visit_occurrence_id,
    {% else %}
        procedures.proceduresid::INTEGER AS procedure_occurrence_id,
        procedures.patid::INTEGER AS person_id,
        procedures.providerid::INTEGER AS provider_id,
        procedures.encounterid::INTEGER AS visit_occurrence_id,
    {% endif %}

    -- Procedure concept resolution
    CASE
        WHEN c_hcpcs.concept_id IS NOT NULL THEN c_hcpcs.concept_id
        WHEN procedures.px_type = 'CH' THEN c_cpt.concept_id
        WHEN procedures.px_type = '10' THEN c_icd10.concept_id
        WHEN procedures.px_type = '09' THEN c_icd9.concept_id
        ELSE 0
    END::INTEGER AS procedure_concept_id,

    COALESCE(procedures.px_date, procedures.admit_date)::DATE AS procedure_date,
    procedures.admit_date::TIMESTAMP AS procedure_datetime,
    NULL::DATE AS procedure_end_date,
    NULL::TIMESTAMP AS procedure_end_datetime,

    CASE
        WHEN procedures.px_source = 'OD' THEN 38000275
        WHEN procedures.px_source = 'BI' THEN 44786631
        ELSE 44814650
    END::INTEGER AS procedure_type_concept_id,

    0::INTEGER AS modifier_concept_id,
    NULL::INTEGER AS quantity,

    NULL::INTEGER AS visit_detail_id,
    procedures.px::VARCHAR(50) AS procedure_source_value,

    -- Procedure source concept resolution (same as procedure_concept_id logic)
    CASE
        WHEN c_hcpcs.concept_id IS NOT NULL THEN c_hcpcs.concept_id
        WHEN procedures.px_type = 'CH' THEN c_cpt.concept_id
        WHEN procedures.px_type = '10' THEN c_icd10.concept_id
        WHEN procedures.px_type = '09' THEN c_icd9.concept_id
        ELSE 0
    END::INTEGER AS procedure_source_concept_id,

    NULL::VARCHAR(50) AS modifier_source_value

FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ procedure_table }} procedures
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept c_hcpcs
    ON procedures.px = c_hcpcs.concept_code
    AND procedures.px_type = 'CH'
    AND c_hcpcs.vocabulary_id = 'HCPCS'
    AND procedures.px RLIKE '[A-Z]'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept c_cpt
    ON procedures.px = c_cpt.concept_code
    AND procedures.px_type = 'CH'
    AND c_cpt.vocabulary_id = 'CPT4'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept c_icd10
    ON procedures.px = c_icd10.concept_code
    AND procedures.px_type = '10'
    AND c_icd10.vocabulary_id = 'ICD10CM'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept c_icd9
    ON procedures.px = c_icd9.concept_code
    AND procedures.px_type = '09'
    AND c_icd9.vocabulary_id = 'ICD9CM';
