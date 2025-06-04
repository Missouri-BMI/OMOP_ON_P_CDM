-- CONDITION_OCCURRENCE
--ALTER INDEX ALL ON TRACS_CDM.OMOP.XSTG_CONDITION_OCCURRENCE DISABLE;
TRUNCATE TABLE TRACS_CDM.OMOP.XSTG_CONDITION_OCCURRENCE;

with
cohort_omop_no_enc as
(
	select distinct patid, person_id from TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
),
pcdm_condition AS 
(
    -- CONDITION
    SELECT
        XSTG_COHORT_OMOP.PERSON_ID,
        target_concept.concept_id as condition_concept_id, -- NULLs need to go to concept_id 0 in final select statement
        cast( coalesce(condition.onset_date,condition.report_date) as date) as condition_start_date, 
        cast(condition.resolve_date as date) as condition_end_date, 
--        case
--         	when condition.raw_condition_source in ('PATIENT_PROBLEM_LIST','HOSPITAL_PROBLEM_LIST') then 32840  -- EHR problem list
--			else 32817 -- EHR
--		end as condition_type_concept_id,
		coalesce(map_condition_type.target_concept_id,32817) as condition_type_concept_id,  -- EHR = 32817
        cast(0 as int) AS condition_status_concept_id,
        NULL as provider_id,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID,
        condition.condition AS condition_source_value,
        source_concept.concept_id as condition_source_concept_id,
        condition.raw_condition_source AS condition_status_source_value
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.CONDITION condition on XSTG_COHORT_OMOP.patid = condition.patid and XSTG_COHORT_OMOP.ENCOUNTERID = condition.ENCOUNTERID -- need another join for null encounters from prob list -- or condition.ENCOUNTERID is NULL)  -- need to allow for null with patient problem list
    	--pcornet_condition condition
        join TRACS_CDM.OMOP.CONCEPT source_concept
            ON source_concept.concept_code = condition.condition
            AND (
            	(source_concept.vocabulary_id = 'ICD10CM' and condition.condition_type='10')
            	OR
                (source_concept.vocabulary_id = 'ICD9CM' and condition.condition_type='09')
                )
        left outer join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 
        	and upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
        left outer join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.standard_concept='S' 
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)        
		
		-- mapping for condition_type_concept_id
		left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_condition_type
			on condition.raw_condition_source = map_condition_type.SOURCE_VALUE
			and map_condition_type.source_table = 'CONDITION'
			and map_condition_type.source_column = 'RAW_CONDITION_SOURCE'
			and map_condition_type.target_table = 'CONDITION_OCCURRENCE'
			and map_condition_type.target_column = 'CONDITION_TYPE_CONCEPT_ID'

	where
		( target_concept.domain_id is null or target_concept.domain_id = 'Condition' ) 	 -- if this maps to target concept which is NOT Condition, do not use				
),
pcdm_condition_no_enc AS 
(
    -- CONDITION
    SELECT
        cohort_omop_no_enc.PERSON_ID,
        target_concept.concept_id as condition_concept_id, -- NULLs need to go to concept_id 0 in final select statement
        cast(coalesce(condition.onset_date,condition.report_date) as date) as condition_start_date, 
        cast(condition.resolve_date as date) as condition_end_date, 
--        case
--         	when condition.raw_condition_source in ('PATIENT_PROBLEM_LIST','HOSPITAL_PROBLEM_LIST') then 32840  -- EHR problem list
--			else 32817 -- EHR
--		end as condition_type_concept_id,
		coalesce(map_condition_type.target_concept_id,32817) as condition_type_concept_id,  -- EHR = 32817
        cast(0 as int) AS condition_status_concept_id,
        cast(NULL as int) as provider_id,
        cast(null as int) as visit_occurrence_id,
		cast(null as int) as visit_detail_id,
        condition.condition AS condition_source_value,
        source_concept.concept_id as condition_source_concept_id,
        condition.raw_condition_source AS condition_status_source_value
    FROM
    	cohort_omop_no_enc
    	join TRACS_CDM.PCDM.CONDITION condition on cohort_omop_no_enc.patid = condition.patid and condition.encounterid is null
    	--pcornet_condition condition
        join TRACS_CDM.OMOP.CONCEPT source_concept
            ON source_concept.concept_code = condition.condition
            AND (
            	(source_concept.vocabulary_id = 'ICD10CM' and condition.condition_type='10')
            	OR
                (source_concept.vocabulary_id = 'ICD9CM' and condition.condition_type='09')
                )
        left outer join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 
        	and upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
        left outer join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.standard_concept='S' 
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)        
		
		-- mapping for condition_type_concept_id
		left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_condition_type
			on condition.raw_condition_source = map_condition_type.SOURCE_VALUE
			and map_condition_type.source_table = 'CONDITION'
			and map_condition_type.source_column = 'RAW_CONDITION_SOURCE'
			and map_condition_type.target_table = 'CONDITION_OCCURRENCE'
			and map_condition_type.target_column = 'CONDITION_TYPE_CONCEPT_ID'
			
	where
		( target_concept.domain_id is null or target_concept.domain_id = 'Condition' ) 	 -- if this maps to target concept which is NOT Condition, do not use				
),
pcdm_diagnosis as
(
    -- DIAGNOSIS
    SELECT 
    	XSTG_COHORT_OMOP.person_id,
        target_concept.concept_id as condition_concept_id, 
        cast(COALESCE(diagnosis.dx_date, diagnosis.admit_date) as date) as condition_start_date,
        NULL as condition_end_date, 
    --    vx.target_concept_id AS condition_type_concept_id, --already collected fro the visit_occurrence_table. / visit_occurrence.visit_source_value 
    --    43542353 condition_type_concept_id,
        coalesce(map_condition_type.target_concept_id,32817 )  as condition_type_concept_id,  -- EHR = 32817
        case
        	when diagnosis.raw_dx_source in ('HSP_ADMIT_DX','DA') and diagnosis.pdx = 'P' 	then 32901		--Primary admission diagnosis
        	when diagnosis.raw_dx_source in ('HSP_ADMIT_DX','DA') 							then 32890		--Admission diagnosis
			when diagnosis.raw_dx_source in ('HSP_FINAL_DX','DF') and diagnosis.pdx = 'P' 	then 32903		--Primary discharge diagnosis
			when diagnosis.raw_dx_source in ('HSP_FINAL_DX','DF') 							then 32896		--Discharge diagnosis
			else 0
        end	AS condition_status_concept_id,        
        NULL as provider_id,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID,
        diagnosis.dx AS condition_source_value,
        source_concept.concept_id as condition_source_concept_id,
        diagnosis.raw_dx_source AS condition_status_source_value
    FROM 
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.DIAGNOSIS diagnosis on XSTG_COHORT_OMOP.patid = diagnosis.patid and XSTG_COHORT_OMOP.ENCOUNTERID = diagnosis.ENCOUNTERID
        JOIN TRACS_CDM.OMOP.CONCEPT source_concept
            ON source_concept.concept_code = diagnosis.dx
            AND (
            	(source_concept.vocabulary_id = 'ICD10CM' and diagnosis.dx_type='10')
            	OR
                (source_concept.vocabulary_id = 'ICD9CM' and diagnosis.dx_type='09')
                )
        left outer join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP 
        	on source_concept.concept_id = concept_relationship.concept_id_1
			and upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
        left outer join TRACS_CDM.OMOP.CONCEPT target_concept 
        	on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.standard_concept='S'
			and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)  
		left outer join TRACS_CDM.xOMOP.PCDM_TO_OMOP_MAP map_condition_type
			on diagnosis.raw_dx_source = map_condition_type.SOURCE_VALUE
			and map_condition_type.source_table = 'DIAGNOSIS'
			and map_condition_type.source_column = 'RAW_DX_SOURCE'
			and map_condition_type.target_table = 'CONDITION_OCCURRENCE'
			and map_condition_type.target_column = 'CONDITION_TYPE_CONCEPT_ID'
	where
		( target_concept.domain_id is null or target_concept.domain_id = 'Condition' ) 		
),
pcdm_obs_clin as
(
    SELECT
        XSTG_COHORT_OMOP.PERSON_ID,
        target_concept.concept_id as condition_concept_id, -- NULLs need to go to concept_id 0 in final select statement
        cast(obs_clin.obsclin_start_date as date) as condition_start_date, 
        cast(obs_clin.obsclin_stop_date as date) as condition_end_date, 
--        case
--         	when condition.raw_condition_source in ('PATIENT_PROBLEM_LIST','HOSPITAL_PROBLEM_LIST') then 32840  -- EHR problem list
--			else 32817 -- EHR
--		end as condition_type_concept_id,
		32817 as condition_type_concept_id,  -- EHR = 32817
        cast(0 as int) AS condition_status_concept_id,
        NULL as provider_id,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID,
        obs_clin.obsclin_code AS condition_source_value,
        source_concept.concept_id as condition_source_concept_id,
        NULL AS condition_status_source_value
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	inner join TRACS_CDM.PCDM.OBS_CLIN obs_clin on XSTG_COHORT_OMOP.patid = obs_clin.patid and XSTG_COHORT_OMOP.encounterid = obs_clin.encounterid
    	INNER join TRACS_CDM.OMOP.CONCEPT source_concept on source_concept.concept_code = obs_clin.obsclin_code
    		and ( (obs_clin.obsclin_type = 'LC' and source_concept.vocabulary_id = 'LOINC') OR (obs_clin.obsclin_type = 'SM' and source_concept.vocabulary_id = 'SNOMED') )
        INNER join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        INNER join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id 
			and target_concept.standard_concept='S' 
			and target_concept.domain_id = 'Condition'		-- ONLY WANT CONDITION DOMAIN

)
insert into TRACS_CDM.OMOP.XSTG_CONDITION_OCCURRENCE
(
	CONDITION_OCCURRENCE_ID,
	PERSON_ID,
	CONDITION_CONCEPT_ID,
	CONDITION_START_DATE,
	CONDITION_START_DATETIME,
	CONDITION_END_DATE,
	CONDITION_END_DATETIME,
	CONDITION_TYPE_CONCEPT_ID,
	CONDITION_STATUS_CONCEPT_ID,
	STOP_REASON,
	PROVIDER_ID,
	VISIT_OCCURRENCE_ID,
	VISIT_DETAIL_ID,
	CONDITION_SOURCE_VALUE,
	CONDITION_SOURCE_CONCEPT_ID,
	CONDITION_STATUS_SOURCE_VALUE
)
select
	row_number() over(order by visit_occurrence_id) as CONDITION_OCCURRENCE_ID,
	PERSON_ID,
	cast( coalesce(condition_concept_id,0) as int) as CONDITION_CONCEPT_ID,
	CONDITION_START_DATE,
	cast(condition_start_date as date) as CONDITION_START_DATETIME,
	CONDITION_END_DATE,
	cast(condition_end_date as date) as CONDITION_END_DATETIME,
	cast(condition_type_concept_id as int) as CONDITION_TYPE_CONCEPT_ID,
	cast(condition_status_concept_id as int) as CONDITION_STATUS_CONCEPT_ID,
	cast(NULL as varchar(20)) as STOP_REASON,
	PROVIDER_ID,
	VISIT_OCCURRENCE_ID,
	VISIT_DETAIL_ID,
	cast(condition_source_value as varchar(50)) as CONDITION_SOURCE_VALUE,
	cast(condition_source_concept_id as int) as CONDITION_SOURCE_CONCEPT_ID,
	cast(condition_status_source_value as varchar(50)) as CONDITION_STATUS_SOURCE_VALUE
from
(
	select DISTINCT  * from pcdm_diagnosis
	UNION
	select DISTINCT  * from pcdm_condition
	UNION
	select DISTINCT  * from pcdm_condition_no_enc
	UNION
	select DISTINCT * from pcdm_obs_clin
) subq
;
--ALTER INDEX ALL ON TRACS_CDM.OMOP.XSTG_CONDITION_OCCURRENCE REBUILD with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
