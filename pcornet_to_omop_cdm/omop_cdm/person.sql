
--Person View

Create or replace secure view OMOP_CDM.CDM.person AS
(
SELECT
    demographic.patid::INTEGER AS PERSON_ID ,

    sc.target_concept_id::INTEGER AS gender_concept_id,   

    year(demographic.birth_date)::INTEGER AS year_of_birth,

    month(demographic.birth_date)::INTEGER AS month_of_birth,

    day(demographic.birth_date)::INTEGER AS day_of_birth,

    CONCAT(demographic.birth_date, ' ', demographic.birth_time)::TIMESTAMP AS birth_datetime,

    death.death_date::TIMESTAMP as death_datetime,

    rc.target_concept_id::INTEGER AS race_concept_id,

    hc.target_concept_id::INTEGER AS ethnicity_concept_id,

  --  location.location_id
    NULL::INTEGER AS location_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS provider_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS care_site_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS person_source_value,

    demographic.raw_sex::VARCHAR(50) AS gender_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS gender_source_concept_id,

    demographic.raw_race::VARCHAR(50) AS race_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS race_source_concept_id,

    demographic.raw_hispanic::VARCHAR(50) AS ethnicity_source_value ,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS ethnicity_source_concept_id

FROM pcornet_CDM.CDM_2023_APRIL.demographic
left join OMOP_CDM.CROSSWALK.GENDER_XWALK sc on demographic.SEX = sc.SRC_GENDER and sc.CDM_NAME = 'PCORnet'
left join OMOP_CDM.CROSSWALK.ETHNICITY_XWALK hc on demographic.HISPANIC = hc.SRC_ETHNICITY and hc.CDM_NAME = 'PCORnet'
left join OMOP_CDM.CROSSWALK.RACE_XWALK rc on demographic.RACE = rc.SRC_RACE and rc.CDM_NAME = 'PCORnet'
left join pcornet_cdm.cdm_2023_april.death on death.patid = demographic.patid
);
/*
left join pcornet_CDM.CDM_2023_APRIL.lds_address_history on demographic.PATID = lds_address_history.PATID and lds_address_history.ADDRESS_PERIOD_END is NULL
left join OMOP_CDM.CDM.LOCATION 
    on LOCATION.CITY = lds_address_history.address_city and LOCATION.STATE = lds_address_history.address_state
    and LOCATION.ZIP = lds_address_history.address_zip5
*/

