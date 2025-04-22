CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.death AS (
WITH RankedDeath AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                {% if site in ['mu', 'mu-id'] %}
                    patid
                {% elif site == 'gpc' %}
                    patient_num
                {% else %}
                    patid
                {% endif %}
            ORDER BY 
                CASE death_source
                    WHEN 'D' THEN 1
                    WHEN 'N' THEN 2
                    WHEN 'L' THEN 3
                    WHEN 'S' THEN 4
                    WHEN 'T' THEN 5
                    WHEN 'DR' THEN 6
                    WHEN 'NI' THEN 7
                    WHEN 'UN' THEN 8
                    WHEN 'OT' THEN 9
                    ELSE 8
                END
        ) AS row_num
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ death_table }}
),
RankedDeathCause AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                {% if site in ['mu', 'mu-id'] %}
                    patid
                {% elif site == 'gpc' %}
                    patient_num
                {% else %}
                    patid
                {% endif %}
            ORDER BY 
                CASE death_cause_code
                    WHEN '10' THEN 1
                    WHEN '09' THEN 2
                    WHEN 'SM' THEN 3
                    ELSE 4
                END
        ) AS row_num
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ death_cause_table }}
)
SELECT DISTINCT
    {% if site in ['mu', 'mu-id'] %}
        d.patid::INTEGER AS person_id,
    {% elif site == 'gpc' %}
        d.patient_num::INTEGER AS person_id,
    {% else %}
        d.patid::INTEGER AS person_id,
    {% endif %}
    d.death_date::DATE AS death_date,
    d.death_date::DATETIME AS death_datetime,
    COALESCE(dt.source_concept_id, 0)::INTEGER AS death_type_concept_id,
    COALESCE(
        CASE
            WHEN dc.death_cause_code = '09' THEN c_icd9.concept_id
            WHEN dc.death_cause_code = '10' THEN c_icd10.concept_id
            WHEN dc.death_cause_code = 'SM' THEN c_snomed.concept_id
            WHEN dc.death_cause IS NOT NULL 
                 AND c_icd9.concept_id IS NULL
                 AND c_icd10.concept_id IS NULL
                 AND c_snomed.concept_id IS NULL THEN 0 
        END,
        44814650
    )::INTEGER AS cause_concept_id,
    dc.death_cause::VARCHAR(50) AS cause_source_value,
    COALESCE(
        CASE
            WHEN dc.death_cause_code = '09' THEN c_icd9.concept_id
            WHEN dc.death_cause_code = '10' THEN c_icd10.concept_id
            WHEN dc.death_cause_code = 'SM' THEN c_snomed.concept_id
            WHEN dc.death_cause IS NOT NULL 
                 AND c_icd9.concept_id IS NULL
                 AND c_icd10.concept_id IS NULL
                 AND c_snomed.concept_id IS NULL THEN 0 
        END,
        44814650
    )::INTEGER AS cause_source_concept_id
FROM (
    SELECT * FROM RankedDeath WHERE row_num = 1
) AS d
LEFT JOIN (
    SELECT * FROM RankedDeathCause WHERE row_num = 1
) AS dc ON 
    {% if site in ['mu', 'mu-id'] %}
        dc.patid = d.patid
    {% elif site == 'gpc' %}
        dc.patient_num = d.patient_num
    {% else %}
        dc.patid = d.patid
    {% endif %}
LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping dt
    ON dt.pcornet_table_name = 'DEATH'
    AND dt.pcornet_field_name = 'DEATH_SOURCE'
    AND dt.pcornet_valueset_item = d.death_source
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept c_icd9 
    ON dc.death_cause = c_icd9.concept_code
    AND c_icd9.vocabulary_id = 'ICD9CM'
    AND dc.death_cause_code = '09'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept c_icd10 
    ON dc.death_cause = c_icd10.concept_code
    AND c_icd10.vocabulary_id = 'ICD10CM'
    AND dc.death_cause_code = '10'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept c_snomed 
    ON dc.death_cause = c_snomed.concept_code
    AND c_snomed.vocabulary_id = 'SNOMED'
    AND dc.death_cause_code = 'SM'
);
