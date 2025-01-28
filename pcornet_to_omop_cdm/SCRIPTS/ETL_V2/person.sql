--Person View

Create or replace view CDM.person AS
(
SELECT demographic.patid::INTEGER                                                   AS PERSON_ID,
       coalesce(gender_map.source_concept_id, 44814650)::INTEGER                    AS gender_concept_id,
       year(demographic.birth_date)::INTEGER                                        AS year_of_birth,
       month(demographic.birth_date)::INTEGER                                       AS month_of_birth,
       day(demographic.birth_date)::INTEGER                                         AS day_of_birth,
       CONCAT(date(demographic.birth_date), ' ', demographic.birth_time)::TIMESTAMP AS birth_datetime,
       death.death_date::TIMESTAMP                                                  as death_datetime,
       coalesce(race_map.source_concept_id, 44814650)::INTEGER                      AS race_concept_id,
       coalesce(ethnicity_map.source_concept_id, 44814650)::INTEGER                 AS ethnicity_concept_id,

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

FROM DEIDENTIFIED_PCORNET_CDM.CDM.DEID_DEMOGRAPHIC demographic
         left join
     CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING gender_map
     on demographic.sex = gender_map.PCORNET_VALUESET_ITEM
         and gender_map.source_concept_class = 'Gender'
         left join
     CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING ethnicity_map
     on demographic.hispanic = ethnicity_map.PCORNET_VALUESET_ITEM
         and ethnicity_map.source_concept_class = 'Hispanic'
         left join
     CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING race_map
     on demographic.race = race_map.PCORNET_VALUESET_ITEM
         and race_map.source_concept_class = 'Race'
         left join DEIDENTIFIED_PCORNET_CDM.CDM.DEID_DEATH death
                   on death.patid = demographic.patid
where year_of_birth is not null
    );



