
Create or replace view OMOP_CDM.CDM.deid_observation_period AS
with
pat_visit_range as
    (
    select PERSON_ID,
        min(visit_start_date)::date as OBSERVATION_PERIOD_START_DATE,
		max(coalesce(visit_end_date,visit_start_date))::date as OBSERVATION_PERIOD_END_DATE,
		32817 as PERIOD_TYPE_CONCEPT_ID -- EHR

      from OMOP_CDM.CDM.deid_visit_occurrence
      group by PERSON_ID
)
(
SELECT
    ROW_NUMBER() over(order by observation_period_start_date,person_id)::INTEGER AS observation_period_id,
    person_id::INTEGER AS person_id,
    OBSERVATION_PERIOD_START_DATE::date AS observation_period_start_date,
    case
        when OBSERVATION_PERIOD_END_DATE::date > harvest.refresh_encounter_date then harvest.refresh_encounter_date
        else OBSERVATION_PERIOD_END_DATE::date
            end as OBSERVATION_PERIOD_END_DATE,
    PERIOD_TYPE_CONCEPT_ID::INTEGER AS period_type_concept_id

FROM pat_visit_range, pcornet_cdm.CDM.harvest
);
