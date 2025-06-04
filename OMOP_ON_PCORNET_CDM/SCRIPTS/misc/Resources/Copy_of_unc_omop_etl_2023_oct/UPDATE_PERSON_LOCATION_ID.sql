use tracs_cdm;

create index xperson_id_temp on omop.xstg_person(person_id);

with 
--loc as
--(
--	select top 100 * from omop.XSTG_LOCATION_HISTORY
--	where entity_id = 2833122
--),
person_location as
(
	select PERSON_ID,LOCATION_ID from
	(
		select
			ENTITY_ID AS PERSON_ID,
			LOCATION_ID,
			ROW_NUMBER() over(partition by entity_id order by coalesce(end_date,getdate()+1) desc) as LAST_ADDR
		
		from
			--loc xstg_location_history
			omop.xstg_location_history
		where
			domain_id = 1147314 -- PERSON
	) subq
	where LAST_ADDR = 1
)
update omop.xstg_person 
set xstg_person.LOCATION_ID = person_location.location_id
from
	omop.xstg_person
	join person_location on xstg_person.PERSON_ID = person_location.PERSON_ID
;
drop index omop.xstg_person.xperson_id_temp;
