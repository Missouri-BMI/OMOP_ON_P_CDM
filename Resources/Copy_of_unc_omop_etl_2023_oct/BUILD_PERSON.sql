-- person_id using clarity Z number


--alter index all on TRACS_CDM.OMOP.XSTG_PERSON DISABLE;
truncate table TRACS_CDM.OMOP.XSTG_PERSON;

with
cohort as
(
	select distinct PATID, PERSON_ID from TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
),
omop_person as 
(
    SELECT 
     	cohort.person_id,
        cast(map_gender.TARGET_CONCEPT_ID as int) AS gender_concept_id,
        year(birth_date) AS year_of_birth,
        month(birth_date) AS month_of_birth,
        day(birth_date) AS day_of_birth,
        demographic.birth_date as birth_datetime,
        --CASE 
        --    WHEN demographic.race != '06' OR (demographic.race = '06' AND demographic.raw_race is null) 
        --        THEN cast(rx.TARGET_CONCEPT_ID as int)
        --    ELSE cast(null as int)
        --END AS race_concept_id,
		cast(map_race.TARGET_CONCEPT_ID as int) AS race_concept_id,
        cast(map_hispanic.TARGET_CONCEPT_ID as int) AS ethnicity_concept_id, 
        cast(null as int) as location_id,
        cast(null as int) as provider_id,
        cast(null as int) as care_site_id,
        cast(demographic.internal_pat_id as varchar(100)) AS person_source_value, 
        cast(demographic.sex as varchar(100)) AS gender_source_value,  
        0 as gender_source_concept_id, 
        cast(demographic.race as varchar(100)) AS race_source_value, 
        0 AS race_source_concept_id,  
        cast(demographic.hispanic as varchar(100)) AS ethnicity_source_value, 
        0 AS ethnicity_source_concept_id
    FROM 
    	cohort
    	join TRACS_CDM.PCDM.DEMOGRAPHIC demographic on cohort.patid = demographic.patid
    	left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_gender on
    		map_gender.source_table='DEMOGRAPHIC'
    		AND map_gender.source_column='SEX'
    		and demographic.sex = map_gender.source_value
		left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_hispanic on
			map_hispanic.source_table='DEMOGRAPHIC' 
			AND map_hispanic.source_column='HISPANIC'
			and demographic.hispanic = map_hispanic.source_value
		left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_race on
			map_race.source_table='DEMOGRAPHIC' 
			AND map_race.source_column='RACE'
			and demographic.race = map_race.source_value
 
)
insert into TRACS_CDM.OMOP.XSTG_PERSON with (tablock)
(
	PERSON_ID,
	GENDER_CONCEPT_ID,
	YEAR_OF_BIRTH,
	MONTH_OF_BIRTH,
	DAY_OF_BIRTH,
	BIRTH_DATETIME,
	RACE_CONCEPT_ID,
	ETHNICITY_CONCEPT_ID,
	LOCATION_ID,
	PROVIDER_ID,
	CARE_SITE_ID,
	PERSON_SOURCE_VALUE,
	GENDER_SOURCE_VALUE,
	GENDER_SOURCE_CONCEPT_ID,
	RACE_SOURCE_VALUE,
	RACE_SOURCE_CONCEPT_ID,
	ETHNICITY_SOURCE_VALUE,
	ETHNICITY_SOURCE_CONCEPT_ID
)
select
	PERSON_ID,
	GENDER_CONCEPT_ID,
	YEAR_OF_BIRTH,
	MONTH_OF_BIRTH,
	DAY_OF_BIRTH,
	BIRTH_DATETIME,
	RACE_CONCEPT_ID,
	ETHNICITY_CONCEPT_ID,
	LOCATION_ID,
	PROVIDER_ID,
	CARE_SITE_ID,
	PERSON_SOURCE_VALUE,
	GENDER_SOURCE_VALUE,
	GENDER_SOURCE_CONCEPT_ID,
	RACE_SOURCE_VALUE,
	RACE_SOURCE_CONCEPT_ID,
	ETHNICITY_SOURCE_VALUE,
	ETHNICITY_SOURCE_CONCEPT_ID
from omop_person
;
--ALTER INDEX ALL ON TRACS_CDM.OMOP.XSTG_PERSON REBUILD with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
