Create or replace view {cdm_db}.{cdm_schema}.person AS (
    WITH RankedDeath AS (
        SELECT 
            *
            , ROW_NUMBER() OVER (
                PARTITION BY patid 
                ORDER BY 
                CASE DEATH_SOURCE
                    WHEN 'D' THEN 1
                    WHEN 'N' THEN 2
                    WHEN 'L' THEN 3
                    WHEN 'S' THEN 4
                    WHEN 'T' THEN 5
                    WHEN 'DR' THEN 6
                    WHEN 'NI' THEN 7
                    WHEN 'UN' THEN 8
                    WHEN 'OT' THEN 9
                ELSE 8
                END ASC
            ) AS row_num
        FROM {pcornet_db}.{pcornet_schema}.DEID_DEATH
    )
    SELECT  
        demographic.patid::INTEGER                                                      AS PERSON_ID,
        coalesce(gender_map.source_concept_id, 44814650)::INTEGER                       AS gender_concept_id,
        year(demographic.birth_date)::INTEGER                                           AS year_of_birth,
        month(demographic.birth_date)::INTEGER                                          AS month_of_birth,
        day(demographic.birth_date)::INTEGER                                            AS day_of_birth,
        CONCAT(date(demographic.birth_date), ' ', demographic.birth_time)::TIMESTAMP    AS birth_datetime,
        death.death_date                                                                as death_datetime,
        coalesce(race_map.source_concept_id, 44814650)::INTEGER                         AS race_concept_id,
        coalesce(ethnicity_map.source_concept_id, 44814650)::INTEGER                    AS ethnicity_concept_id,
        NULL::INTEGER                                                                AS location_id,

        NULL::INTEGER                                                                AS provider_id,

        NULL::INTEGER                                                                AS care_site_id,

        NULL::VARCHAR(50)                                                            AS person_source_value,

        demographic.raw_sex::VARCHAR(50)                                             AS gender_source_value,
        44814650::INTEGER                                                            AS gender_source_concept_id,
        demographic.raw_race::VARCHAR(50)                                            AS race_source_value,
        44814650::INTEGER                                                            AS race_source_concept_id,
        demographic.raw_hispanic::VARCHAR(50)                                        AS ethnicity_source_value,
        44814650::INTEGER                                                            AS ethnicity_source_concept_id

    FROM {pcornet_db}.{pcornet_schema}.DEID_DEMOGRAPHIC as demographic
    left join
        {cdm_db}.{crosswalk}.OMOP_PCORNET_VALUESET_MAPPING gender_map
        on demographic.sex = gender_map.PCORNET_VALUESET_ITEM
            and gender_map.source_concept_class = 'Gender'
            and gender_map.pcornet_table_name = 'DEMOGRAPHIC' 
            and gender_map.pcornet_field_name = 'SEX'
    left join
        {cdm_db}.{crosswalk}.OMOP_PCORNET_VALUESET_MAPPING ethnicity_map
        on demographic.hispanic = ethnicity_map.PCORNET_VALUESET_ITEM
        and ethnicity_map.source_concept_class = 'Hispanic'
        and ethnicity_map.pcornet_table_name = 'DEMOGRAPHIC' 
        and ethnicity_map.pcornet_field_name = 'HISPANIC'
    left join
        {cdm_db}.{crosswalk}.OMOP_PCORNET_VALUESET_MAPPING race_map
        on demographic.race = race_map.PCORNET_VALUESET_ITEM
        and race_map.source_concept_class = 'Race'
        and race_map.pcornet_table_name = 'DEMOGRAPHIC' 
        and race_map.pcornet_field_name = 'RACE'
    left join (
       SELECT * FROM RankedDeath
        WHERE row_num = 1
    ) death
    on death.patid = demographic.patid
    where year_of_birth is not null
);
