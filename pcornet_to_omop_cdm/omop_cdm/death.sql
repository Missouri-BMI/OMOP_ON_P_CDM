
CREATE or replace secure view omop_cdm.cdm.death
AS
SELECT 
d.PATID::INTEGER AS person_id,
d.death_date::DATE as death_date,
(d.death_date)::DATETIME as death_datetime,
coalesce(dt.target_concept_id,0)::INTEGER as death_type_concept_id,
coalesce(case
	when dc.death_cause_code='09' then cr_icd9.concept_id_2
	when dc.death_cause_code='10' then cr_icd10.concept_id_2
	when dc.death_cause_code='SM' then c_snomed.concept_id
	when dc.death_cause is not null and (cr_icd9.concept_id_2 is null 
											and cr_icd10.concept_id_2 is null
											and c_snomed.concept_id is null) then 0 end,
	44814650)::INTEGER as cause_concept_id,
    dc.death_cause::VARCHAR(50) as cause_source_value,
coalesce(case
	when dc.death_cause_code='09' then c_icd9.concept_id
	when dc.death_cause_code='10' then c_icd10.concept_id
	when dc.death_cause_code='SM' then c_snomed.concept_id
	when dc.death_cause is not null and (c_icd9.concept_id is null 
											and c_icd10.concept_id is null
											and c_snomed.concept_id is null) then 0 end,
	44814650)::INTEGER as cause_source_concept_id

/*coalesce (impu.source_concept_id::int, 44814650)  as death_impute_concept_id, */

FROM pcornet_cdm.cdm_2023_april.deid_death d
left join pcornet_cdm.cdm_2023_april.deid_death_cause dc on dc.patid=d.patid
/*left join pcornet_maps.pedsnet_pcornet_valueset_map impu 
	on impu.source_concept_class = 'death date impute' 
	and impu.target_concept = d.death_date_impute */
left join OMOP_CDM.CROSSWALK.p2o_death_term_xwalk dt 
	on dt.cdm_tbl='DEATH' 
	and dt.cdm_column_name='DEATH_SOURCE' 
	and dt.src_code=d.death_source
left join vocabulary.concept c_icd9 on dc.death_cause=c_icd9.concept_code
	and c_icd9.vocabulary_id='ICD9CM' and dc.death_cause_code='09'
left join vocabulary.concept c_icd10 on dc.death_cause=c_icd10.concept_code
	and c_icd10.vocabulary_id='ICD10CM' and dc.death_cause_code='10'
left join vocabulary.concept c_snomed on dc.death_cause=c_snomed.concept_code
	and c_snomed.vocabulary_id='SNOMED' and dc.death_cause_code='SM'
left join vocabulary.concept_relationship cr_icd9
	on c_icd9.concept_id = cr_icd9.concept_id_1
	and cr_icd9.relationship_id='Maps to'
left join vocabulary.concept_relationship cr_icd10
	on c_icd10.concept_id = cr_icd10.concept_id_1
	and cr_icd10.relationship_id='Maps to';


