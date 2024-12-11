--TODO: all columns are null
create or replace view CDM.OBSERVATION_PERIOD(
	OBSERVATION_PERIOD_ID,
	PERSON_ID,
	OBSERVATION_PERIOD_START_DATE,
	OBSERVATION_PERIOD_END_DATE,
	PERIOD_TYPE_CONCEPT_ID
) as
(
SELECT
   --  ATLAS_MU_DEV.CDM.observation_period_id_seq.nextval::INTEGER AS observation_period_id,
   ROW_NUMBER() OVER (ORDER BY enrl.patid) ::INTEGER AS observation_period_id,
 patid::INTEGER AS person_id,

 ENR_START_DATE::date AS observation_period_start_date,

ENR_END_DATE::date AS observation_period_end_date,

 44814722::INTEGER AS period_type_concept_id

FROM DEIDENTIFIED_PCORNET_CDM.CDM.deid_enrollment enrl
);