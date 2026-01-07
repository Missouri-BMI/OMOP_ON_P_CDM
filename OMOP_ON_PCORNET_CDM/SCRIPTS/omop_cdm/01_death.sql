{% if site in ['mu', 'mu-id'] %}
  {% set person_key = "patid" %}
{% elif site == 'gpc' %}
  {% set person_key = "patient_num" %}
{% else %}
  {% set person_key = "patid" %}
{% endif %}

CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.death (
    person_id                INTEGER NOT NULL,
    death_date               DATE    NOT NULL,
    death_datetime           TIMESTAMP NULL,
    death_type_concept_id    INTEGER NULL,
    cause_concept_id         INTEGER NULL,
    cause_source_value       VARCHAR(50) NULL,
    cause_source_concept_id  INTEGER NULL
) AS
WITH
-- Pick a single death row per patient, preferring the best DEATH_SOURCE
d AS (
  SELECT *
  FROM (
    SELECT
      d0.*,
      ROW_NUMBER() OVER (
        PARTITION BY d0.{{ person_key }}
        ORDER BY
          CASE d0.death_source
            WHEN 'D'  THEN 1
            WHEN 'N'  THEN 2
            WHEN 'L'  THEN 3
            WHEN 'S'  THEN 4
            WHEN 'T'  THEN 5
            WHEN 'DR' THEN 6
            WHEN 'NI' THEN 7
            WHEN 'UN' THEN 8
            WHEN 'OT' THEN 9
            ELSE 8
          END
      ) AS rn
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ death_table }} d0
    WHERE d0.{{ person_key }} IS NOT NULL
      AND d0.death_date IS NOT NULL
  )
  WHERE rn = 1
),

-- Pick a single cause-of-death row per patient, preferring ICD10 > ICD9 > SNOMED > other
dc AS (
  SELECT *
  FROM (
    SELECT
      dc0.*,
      ROW_NUMBER() OVER (
        PARTITION BY dc0.{{ person_key }}
        ORDER BY
          CASE dc0.death_cause_code
            WHEN '10' THEN 1
            WHEN '09' THEN 2
            WHEN 'SM' THEN 3
            ELSE 4
          END
      ) AS rn
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ death_cause_table }} dc0
    WHERE dc0.{{ person_key }} IS NOT NULL
  )
  WHERE rn = 1
),

-- Map DEATH_SOURCE -> OMOP concept (death_type_concept_id)
dt AS (
  SELECT pcornet_valueset_item, source_concept_id
  FROM {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping
  WHERE pcornet_table_name = 'DEATH'
    AND pcornet_field_name = 'DEATH_SOURCE'
)

SELECT
  d.{{ person_key }}::INTEGER                                     AS person_id,
  d.death_date::DATE                                             AS death_date,
  d.death_date::TIMESTAMP                                        AS death_datetime,
  COALESCE(dt.source_concept_id, 0)::INTEGER                      AS death_type_concept_id,

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
  )::INTEGER                                                     AS cause_concept_id,

  LEFT(COALESCE(dc.death_cause::VARCHAR, ''), 50)::VARCHAR(50)    AS cause_source_value,

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
  )::INTEGER                                                     AS cause_source_concept_id

FROM d
LEFT JOIN dc
  ON dc.{{ person_key }} = d.{{ person_key }}
LEFT JOIN dt
  ON dt.pcornet_valueset_item = d.death_source
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
;
