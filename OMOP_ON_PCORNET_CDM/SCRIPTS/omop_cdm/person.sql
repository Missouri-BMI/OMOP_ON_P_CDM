CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.person AS (
    -- Rank one death record per person based on DEATH_SOURCE preference
    WITH RankedDeath AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY patid 
                ORDER BY 
                    CASE death_source
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
            ) AS row_num
        FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ death_table }}
    )
    SELECT  
        {% if site in ['mu', 'mu-id'] %}
            demographic.patid::INTEGER AS person_id,
        {% elif site == 'gpc' %}
            demographic.person_num::INTEGER AS person_id,
        {% else %}
            demographic.patid::INTEGER AS person_id,
        {% endif %}

        COALESCE(gender_map.source_concept_id, 44814650)::INTEGER AS gender_concept_id,
        EXTRACT(YEAR FROM demographic.birth_date)::INTEGER AS year_of_birth,
        EXTRACT(MONTH FROM demographic.birth_date)::INTEGER AS month_of_birth,
        EXTRACT(DAY FROM demographic.birth_date)::INTEGER AS day_of_birth,
        CONCAT(DATE(demographic.birth_date), ' ', demographic.birth_time)::TIMESTAMP AS birth_datetime,
        death.death_date AS death_datetime,
        COALESCE(race_map.source_concept_id, 44814650)::INTEGER AS race_concept_id,
        COALESCE(ethnicity_map.source_concept_id, 44814650)::INTEGER AS ethnicity_concept_id,
        NULL::INTEGER AS location_id,
        NULL::INTEGER AS provider_id,
        NULL::INTEGER AS care_site_id,
        NULL::VARCHAR(50) AS person_source_value,
        demographic.raw_sex::VARCHAR(50) AS gender_source_value,
        44814650::INTEGER AS gender_source_concept_id,
        demographic.raw_race::VARCHAR(50) AS race_source_value,
        44814650::INTEGER AS race_source_concept_id,
        demographic.raw_hispanic::VARCHAR(50) AS ethnicity_source_value,
        44814650::INTEGER AS ethnicity_source_concept_id
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ demographic_table }} AS demographic
    -- Mappings for gender, race, ethnicity
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
    -- Join to ranked death
    LEFT JOIN (
        SELECT * FROM RankedDeath WHERE row_num = 1
    ) AS death
        ON death.patid = demographic.patid
    -- Skip completely null birth records
    WHERE demographic.birth_date IS NOT NULL
);
