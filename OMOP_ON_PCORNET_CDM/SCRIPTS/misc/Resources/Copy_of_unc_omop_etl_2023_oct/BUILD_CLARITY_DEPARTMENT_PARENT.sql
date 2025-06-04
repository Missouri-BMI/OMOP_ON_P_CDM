-- CHANGE TO USE THIS LOGIC FOR PARENT:
--SELECT DISTINCT EFFECTIVE_DEPT_ID INTO #ENC_DEPARTMENTS FROM PAT_ENC WHERE EFFECTIVE_DATE_DT >= '2015-01-01';

select  --top 100
	clarity_dep.DEPARTMENT_ID,
	clarity_dep.DEPARTMENT_NAME,
	clarity_loc2.LOC_ID as loc_id_ADT,
	clarity_loc2.LOC_NAME as loc_name_ADT,
	clarity_loc_parent.LOC_ID AS LOC_ID_PARENT,
	clarity_loc_parent.LOC_NAME AS LOC_NAME_PARENT,
	coalesce(clarity_loc_parent.loc_id, clarity_loc2.loc_id) as BEST_PARENT_LOC_ID,
	coalesce(clarity_loc_parent.loc_name, clarity_loc2.loc_name) as BEST_PARENT_LOC_NAME
from
	clarity_dep
	JOIN #ENC_DEPARTMENTS pat_enc_deps on clarity_dep.DEPARTMENT_ID = pat_enc_deps.effective_dept_id
	left outer join clarity_loc ON clarity_loc.LOC_ID = clarity_dep.REV_LOC_ID
	left outer join clarity_loc clarity_loc2 ON clarity_loc2.LOC_ID=clarity_loc.ADT_PARENT_ID 
	left outer join clarity.dbo.clarity_loc clarity_loc_parent on clarity_loc.hosp_parent_loc_id = clarity_loc_parent.loc_id
-- 9 rows returned with below:
--where clarity_loc2.LOC_ID is null and clarity_loc_parent.loc_id is NOT null
-- 351 rows returned with below:
--where clarity_loc2.LOC_ID is NOT null and clarity_loc_parent.loc_id is null
-- 1 row returned below, looks like hosp_parent_loc_id result is the correct one
--where clarity_loc2.LOC_ID <> clarity_loc_parent.loc_id 
order by 1
--------------------------------------



-- starting point for care_site parent locations
-- will populate care_site and fact_relationship in the future

-- starting etl below

use clarity;

with all_deps as
(
	select --top 10
		clarity_dep.DEPARTMENT_ID,
		clarity_dep.DEPARTMENT_NAME,
		clarity_dep.EXTERNAL_NAME,
		clarity_loc_parent.LOC_ID as PARENT_LOC_ID,
		clarity_loc_parent.loc_name AS PARENT_LOC_NAME,
		clarity_loc_parent.LOCATION_ABBR AS PARANT_LOC_ABBR
	from
		clarity.dbo.clarity_dep
		left outer join clarity.dbo.clarity_loc on clarity_dep.rev_loc_id = clarity_loc.loc_id
		left outer join clarity.dbo.clarity_loc clarity_loc_parent on clarity_loc.hosp_parent_loc_id = clarity_loc_parent.loc_id
),
raw_care_site as
(
	select
		row_number() over(order by level,id) as CARE_SITE_ID,
		*
	from
	(
		select distinct 1 as LEVEL, parent_loc_id as ID, parent_loc_name as NAME, NULL as PARENT_ID from all_deps where parent_loc_name is not null
		UNION
		select distinct 2 as LEVEL, department_id as ID, coalesce(external_name,department_name) as NAME, parent_loc_id as PARENT_ID from all_deps
	) subq
)
-- parent records
select
	CARE_SITE_ID,
	NAME as CARE_SITE_NAME,
	38004515 as PLACE_OF_SERVICE_CONCEPT_ID, -- 38004515 = HOSPITAL
	null as LOCATION_ID,
	ID as CARE_SITE_SOURCE_VALUE,
	null as PLACE_OF_SERVICE_SOURCE_VALUE
from raw_care_site
where
	level = 1

