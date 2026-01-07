{% if site in ['mu', 'mu-id'] %}
  {% set person_id_expr = "lab.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "lab.encounterid::INTEGER" %}
{% elif site == 'gpc' %}
  {% set person_id_expr = "lab.patient_num::INTEGER" %}
  {% set visit_occurrence_id_expr = "lab.encounter_num::INTEGER" %}
{% else %}
  {% set person_id_expr = "lab.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "lab.encounterid::INTEGER" %}
{% endif %}


CREATE OR REPLACE SEQUENCE {{ cdm_db }}.{{ cdm_schema }}.measurement_id_seq START = 1 INCREMENT = 1;
-- 1) Create a mapping table to generate measurement_id values
CREATE OR REPLACE TABLE {{ cdm_db }}.{{ cdm_schema }}.measurement_id_map AS
WITH ids AS (
  SELECT distinct
    lab.lab_result_cm_id     AS measurementid_source
  FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ lab_results_table }} lab
  WHERE lab.lab_result_cm_id IS NOT NULL
)
SELECT
  measurementid_source,
  {{ cdm_db }}.{{ cdm_schema }}.measurement_id_seq.NEXTVAL::INTEGER AS measurement_id
FROM ids
;


CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.measurement (
    measurement_id integer NOT NULL,
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
) AS
SELECT 
    idmap.measurement_id::INTEGER                                   AS measurement_id,
    {{ person_id_expr }}                                            AS person_id,
    c.concept_id::INTEGER                                           AS measurement_concept_id,
    lab.result_date::DATE                                           AS measurement_date,
    lab.result_date::TIMESTAMP                                      AS measurement_datetime,
    lab.result_time::VARCHAR(10)                                    AS measurement_time,
    COALESCE(c_result.concept_id, 0)::INTEGER                        AS measurement_type_concept_id,
    NULL::INTEGER                                                   AS operator_concept_id,
    lab.result_num::FLOAT                                           AS value_as_number,
    CASE
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
      WHEN LOWER(TRIM(result_qual)) IN ('ni','ot','un','no information','unknown','other') THEN NULL::INTEGER
      WHEN result_qual IS NULL THEN NULL::INTEGER
      ELSE 45877393::INTEGER
    END                                                             AS value_as_concept_id,
    u.concept_id::INTEGER                                           AS unit_concept_id,
    TRY_CAST(lab.norm_range_low AS FLOAT)                           AS range_low,
    TRY_CAST(lab.norm_range_high AS FLOAT)                          AS range_high,
    NULL::INTEGER                                                   AS provider_id,
    {{ visit_occurrence_id_expr }}                                  AS visit_occurrence_id,
    {{ visit_occurrence_id_expr }}                                  AS visit_detail_id,
    LEFT(COALESCE(lab.lab_loinc, ''), 50)::VARCHAR(50)              AS measurement_source_value,
    0::INTEGER                                                      AS measurement_source_concept_id,
    LEFT(COALESCE(lab.result_unit, ''), 50)::VARCHAR(50)            AS unit_source_value,
    NULL::INTEGER                                                   AS unit_source_concept_id,
    COALESCE(
      LEFT(COALESCE(lab.raw_result, ''), 50),
      LEFT(CASE WHEN lab.result_num = 0 THEN COALESCE(lab.result_qual, '') ELSE NULL END, 50)
    )::VARCHAR(50)                                                  AS value_source_value,
    NULL::INTEGER                                                   AS measurement_event_id,
    NULL::INTEGER                                                   AS meas_event_field_concept_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ lab_results_table }} lab
JOIN {{ cdm_db }}.{{ cdm_schema }}.measurement_id_map idmap
  ON idmap.measurementid_source = lab.lab_result_cm_id

JOIN {{ cdm_db }}.{{ vocabulary }}.concept c
  ON lab.lab_loinc = c.concept_code
 AND c.domain_id = 'Measurement'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept u
  ON lab.result_unit = u.concept_code
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept c_result
  ON lab.lab_result_source = c_result.concept_code
where result_date is not null
;
