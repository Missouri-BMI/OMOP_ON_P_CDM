truncate table TRACS_CDM.OMOP.XSTG_OBSERVATION_PERIOD;

with
pat_visit_range as
(
	select
		PERSON_ID,
		min(visit_start_date) as OBSERVATION_PERIOD_START_DATE,
		max(coalesce(visit_end_date,visit_start_date)) as OBSERVATION_PERIOD_END_DATE,
		32817 as PERIOD_TYPE_CONCEPT_ID -- EHR
	from
		tracs_cdm.omop.xstg_visit_occurrence
	group by
		person_id
)
insert into TRACS_CDM.OMOP.XSTG_OBSERVATION_PERIOD with (tablock)
(
	OBSERVATION_PERIOD_ID,
	PERSON_ID,
	OBSERVATION_PERIOD_START_DATE,
	OBSERVATION_PERIOD_END_DATE,
	PERIOD_TYPE_CONCEPT_ID
)
select
	ROW_NUMBER() over(order by observation_period_start_date,person_id) as OBSERVATION_PERIOD_ID,
	PERSON_ID,
	OBSERVATION_PERIOD_START_DATE,
	case 
		when OBSERVATION_PERIOD_END_DATE > harvest.refresh_encounter_date then harvest.refresh_encounter_date
		else OBSERVATION_PERIOD_END_DATE
	end as OBSERVATION_PERIOD_END_DATE,
	PERIOD_TYPE_CONCEPT_ID
from
	pat_visit_range, tracs_cdm.pcdm.harvest
;
