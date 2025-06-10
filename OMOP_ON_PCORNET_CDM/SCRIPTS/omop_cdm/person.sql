CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.person AS (
    SELECT  
        {% if site in ['mu', 'mu-id'] %}
            demographic.patid
        {% elif site == 'gpc' %}
            demographic.person_num
        {% else %}
            demographic.patid
        {% endif %} ::INTEGER AS person_id, --person_id
        COALESCE(gender_map.source_concept_id, 44814650)::INTEGER AS gender_concept_id, -- gender_concept_id
        EXTRACT(YEAR FROM demographic.birth_date)::INTEGER AS year_of_birth, -- year_of_birth
        EXTRACT(MONTH FROM demographic.birth_date)::INTEGER AS month_of_birth, -- month_of_birth
        EXTRACT(DAY FROM demographic.birth_date)::INTEGER AS day_of_birth, -- day_of_birth
        CONCAT(DATE(demographic.birth_date), ' ', demographic.birth_time)::TIMESTAMP AS birth_datetime, -- birth_datetime
        COALESCE(race_map.source_concept_id, 44814650)::INTEGER AS race_concept_id, --race_concept_id
        COALESCE(ethnicity_map.source_concept_id, 44814650)::INTEGER AS ethnicity_concept_id,
        NULL::INTEGER AS location_id, -- location_id 
        NULL::INTEGER AS provider_id, -- provider_id
        NULL::INTEGER AS care_site_id, -- care_site_id
        NULL::VARCHAR(50) AS person_source_value, -- person_source_value
        demographic.raw_sex::VARCHAR(50) AS gender_source_value, -- gender_source_value
        0 AS gender_source_concept_id, --gender_source_concept_id
        demographic.raw_race::VARCHAR(50) AS race_source_value, -- race_source_value
        0 AS race_source_concept_id, -- race_source_concept_id
        demographic.raw_hispanic::VARCHAR(50) AS ethnicity_source_value, --ethnicity_source_value
        0 AS ethnicity_source_concept_id -- ethnicity_source_concept_id
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ demographic_table }} AS demographic
    LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping gender_map
        ON demographic.sex = gender_map.pcornet_valueset_item
        AND gender_map.source_concept_class = 'Gender'
        AND gender_map.pcornet_table_name = 'DEMOGRAPHIC'
        AND gender_map.pcornet_field_name = 'SEX'
    LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping ethnicity_map
        ON demographic.hispanic = ethnicity_map.pcornet_valueset_item
        AND ethnicity_map.source_concept_class = 'Hispanic'
        AND ethnicity_map.pcornet_table_name = 'DEMOGRAPHIC'
        AND ethnicity_map.pcornet_field_name = 'HISPANIC'
    LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping race_map
        ON demographic.race = race_map.pcornet_valueset_item
        AND race_map.source_concept_class = 'Race'
        AND race_map.pcornet_table_name = 'DEMOGRAPHIC'
        AND race_map.pcornet_field_name = 'RACE'
    WHERE demographic.birth_date IS NOT NULL -- year of birth is required
);
