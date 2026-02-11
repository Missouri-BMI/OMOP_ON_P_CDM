{% if site in ['mu', 'mu-id'] %}
  {% set person_id_expr = "enc.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "enc.encounterid::INTEGER" %}
{% elif site == 'gpc' %}
  {% set person_id_expr = "enc.patient_num::INTEGER" %}
  {% set visit_occurrence_id_expr = "enc.encounter_num::INTEGER" %}
{% else %}
  {% set person_id_expr = "enc.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "enc.encounterid::INTEGER" %}
{% endif %}


CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.observation (
    observation_id integer NOT NULL,
    person_id integer NOT NULL,
    observation_concept_id integer NOT NULL,
    observation_date date NOT NULL,
    observation_datetime TIMESTAMP NULL,
    observation_type_concept_id integer NOT NULL,
    value_as_number float NULL,
    value_as_string varchar(60) NULL,
    value_as_concept_id integer NULL,
    qualifier_concept_id integer NULL,
    unit_concept_id integer NULL,
    provider_id integer NULL,
    visit_occurrence_id integer NULL,
    visit_detail_id integer NULL,
    observation_source_value varchar(50) NULL,
    observation_source_concept_id integer NULL,
    unit_source_value varchar(50) NULL,
    qualifier_source_value varchar(50) NULL,
    value_source_value varchar(50) NULL,
    observation_event_id integer NULL,
    obs_event_field_concept_id integer NULL
) AS
SELECT 
    {{ visit_occurrence_id_expr }}                            AS observation_id,
    {{ person_id_expr }}                                      AS person_id,
    3040464::INTEGER                                          AS observation_concept_id,

    COALESCE(
      TRY_TO_DATE(enc.discharge_date::VARCHAR, 'YYYY-MM-DD'),
      TRY_TO_DATE(enc.admit_date::VARCHAR,     'YYYY-MM-DD'),
      '0001-01-01'::DATE
    ) AS observation_date,

    COALESCE(
      TRY_TO_TIMESTAMP(enc.discharge_date::VARCHAR, 'YYYY-MM-DD HH24:MI:SS'),
      TRY_TO_TIMESTAMP(enc.admit_date::VARCHAR,     'YYYY-MM-DD HH24:MI:SS'),
      '0001-01-01'::TIMESTAMP
    ) AS observation_datetime,

    38000280::INTEGER                                         AS observation_type_concept_id,
    NULL::FLOAT                                               AS value_as_number,
    NULL::VARCHAR(60)                                         AS value_as_string,

    CASE
      WHEN COALESCE(
             TRY_TO_DATE(enc.discharge_date::VARCHAR, 'YYYY-MM-DD'),
             TRY_TO_DATE(enc.admit_date::VARCHAR,     'YYYY-MM-DD')
           ) < '2007-10-01'
        THEN COALESCE(drg.concept_id, msdrg.concept_id)
      ELSE msdrg.concept_id
    END::INTEGER                                              AS value_as_concept_id,

    4269228::INTEGER                                          AS qualifier_concept_id,
    NULL::INTEGER                                             AS unit_concept_id,

    pm.provider_id                                            AS provider_id,
    {{ visit_occurrence_id_expr }}                            AS visit_occurrence_id,
    {{ visit_occurrence_id_expr }}                            AS visit_detail_id,

    LEFT('DRG|' || COALESCE(enc.drg::VARCHAR, ''), 50)::VARCHAR(50) AS observation_source_value,
    0::INTEGER                                                AS observation_source_concept_id,
    NULL::VARCHAR(50)                                         AS unit_source_value,
    'Primary'::VARCHAR(50)                                    AS qualifier_source_value,

    LEFT(
      CASE
        WHEN COALESCE(
               TRY_TO_DATE(enc.discharge_date::VARCHAR, 'YYYY-MM-DD'),
               TRY_TO_DATE(enc.admit_date::VARCHAR,     'YYYY-MM-DD')
             ) < '2007-10-01'
          THEN COALESCE(drg.concept_id, msdrg.concept_id)::VARCHAR
        ELSE msdrg.concept_id::VARCHAR
      END,
      50
    )::VARCHAR(50)                                            AS value_source_value,

    NULL::INTEGER                                             AS observation_event_id,
    NULL::INTEGER                                             AS obs_event_field_concept_id

FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ observation_table }} enc
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.provider_id_map pm
  ON pm.providerid_source = enc.providerid
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept drg
  ON enc.drg = drg.concept_code
 AND drg.concept_class_id = 'DRG'
 AND drg.valid_end_date = '2007-09-30'
 AND drg.invalid_reason = 'D'
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept msdrg
  ON enc.drg = msdrg.concept_code
 AND msdrg.concept_class_id = 'MS-DRG'
 AND msdrg.invalid_reason IS NULL
WHERE enc.drg IS NOT NULL
;
