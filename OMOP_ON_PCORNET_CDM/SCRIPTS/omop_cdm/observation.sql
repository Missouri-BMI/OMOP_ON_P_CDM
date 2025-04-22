CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.observation AS
SELECT DISTINCT
    3040464 AS observation_concept_id,
    CASE
        WHEN enc.discharge_date IS NOT NULL AND TRY_TO_DATE(enc.discharge_date::VARCHAR, 'YYYY-MM-DD') IS NOT NULL
            THEN TRY_TO_DATE(enc.discharge_date::VARCHAR, 'YYYY-MM-DD')
        WHEN enc.admit_date IS NOT NULL AND TRY_TO_DATE(enc.admit_date::VARCHAR, 'YYYY-MM-DD') IS NOT NULL
            THEN TRY_TO_DATE(enc.admit_date::VARCHAR, 'YYYY-MM-DD')
        ELSE '0001-01-01'::DATE
    END AS observation_date,
    CASE
        WHEN enc.discharge_date IS NOT NULL AND TRY_TO_TIMESTAMP(enc.discharge_date::VARCHAR, 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL
            THEN TRY_TO_TIMESTAMP(enc.discharge_date::VARCHAR, 'YYYY-MM-DD HH24:MI:SS')
        WHEN enc.admit_date IS NOT NULL AND TRY_TO_TIMESTAMP(enc.admit_date::VARCHAR, 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL
            THEN TRY_TO_TIMESTAMP(enc.admit_date::VARCHAR, 'YYYY-MM-DD HH24:MI:SS')
        ELSE '0001-01-01'::TIMESTAMP
    END AS observation_datetime,
    ROW_NUMBER() OVER (ORDER BY enc.encounterid)::INTEGER AS observation_id,  -- TODO: replace with global observation_id generator if needed
    0 AS observation_source_concept_id,
    'DRG|' || enc.drg AS observation_source_value,
    38000280 AS observation_type_concept_id,
    -- Person ID logic
    {% if site in ['mu', 'mu-id'] %}
        enc.patid::INTEGER AS person_id,
    {% elif site == 'gpc' %}
        enc.person_num::INTEGER AS person_id,
    {% else %}
        enc.patid::INTEGER AS person_id,
    {% endif %}
    enc.providerid AS provider_id,
    4269228 AS qualifier_concept_id,
    'Primary' AS qualifier_source_value,  -- Only primary DRG is captured in PCORnet
    NULL AS unit_concept_id,
    NULL AS unit_source_value,
    -- Value as concept
    CASE
        WHEN TRY_TO_DATE(enc.discharge_date::VARCHAR, 'YYYY-MM-DD') < '2007-10-01'
          OR TRY_TO_DATE(enc.admit_date::VARCHAR, 'YYYY-MM-DD') < '2007-10-01'
            THEN COALESCE(drg.concept_id, msdrg.concept_id)
        ELSE msdrg.concept_id
    END AS value_as_concept_id,
    NULL AS value_as_number,
    NULL AS value_as_string,
    -- Value source value (string version of concept)
    CASE
        WHEN TRY_TO_DATE(enc.discharge_date::VARCHAR, 'YYYY-MM-DD') < '2007-10-01'
          OR TRY_TO_DATE(enc.admit_date::VARCHAR, 'YYYY-MM-DD') < '2007-10-01'
            THEN COALESCE(drg.concept_id, msdrg.concept_id)::VARCHAR
        ELSE msdrg.concept_id::VARCHAR
    END AS value_source_value,
    {% if site in ['mu', 'mu-id'] %}
        enc.encounterid::INTEGER AS visit_occurrence_id
    {% elif site == 'gpc' %}
        enc.encounter_num::INTEGER AS visit_occurrence_id
    {% else %}
        enc.encounterid::INTEGER AS visit_occurrence_id
    {% endif %}
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ observation_table }} enc
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept drg
    ON enc.drg = drg.concept_code
    AND drg.concept_class_id = 'DRG'
    AND drg.valid_end_date = '2007-09-30'
    AND drg.invalid_reason = 'D'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept msdrg
    ON enc.drg = msdrg.concept_code
    AND msdrg.concept_class_id = 'MS-DRG'
    AND msdrg.invalid_reason IS NULL
WHERE enc.drg IS NOT NULL;
