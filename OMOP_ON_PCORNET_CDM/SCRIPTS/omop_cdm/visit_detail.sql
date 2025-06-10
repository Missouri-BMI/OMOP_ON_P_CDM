CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.visit_detail AS (
    SELECT 
        {% if site in ['mu', 'mu-id'] %}
            enc.encounterid::INTEGER AS visit_detail_id,
            enc.patid::INTEGER AS person_id,
            enc.providerid::INTEGER AS provider_id,
        {% elif site == 'gpc' %}
            enc.encounter_num::INTEGER AS visit_detail_id,
            enc.person_num::INTEGER AS person_id,
            -1::INTEGER AS provider_id,
        {% else %}
            enc.encounterid::INTEGER AS visit_detail_id,
            enc.patid::INTEGER AS person_id,
            enc.providerid::INTEGER AS provider_id,
        {% endif %}
        COALESCE(enctyp.source_concept_id, 0)::INTEGER AS visit_detail_concept_id,
        DATE(enc.admit_date)::DATE AS visit_detail_start_date,
        CONCAT(DATE(enc.admit_date), ' ', enc.admit_time)::TIMESTAMP AS visit_detail_start_datetime,
        DATE(COALESCE(enc.discharge_date, enc.admit_date))::DATE AS visit_detail_end_date,
        CONCAT(DATE(COALESCE(enc.discharge_date, enc.admit_date)), ' ', COALESCE(enc.discharge_time, enc.admit_time)) ::TIMESTAMP AS visit_detail_end_datetime,
        32827::INTEGER AS visit_detail_type_concept_id, -- synthea etl
        NULL::INTEGER AS care_site_id,  -- originally planned from facilityid → care_site, still NULL here
        as_map.source_concept_id::INTEGER AS admitted_from_concept_id, 
        ds_map.source_concept_id::INTEGER AS discharged_to_concept_id,
        {% if site in ['mu', 'mu-id'] %}
            lag(enc.encounterid) over(partition by enc.patid order by enc.admit_date) AS preceding_visit_detail_id,
        {% elif site == 'gpc' %}
            lag(enc.encounter_num) over(partition by enc.person_num order by enc.admit_date) AS preceding_visit_detail_id,
        {% else %}
            lag(enc.encounterid) over(partition by enc.patid order by enc.admit_date) AS preceding_visit_detail_id,
        {% endif %}
        enc.raw_enc_type::VARCHAR(50)         AS visit_detail_source_value,
        0                                     AS visit_detail_source_concept_id,
        enc.raw_admitting_source::VARCHAR(50) AS admitted_from_source_value,
        enc.raw_discharge_status::VARCHAR(50) AS discharged_to_source_value,
        null                                  AS parent_visit_detail_id,
        visit_detail_id                       AS visit_occurrence_id
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ encounter_table }} enc
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
);
