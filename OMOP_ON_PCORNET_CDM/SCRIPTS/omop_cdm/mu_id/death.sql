CREATE or replace view cdm.death AS (
	WITH RankedDeath AS (
		SELECT 
			*
			, ROW_NUMBER() OVER (
				PARTITION BY patid 
				ORDER BY 
				CASE DEATH_SOURCE
					WHEN 'D' THEN 1
					WHEN 'N' THEN 2
					WHEN 'L' THEN 3
					WHEN 'S' THEN 4
					WHEN 'T' THEN 5
					WHEN 'DR' THEN 6
					WHEN 'NI' THEN 7
					WHEN 'UN' THEN 8
					WHEN 'OT' THEN 9
				ELSE 8
				END ASC
			) AS row_num
		FROM {pcornet_db}.{pcornet_schema}.DEATH
	), RankedDeathCause AS (
		SELECT 
			*
			, ROW_NUMBER() OVER (
				PARTITION BY patid 
				ORDER BY 
				CASE DEATH_CAUSE_CODE
					WHEN '10' THEN 1
					WHEN '09' THEN 2
					WHEN 'SM' THEN 3
				ELSE 4
				END ASC
			) AS row_num
		FROM {pcornet_db}.{pcornet_schema}.DEATH_CAUSE
	)
	SELECT 
		distinct d.PATID::INTEGER 																AS person_id
		, d.death_date::DATE 																	as death_date
		, (d.death_date)::DATETIME 																as death_datetime
		, coalesce(dt.source_concept_id,0)::INTEGER 											as death_type_concept_id
		, coalesce(
			case
				when
					dc.death_cause_code='09' 
				then c_icd9.concept_id
				when
					dc.death_cause_code='10' 
				then c_icd10.concept_id
				when 
					dc.death_cause_code='SM' 
				then c_snomed.concept_id
				when 
					dc.death_cause is not null 
					and c_icd9.concept_id is null
					and c_icd10.concept_id is null
					and c_snomed.concept_id is null 
				then 0 
			end
		, 44814650)::INTEGER 																	as cause_concept_id
		, dc.death_cause::VARCHAR(50) as cause_source_value
		, coalesce(
			case
				when 
					dc.death_cause_code='09' 
				then c_icd9.concept_id
				when 
					dc.death_cause_code='10'
				then c_icd10.concept_id
				when 
					dc.death_cause_code='SM' 
				then c_snomed.concept_id
				when
					dc.death_cause is not null 
					and c_icd9.concept_id is null
					and c_icd10.concept_id is null
					and c_snomed.concept_id is null
				then 0 
			end, 44814650)::INTEGER as cause_source_concept_id
		
		/*coalesce (impu.source_concept_id::int, 44814650)  as death_impute_concept_id, */
		FROM (
			SELECT
				* 
			FROM RankedDeath
			WHERE row_num = 1
		) as d
		left join (
			SELECT
				* 
			FROM RankedDeathCause
			WHERE row_num = 1
		) as dc
		on dc.patid=d.patid
		/*left join {cdm_db}.{crosswalk}.pedsnet_pcornet_valueset_map impu
		on impu.source_concept_class = 'death date impute'
		and impu.target_concept = d.death_date_impute */
		left join {cdm_db}.{crosswalk}.omop_pcornet_valueset_mapping dt
			on dt.pcornet_table_name='DEATH'
				and dt.pcornet_field_name='DEATH_SOURCE'
				and dt.pcornet_valueset_item=d.death_source
		left join {cdm_db}.{vocabulary}.concept c_icd9 
			on dc.death_cause=c_icd9.concept_code
				and c_icd9.vocabulary_id='ICD9CM' 
				and dc.death_cause_code='09'
		left join {cdm_db}.{vocabulary}.concept c_icd10 
			on dc.death_cause=c_icd10.concept_code
				and c_icd10.vocabulary_id='ICD10CM' 
				and dc.death_cause_code='10'
		left join {cdm_db}.{vocabulary}.concept c_snomed 
			on dc.death_cause=c_snomed.concept_code
				and c_snomed.vocabulary_id='SNOMED' 
				and dc.death_cause_code='SM'

);