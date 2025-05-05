CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.measurement AS
SELECT DISTINCT
    {% if site in ['mu', 'mu-id'] %}
        lab.lab_result_cm_id::INTEGER AS measurement_id
    {% elif site == 'gpc' %}
        ROW_NUMBER() OVER (ORDER BY lab.lab_result_cm_id)::INTEGER AS measurement_id
    {% else %}
        lab.lab_result_cm_id::INTEGER AS measurement_id
    {% endif %}
    {% if site in ['mu', 'mu-id'] %}
        , lab.patid::INTEGER AS person_id
    {% elif site == 'gpc' %}
        , lab.person_num::INTEGER AS person_id
    {% else %}
        , lab.patid::INTEGER AS person_id
    {% endif %}
    , c.concept_id::INTEGER AS measurement_concept_id
    , lab.result_date::DATE AS measurement_date
    , lab.result_date::TIMESTAMP AS measurement_datetime
    , lab.result_time::VARCHAR(10) AS measurement_time
    , COALESCE(c_result.concept_id, 0)::INTEGER AS measurement_type_concept_id
    , NULL::INTEGER AS operator_concept_id
    , lab.result_num::NUMERIC AS value_as_number
    , CASE
        WHEN LOWER(TRIM(result_qual)) IN ('positive', 'pos', 'presumptive positive', 'detected') THEN 45884084
        WHEN LOWER(TRIM(result_qual)) IN ('negative', 'neg', 'presumptive negative', 'not detected', 'undetectable') THEN 45878583
        WHEN LOWER(TRIM(result_qual)) = 'inconclusive' THEN 45877990
        WHEN LOWER(TRIM(result_qual)) = 'normal' THEN 45884153
        WHEN LOWER(TRIM(result_qual)) = 'abnormal' THEN 45878745
        WHEN LOWER(TRIM(result_qual)) = 'low' THEN 45881666
        WHEN LOWER(TRIM(result_qual)) = 'high' THEN 45876384
        WHEN LOWER(TRIM(result_qual)) = 'borderline' THEN 45880922
        WHEN LOWER(TRIM(result_qual)) = 'elevated' THEN 4328749
        WHEN LOWER(TRIM(result_qual)) = 'undetermined' THEN 45880649
        WHEN LOWER(TRIM(result_qual)) IN ('ni', 'ot', 'un', 'no information', 'unknown', 'other') THEN NULL::INTEGER
        WHEN result_qual IS NULL THEN NULL::INTEGER
        ELSE 45877393::INTEGER
      END AS value_as_concept_id
    , u.concept_id::INTEGER AS unit_concept_id
    , TRY_CAST(lab.norm_range_low AS FLOAT)::NUMERIC AS range_low
    , TRY_CAST(lab.norm_range_high AS FLOAT)::NUMERIC AS range_high
    , NULL::INTEGER AS provider_id
    {% if site in ['mu', 'mu-id'] %}
        , lab.encounterid::INTEGER AS visit_occurrence_id
    {% elif site == 'gpc' %}
        , lab.encounter_num::INTEGER AS visit_occurrence_id
    {% else %}
        , lab.encounterid::INTEGER AS visit_occurrence_id
    {% endif %}
    , NULL::INTEGER AS visit_detail_id
    , lab.lab_loinc::VARCHAR(50) AS measurement_source_value
    , 0::INTEGER AS measurement_source_concept_id
    , lab.result_unit::VARCHAR(50) AS unit_source_value
    , NULL::INTEGER AS unit_source_concept_id
    , COALESCE(LEFT(lab.raw_result, 100), CASE WHEN lab.result_num = 0 THEN lab.result_qual ELSE NULL END)::VARCHAR(100) AS value_source_value
    , NULL::INTEGER AS measurement_event_id
    , NULL::INTEGER AS meas_event_field_concept_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ lab_results_table }} lab
JOIN {{ cdm_db }}.{{ cdm_schema }}.concept c
    ON lab.lab_loinc = c.concept_code
    AND c.domain_id = 'Measurement'
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept u
    ON lab.result_unit = u.concept_code
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept c_result
    ON lab.lab_result_source = c_result.concept_code
;
