-- DISTINCT LOCATIONS, PATIENTS ONLY AT THIS POINT, COULD ADD CARE_SITE LOCATIONS
/******
-- care site
select top 100
upper(address_city) as CITY,
upper(zc_state.name) AS STATE,
substring(address_zip_code , 1,5) as ZIP,
upper(zc_county.name) as COUNTY
, clarity_dep.*
from 
clarity.dbo.clarity_dep
join clarity.dbo.clarity_dep_2 on clarity_dep.department_id = clarity_dep_2.department_id
left outer join clarity.dbo.zc_state on clarity_dep_2.address_state_c = zc_state.state_c
left outer join clarity.dbo.zc_county on clarity_dep_2.address_county_c = zc_county.county_c
**********/

USE TRACS_CDM;

truncate table TRACS_CDM.OMOP.XSTG_LOCATION;

insert into TRACS_CDM.OMOP.XSTG_LOCATION with (tablock)
(
	LOCATION_ID,
	ADDRESS_1,
	ADDRESS_2,
	CITY,
	STATE,
	ZIP,
	COUNTY,
	LOCATION_SOURCE_VALUE
)
select
	ROW_NUMBER() over(order by city, state, zip, county) as LOCATION_ID,
	null as ADDRESS_1,
	null as ADDRESS_2,
	CITY,
	STATE,
	ZIP,
	COUNTY,
	null as LOCATION_SOURCE_VALUE
from
(
	select distinct
		cast(upper(ADDRESS_CITY) as varchar(50)) as CITY,
		cast(upper(ADDRESS_STATE) as varchar(2)) as STATE,
		ADDRESS_ZIP5 as ZIP,
		cast(upper(ADDRESS_COUNTY) as varchar(20)) as COUNTY
	from
		--clarity.dbo.PAT_ADDR_CHNG_HX 
		pcdm.lds_address_history
	where
		address_state is not null
		or
		address_zip5 is not null
) subq;
