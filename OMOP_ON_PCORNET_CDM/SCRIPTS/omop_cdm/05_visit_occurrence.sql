{% if site in ['mu', 'mu-id'] %}
  {% set visit_occurrence_id_expr = "enc.encounterid::INTEGER" %}
  {% set person_id_expr = "enc.patid::INTEGER" %}
  {% set provider_id_expr = "enc.providerid::INTEGER" %}
{% elif site == 'gpc' %}
  {% set visit_occurrence_id_expr = "enc.encounter_num::INTEGER" %}
  {% set person_id_expr = "enc.patient_num::INTEGER" %}
  {% set provider_id_expr = "-1::INTEGER" %}
{% else %}
  {% set visit_occurrence_id_expr = "enc.encounterid::INTEGER" %}
  {% set person_id_expr = "enc.patid::INTEGER" %}
  {% set provider_id_expr = "enc.providerid::INTEGER" %}
{% endif %}

CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.visit_occurrence (
    visit_occurrence_id integer NOT NULL,
    person_id integer NOT NULL,
    visit_concept_id integer NOT NULL,
    visit_start_date date NOT NULL,
    visit_start_datetime TIMESTAMP NULL,
    visit_end_date date NOT NULL,
    visit_end_datetime TIMESTAMP NULL,
    visit_type_concept_id Integer NOT NULL,
    provider_id integer NULL,
    care_site_id integer NULL,
    visit_source_value varchar(50) NULL,
    visit_source_concept_id integer NULL,
    admitted_from_concept_id integer NULL,
    admitted_from_source_value varchar(50) NULL,
    discharged_to_concept_id integer NULL,
    discharged_to_source_value varchar(50) NULL,
    preceding_visit_occurrence_id integer NULL 
) AS
SELECT 
    {{ visit_occurrence_id_expr }}                                  AS visit_occurrence_id,
    {{ person_id_expr }}                                            AS person_id,
    COALESCE(enctyp.source_concept_id, 0)::INTEGER                  AS visit_concept_id,
    DATE(enc.admit_date)::DATE                                      AS visit_start_date,
    CONCAT(DATE(enc.admit_date), ' ', enc.admit_time)::TIMESTAMP    AS visit_start_datetime,
    DATE(COALESCE(enc.discharge_date, enc.admit_date))::DATE        AS visit_end_date,
    CONCAT(
      DATE(COALESCE(enc.discharge_date, enc.admit_date)),
      ' ',
      COALESCE(enc.discharge_time, enc.admit_time)
    )::TIMESTAMP                                                    AS visit_end_datetime,
    44818518::INTEGER                                               AS visit_type_concept_id,
    {{ provider_id_expr }}                                          AS provider_id,
    m.care_site_id::INTEGER                                         AS care_site_id,
    LEFT(COALESCE(enc.raw_enc_type, ''), 50)::VARCHAR(50)           AS visit_source_value,
    NULL::INTEGER                                                   AS visit_source_concept_id,
    as_map.source_concept_id::INTEGER                               AS admitted_from_concept_id,
    LEFT(COALESCE(enc.raw_admitting_source, ''), 50)::VARCHAR(50)   AS admitted_from_source_value,
    ds_map.source_concept_id::INTEGER                               AS discharged_to_concept_id,
    LEFT(COALESCE(enc.raw_discharge_status, ''), 50)::VARCHAR(50)   AS discharged_to_source_value,
    NULL::INTEGER                                                   AS preceding_visit_occurrence_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ encounter_table }} enc
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.care_site_map m
  ON m.facilityid_source = enc.facilityid
-- Mapping admitted_from
LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping as_map
  ON as_map.pcornet_table_name = 'ENCOUNTER'
 AND as_map.pcornet_field_name = 'ADMITTING SOURCE'
 AND as_map.pcornet_valueset_item = enc.admitting_source
-- Mapping discharged_to
LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping ds_map
  ON ds_map.pcornet_table_name = 'ENCOUNTER'
 AND ds_map.pcornet_field_name = 'DISCHARGE STATUS'
 AND ds_map.pcornet_valueset_item = enc.discharge_status
-- Mapping visit concept from enc_type
LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping enctyp
  ON enctyp.pcornet_table_name = 'ENCOUNTER'
 AND enctyp.pcornet_field_name = 'ENC TYPE'
 AND enctyp.pcornet_valueset_item = enc.enc_type
;
