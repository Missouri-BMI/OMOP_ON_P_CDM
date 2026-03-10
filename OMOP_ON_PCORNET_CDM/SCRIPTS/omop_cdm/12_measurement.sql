{% if site in ['mu', 'mu-id'] %}
  {% set person_id_expr = "lab.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "lab.encounterid::INTEGER" %}
  {% set vital_pat_col = "patid" %}
  {% set vital_enc_col = "encounterid" %}
{% elif site == 'gpc' %}
  {% set person_id_expr = "lab.patient_num::INTEGER" %}
  {% set visit_occurrence_id_expr = "lab.encounter_num::INTEGER" %}
  {% set vital_pat_col = "patient_num" %}
  {% set vital_enc_col = "encounter_num" %}
{% else %}
  {% set person_id_expr = "lab.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "lab.encounterid::INTEGER" %}
  {% set vital_pat_col = "patid" %}
  {% set vital_enc_col = "encounterid" %}
{% endif %}


{% set vital_person_id_expr = "v.patid::INTEGER" %}
{% set vital_visit_occurrence_id_expr = "v.encounterid::INTEGER" %}


CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.measurement (
    measurement_id integer IDENTITY (1,1),
    person_id integer NOT NULL,
    measurement_concept_id integer NOT NULL,
    measurement_date date NOT NULL,
    measurement_datetime TIMESTAMP NULL,
    measurement_time varchar(10) NULL,
    measurement_type_concept_id integer NOT NULL,
    operator_concept_id integer NULL,
    value_as_number float NULL,
    value_as_concept_id integer NULL,
    unit_concept_id integer NULL,
    range_low float NULL,
    range_high float NULL,
    provider_id integer NULL,
    visit_occurrence_id integer NULL,
    visit_detail_id integer NULL,
    measurement_source_value varchar(50) NULL,
    measurement_source_concept_id integer NULL,
    unit_source_value varchar(50) NULL,
    unit_source_concept_id integer NULL,
    value_source_value varchar(50) NULL,
    measurement_event_id integer NULL,
    meas_event_field_concept_id integer NULL
);

-- 1) Insert from Lab Results Table
INSERT INTO {{ cdm_db }}.{{ cdm_schema }}.measurement (
    person_id,
    measurement_concept_id,
    measurement_date,
    measurement_datetime,
    measurement_time,
    measurement_type_concept_id,
    operator_concept_id,
    value_as_number,
    value_as_concept_id,
    unit_concept_id,
    range_low,
    range_high,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    measurement_source_value,
    measurement_source_concept_id,
    unit_source_value,
    unit_source_concept_id,
    value_source_value,
    measurement_event_id,
    meas_event_field_concept_id
)
WITH operator_map AS (
    SELECT 
        p.RESULT_MODIFIER,
        o.concept_id AS operator_concept_id
    FROM (SELECT DISTINCT RESULT_MODIFIER FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ lab_results_table }} WHERE RESULT_MODIFIER IS NOT NULL) p
    JOIN {{ cdm_db }}.{{ cdm_schema }}.concept o 
      ON o.domain_id = 'Meas Value Operator' 
     AND o.standard_concept = 'S'
     AND (
        CASE 
            WHEN p.RESULT_MODIFIER = 'EQ' THEN '='
            WHEN p.RESULT_MODIFIER = 'LT' THEN '<'
            WHEN p.RESULT_MODIFIER = 'LE' THEN '<='
            WHEN p.RESULT_MODIFIER = 'GT' THEN '>'
            WHEN p.RESULT_MODIFIER = 'GE' THEN '>='
            ELSE NULL 
        END = o.concept_name
     )
),
qual_map AS (
    SELECT 
        p.result_qual,
        c.concept_id AS value_as_concept_id
    FROM (SELECT DISTINCT result_qual FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ lab_results_table }} WHERE result_qual IS NOT NULL) p
    JOIN {{ cdm_db }}.{{ cdm_schema }}.concept c
      ON LOWER(p.result_qual) = LOWER(c.concept_name)
     AND c.domain_id = 'Meas Value' 
     AND c.vocabulary_id = 'LOINC' 
     AND c.standard_concept = 'S'
),
unit_map AS (
    SELECT 
        p.RESULT_UNIT,
        u.concept_id AS unit_concept_id
    FROM (SELECT DISTINCT RESULT_UNIT FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ lab_results_table }} WHERE RESULT_UNIT IS NOT NULL) p
    JOIN {{ cdm_db }}.{{ cdm_schema }}.concept u
      ON p.RESULT_UNIT = u.concept_code
     AND u.domain_id = 'Unit' 
     AND u.concept_class_id = 'Unit' 
     AND u.standard_concept = 'S'
)
SELECT
    {{ person_id_expr }}                                                AS person_id,
    srctostdvm.target_concept_id                                        AS measurement_concept_id,
    lab.result_date                                                     AS measurement_date,
    NULL::TIMESTAMP                                                     AS measurement_datetime,
    NULL::VARCHAR(10)                                                   AS measurement_time,
    CASE lab.lab_result_source
        WHEN 'OD' THEN 32817  
        ELSE 0
    END::INTEGER                                                        AS measurement_type_concept_id,
    COALESCE(op_map.operator_concept_id, 0)::INTEGER                    AS operator_concept_id,
    lab.result_num::FLOAT                                               AS value_as_number,
    COALESCE(q_map.value_as_concept_id, 0)::INTEGER                     AS value_as_concept_id,
    COALESCE(u_map.unit_concept_id, 0)::INTEGER                         AS unit_concept_id,
    TRY_CAST(lab.norm_range_low AS FLOAT)                               AS range_low,
    TRY_CAST(lab.norm_range_high AS FLOAT)                              AS range_high,
    NULL::INTEGER                                                       AS provider_id,
    {{ visit_occurrence_id_expr }}                                      AS visit_occurrence_id,
    {{ visit_occurrence_id_expr }}                                      AS visit_detail_id,
    LEFT(lab.lab_loinc::VARCHAR, 50)::VARCHAR(50)                       AS measurement_source_value,
    srctosrcvm.source_concept_id::INTEGER                               AS measurement_source_concept_id,
    NULL::VARCHAR(50)                                                   AS unit_source_value,
    NULL::INTEGER                                                       AS unit_source_concept_id,
    NULL::VARCHAR(50)                                                   AS value_source_value,
    NULL::INTEGER                                                       AS measurement_event_id,
    NULL::INTEGER                                                       AS meas_event_field_concept_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ lab_results_table }} lab
JOIN {{ cdm_db }}.{{ cdm_schema }}.source_to_source_vocab_map srctosrcvm
  ON srctosrcvm.source_code = lab.lab_loinc
  AND srctosrcvm.source_vocabulary_id = 'LOINC'
  AND srctosrcvm.source_domain_id = 'Measurement'
  AND srctosrcvm.source_concept_class_id = 'Lab Test'
  AND lab.lab_loinc IS NOT NULL
  AND lab.result_date IS NOT NULL
JOIN {{ cdm_db }}.{{ cdm_schema }}.source_to_standard_vocab_map srctostdvm
  ON srctostdvm.source_code = srctosrcvm.source_code
  AND srctostdvm.target_domain_id = srctosrcvm.source_domain_id
  AND srctostdvm.source_vocabulary_id = srctosrcvm.source_vocabulary_id
  AND srctostdvm.target_standard_concept = 'S'
  AND srctostdvm.target_invalid_reason IS NULL
LEFT JOIN operator_map op_map
  ON lab.RESULT_MODIFIER = op_map.RESULT_MODIFIER
LEFT JOIN qual_map q_map
  ON lab.result_qual = q_map.result_qual
LEFT JOIN unit_map u_map
  ON lab.RESULT_UNIT = u_map.RESULT_UNIT;


-- 2) Insert from Vitals Table
INSERT INTO {{ cdm_db }}.{{ cdm_schema }}.measurement (
    person_id,
    measurement_concept_id,
    measurement_date,
    measurement_datetime,
    measurement_time,
    measurement_type_concept_id,
    operator_concept_id,
    value_as_number,
    value_as_concept_id,
    unit_concept_id,
    range_low,
    range_high,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    measurement_source_value,
    measurement_source_concept_id,
    unit_source_value,
    unit_source_concept_id,
    value_source_value,
    measurement_event_id,
    meas_event_field_concept_id
)
WITH vitals_unpivoted AS (
    -- 1) Height
    SELECT 
        {{ vital_pat_col }} AS patid, 
        {{ vital_enc_col }} AS encounterid, 
        measure_date, measure_time, vital_source, 
        '8302-2' AS loinc_code, 
        ht::FLOAT AS value_as_number, 
        NULL::VARCHAR AS value_as_string,
        '[in_us]' AS unit,
        '=' as operator
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ vital_table }} 
    WHERE ht IS NOT NULL

    UNION ALL

    -- 2) Weight
    SELECT 
        {{ vital_pat_col }} AS patid, 
        {{ vital_enc_col }} AS encounterid, 
        measure_date, measure_time, vital_source, 
        '3141-9' AS loinc_code, 
        wt::FLOAT AS value_as_number, 
        NULL::VARCHAR AS value_as_string,
        'kg' as unit,
        '=' as operator
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ vital_table }} 
    WHERE wt IS NOT NULL

    UNION ALL

    -- 3) Diastolic Blood Pressure
    SELECT 
        {{ vital_pat_col }} AS patid, 
        {{ vital_enc_col }} AS encounterid, 
        measure_date, measure_time, vital_source, 
        '8462-4' AS loinc_code, 
        diastolic::FLOAT AS value_as_number, 
        NULL::VARCHAR AS value_as_string,
        'mm[Hg]' as unit,
        '=' as operator
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ vital_table }} 
    WHERE diastolic IS NOT NULL

    UNION ALL

    -- 4) Systolic Blood Pressure
    SELECT 
        {{ vital_pat_col }} AS patid, 
        {{ vital_enc_col }} AS encounterid, 
        measure_date, measure_time, vital_source, 
        '8480-6' AS loinc_code, 
        systolic::FLOAT AS value_as_number, 
        NULL::VARCHAR AS value_as_string,
        'mm[Hg]' as unit,
        '=' as operator
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ vital_table }} 
    WHERE systolic IS NOT NULL

    UNION ALL

    -- 5) BMI
    SELECT 
        {{ vital_pat_col }} AS patid, 
        {{ vital_enc_col }} AS encounterid, 
        measure_date, measure_time, vital_source, 
        '39156-5' AS loinc_code, 
        original_bmi::FLOAT AS value_as_number, 
        NULL::VARCHAR AS value_as_string,
        'kg/m2' as unit, 
        '=' as operator
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ vital_table }} 
    WHERE original_bmi IS NOT NULL

    UNION ALL

    -- 6) Smoking Status
    SELECT 
        {{ vital_pat_col }} AS patid, 
        {{ vital_enc_col }} AS encounterid, 
        measure_date, measure_time, vital_source, 
        '72166-2' AS loinc_code, 
        NULL::FLOAT AS value_as_number, 
        CASE smoking
            WHEN '04' THEN 'LA18978-9'
            WHEN '05' THEN 'LA18979-7'
            WHEN '03' THEN 'LA15920-4'
            WHEN '01' THEN 'LA18976-3'
            WHEN '06' THEN 'LA18980-5'
            WHEN '02' THEN 'LA18977-1'
            WHEN '07' THEN 'LA18981-3'
            WHEN '08' THEN 'LA18982-1'
            ELSE 'LA18980-5'
        END::VARCHAR AS value_as_string,
        NULL as unit,
        '=' as operator
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ vital_table }} 
    WHERE smoking IS NOT NULL 
)
SELECT
    {{ vital_person_id_expr }}                                          AS person_id,
    COALESCE(srctostdvm.target_concept_id, 0)::INTEGER                  AS measurement_concept_id,
    v.measure_date::DATE                                                AS measurement_date,
    NULL::TIMESTAMP                                                     AS measurement_datetime,
    LEFT(v.measure_time, 10)::VARCHAR(10)                               AS measurement_time,
    0                                                                   AS measurement_type_concept_id,
    o.concept_id::INTEGER                                               AS operator_concept_id,
    v.value_as_number::FLOAT                                            AS value_as_number,
    COALESCE(val_vocab.concept_id, 0)::INTEGER                          AS value_as_concept_id,
    u.concept_id::INTEGER                                               AS unit_concept_id,
    NULL::FLOAT                                                         AS range_low,
    NULL::FLOAT                                                         AS range_high,
    NULL::INTEGER                                                       AS provider_id,
    {{ vital_visit_occurrence_id_expr }}                                AS visit_occurrence_id,
    {{ vital_visit_occurrence_id_expr }}                                AS visit_detail_id,
    v.loinc_code::VARCHAR(50)                                           AS measurement_source_value,
    COALESCE(srctosrcvm.source_concept_id, 0)::INTEGER                  AS measurement_source_concept_id,
    NULL::VARCHAR(50)                                                   AS unit_source_value,
    NULL::INTEGER                                                       AS unit_source_concept_id,
    v.value_as_string::VARCHAR(50)                                      AS value_source_value,
    NULL::INTEGER                                                       AS measurement_event_id,
    NULL::INTEGER                                                       AS meas_event_field_concept_id
FROM vitals_unpivoted v
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.source_to_source_vocab_map srctosrcvm
  ON srctosrcvm.source_code = v.loinc_code
 AND srctosrcvm.source_vocabulary_id = 'LOINC'
 AND srctosrcvm.source_domain_id = 'Measurement'
 AND srctosrcvm.source_concept_class_id in ('Clinical Observation', 'Answer')
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.source_to_standard_vocab_map srctostdvm
  ON srctostdvm.source_code = srctosrcvm.source_code
  AND srctostdvm.target_domain_id = srctosrcvm.source_domain_id
  AND srctostdvm.source_vocabulary_id = srctosrcvm.source_vocabulary_id
  AND srctostdvm.target_standard_concept = 'S'
  AND srctostdvm.target_invalid_reason IS NULL
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept u
      ON v.unit = u.concept_code
     AND u.domain_id = 'Unit' 
     AND u.concept_class_id = 'Unit' 
     AND u.standard_concept = 'S'
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept o 
      ON o.domain_id = 'Meas Value Operator' 
     AND o.standard_concept = 'S'
     AND v.operator = o.concept_name
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept val_vocab
  ON val_vocab.concept_code = v.value_as_string
 AND val_vocab.vocabulary_id = 'LOINC'
 AND val_vocab.standard_concept = 'S'
WHERE v.measure_date IS NOT NULL;