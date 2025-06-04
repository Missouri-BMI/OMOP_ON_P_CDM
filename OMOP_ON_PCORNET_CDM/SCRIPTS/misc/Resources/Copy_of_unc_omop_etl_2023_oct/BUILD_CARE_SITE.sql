USE TRACS_CDM;
drop index if exists OMOP.XSTG_CARE_SITE.omop_care_site_src_idx;
truncate table TRACS_CDM.OMOP.XSTG_CARE_SITE;

insert into TRACS_CDM.OMOP.XSTG_CARE_SITE with (tablock)
(
	CARE_SITE_ID,
	CARE_SITE_NAME,
	PLACE_OF_SERVICE_CONCEPT_ID,
	LOCATION_ID,
	CARE_SITE_SOURCE_VALUE,
	PLACE_OF_SERVICE_SOURCE_VALUE
)
select
	ROW_NUMBER() over(order by clarity_dep.department_id) as CARE_SITE_ID,
	clarity_dep.department_name as CARE_SITE_NAME,
	0 as PLACE_OF_SERVICE_CONCEPT_ID,
	null as LOCATION_ID,
	clarity_dep.department_id as CARE_SITE_SOURCE_VALUE,
	cast(map_facility_loc.TARGET_VALUE_CODE as varchar(50)) as PLACE_OF_SERVICE_SOURCE_VALUE
from
	clarity.dbo.CLARITY_DEP
	join TRACS_CDM.XPCDM.code_mapping map_facility_loc 
		on clarity_dep.DEPARTMENT_ID = map_facility_loc.SOURCE_VALUE_CODE
		and map_facility_loc.source_table_name='V_CUBE_D_DEPARTMENT' 
		and map_facility_loc.source_column_name='DEPARTMENT_ID' 
		and map_facility_loc.target_table_name='ENCOUNTER' 
		and map_facility_loc.target_column_name='FACILITY_TYPE' 
;
create index omop_care_site_src_idx on tracs_cdm.omop.xstg_care_site(care_site_source_value)
;
