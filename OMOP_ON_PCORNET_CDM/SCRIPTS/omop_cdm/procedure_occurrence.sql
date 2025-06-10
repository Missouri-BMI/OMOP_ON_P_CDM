CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.procedure_occurrence AS
SELECT
    {% if site in ['mu', 'mu-id'] %}
        ROW_NUMBER() OVER (ORDER BY procedures.patid)::INTEGER AS procedure_occurrence_id,
        procedures.patid::INTEGER AS person_id,
        procedures.providerid::INTEGER AS provider_id,
        procedures.encounterid::INTEGER AS visit_occurrence_id,
    {% elif site == 'gpc' %}
        ROW_NUMBER() OVER (ORDER BY procedures.person_num)::INTEGER AS procedure_occurrence_id,
        procedures.person_num::INTEGER AS person_id,
        -1::INTEGER AS provider_id,
        procedures.encounter_num::INTEGER AS visit_occurrence_id,
    {% else %}
        ROW_NUMBER() OVER (ORDER BY procedures.patid)::INTEGER AS procedure_occurrence_id,
        procedures.patid::INTEGER AS person_id,
        procedures.providerid::INTEGER AS provider_id,
        procedures.encounterid::INTEGER AS visit_occurrence_id,
    {% endif %}
    COALESCE(srctostdvm.target_concept_id, srctosrcvm.target_concept_id) AS procedure_concept_id, --standard mapping else source mapping to vocabulary
    COALESCE(procedures.px_date, procedures.admit_date)::DATE AS procedure_date,
    procedures.admit_date::TIMESTAMP      AS    procedure_datetime,
    NULL::DATE                            AS    procedure_end_date,
    NULL::TIMESTAMP                       AS    procedure_end_datetime,
    CASE
        WHEN procedures.px_source = 'OD' THEN 38000275
        WHEN procedures.px_source = 'BI' THEN 44786631
        ELSE 32827
    END::INTEGER                          AS    procedure_type_concept_id,
    0::INTEGER                            AS    modifier_concept_id,
    NULL::INTEGER                         AS    quantity,
    NULL::INTEGER                         AS    visit_detail_id,
    procedures.px::VARCHAR(50)            AS    procedure_source_value,
    srctosrcvm.source_concept_id          AS    procedure_source_concept_id,
    NULL::VARCHAR(50)                     AS    modifier_source_value

FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ procedure_table }} procedures
JOIN source_to_source_vocab_map srctosrcvm -- inner join source to source map
    ON srctosrcvm.source_code = procedures.px
    AND srctosrcvm.source_vocabulary_id = 
        CASE 
        WHEN procedures.px_type = '09' THEN 'ICD9Proc'
        WHEN procedures.px_type = '10' THEN 'ICD10PCS'
        WHEN procedures.px_type = 'CH' THEN 
            CASE 
                WHEN procedures.raw_px_type = 'CPT4' THEN 'CPT4'
                ELSE 'HCPCS'
            END
        END
    AND srctosrcvm.source_domain_id = 'Procedure'
LEFT JOIN source_to_standard_vocab_map srctostdvm ---- left join source to source map
ON srctostdvm.source_code = srctosrcvm.source_code
AND srctostdvm.target_domain_id = srctosrcvm.source_domain_id 
AND srctostdvm.source_vocabulary_id = srctosrcvm.source_vocabulary_id
AND srctostdvm.target_standard_concept = 'S'
AND srctostdvm.target_invalid_reason IS NULL;