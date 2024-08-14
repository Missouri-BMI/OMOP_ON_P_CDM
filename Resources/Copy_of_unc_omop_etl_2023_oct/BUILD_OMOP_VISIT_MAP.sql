/*
-- !!! NOT USED !!!

-- SETUP TABLE FOR ENCOUNTERID TO OMOP VISIT_ID MAPPING
-- USE VISIT_ID FROM BOTH VISIT_OCCURRENCE AND VISIT_DETAIL

select top 100 
	ENCOUNTERID,
	ROW_NUMBER() OVER(ORDER BY  encounterid) as VISIT_ID
INTO TRACS_CDM.XOMOP.OMOP_VISIT_MAP
from tracs_cdm.pcdm.encounter
where ENCOUNTERID is not null
;
alter table tracs_cdm.xomop.omop_visit_map add unique(encounterid)
;
alter table tracs_cdm.xomop.omop_visit_map add unique(visit_id)
;
alter table tracs_cdm.xomop.omop_visit_map REBUILD WITH (DATA_COMPRESSION = PAGE)
;
truncate TABLE tracs_cdm.XOMOP.OMOP_VISIT_MAP
*/
declare @MAX_ROW INT;
select @MAX_ROW =  COALESCE(max(visit_id),0) from tracs_cdm.xomop.omop_visit_map;

with
unmapped_encs as
(
	select encounterid from tracs_cdm.pcdm.encounter
	except
	select encounterid from tracs_cdm.xomop.OMOP_VISIT_MAP
)
insert into tracs_cdm.xomop.omop_visit_map
(
	encounterid,
	visit_id
)
select
	ENCOUNTERID,
	ROW_NUMBER() over(order by encounterid) + @MAX_ROW as VISIT_ID
from 
	unmapped_encs
;
