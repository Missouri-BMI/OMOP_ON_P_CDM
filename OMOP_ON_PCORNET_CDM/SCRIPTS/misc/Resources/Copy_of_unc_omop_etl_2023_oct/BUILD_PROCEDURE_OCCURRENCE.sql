--alter index all on TRACS_CDM.OMOP.XSTG_PROCEDURE_OCCURRENCE DISABLE;
truncate table TRACS_CDM.OMOP.XSTG_PROCEDURE_OCCURRENCE;

with
cohort_omop_no_enc as
(
	select distinct patid, person_id from TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
),
pcdm_procedures as 
(
    SELECT distinct
    	XSTG_COHORT_OMOP.person_id,
    	cast(coalesce(target_concept.concept_id, 0) as NUMERIC(18,0)) as procedure_concept_id,
    	procedures.px_date as procedure_date,
    	px_source_map.TARGET_CONCEPT_ID AS procedure_type_concept_id, -- 'BI' is the source type
    	0 as modifier_concept_id,
    	NULL as quantity,
    	NULL as provider_id, -- get from OMOP provider table
    	XSTG_COHORT_OMOP.visit_occurrence_id as visit_occurrence_id,
    	XSTG_COHORT_OMOP.VISIT_DETAIL_ID as visit_detail_id,
		procedures.px as procedure_source_value,
		coalesce(source_concept.concept_id, 0) as procedure_source_concept_id,
		procedures.RAW_PX_TYPE as modifier_source_value
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	JOIN TRACS_CDM.PCDM.PROCEDURES procedures ON XSTG_COHORT_OMOP.patid = procedures.patid AND XSTG_COHORT_OMOP.encounterid = procedures.encounterid
    	LEFT OUTER JOIN TRACS_CDM.OMOP.CONCEPT source_concept ON source_concept.concept_code = procedures.px
			AND (
					(source_concept.vocabulary_id = 'CPT4' and procedures.px_type='CH') 
					OR
					(source_concept.vocabulary_id = 'HCPCS' and procedures.px_type='CH')			
					OR
					(source_concept.vocabulary_id = 'ICD10PCS' and procedures.px_type='10')  
					OR
					(source_concept.vocabulary_id = 'ICD9Proc' and procedures.px_type='09')  	 			  			
				)
        LEFT OUTER JOIN TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP ON source_concept.concept_id = concept_relationship.concept_id_1 
            AND concept_relationship.RELATIONSHIP_ID = 'Maps to'
        LEFT OUTER JOIN TRACS_CDM.OMOP.CONCEPT target_concept ON concept_relationship.concept_id_2 = target_concept.concept_id 
            AND target_concept.standard_concept='S' 
            --AND target_concept.domain_id='Procedure'
            AND (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null) -- invalid_reason for CPT4 has additional value empty character other than null, U and D
		LEFT OUTER JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP px_source_map ON procedures.px_source = px_source_map.SOURCE_VALUE 
			AND px_source_map.SOURCE_TABLE = 'PROCEDURES' AND px_source_map.SOURCE_COLUMN = 'PX_SOURCE'    
	
	WHERE ( source_concept.domain_id is null AND target_concept.domain_id is null)
	      OR 
	      ( source_concept.domain_id = 'Procedure' AND (target_concept.domain_id is null OR target_concept.domain_id = 'Procedure'))
	      OR
	      ( source_concept.domain_id in ('Drug', 'Measurement', 'Observation') AND target_concept.domain_id = 'Procedure')

			                                                               
),
pcdm_condition AS 
(
    -- CONDITION
    SELECT
        XSTG_COHORT_OMOP.PERSON_ID,
        target_concept.concept_id as procedure_concept_id,
        cast(condition.report_date as date) as procedure_date, 
		32817 as procedure_type_concept_id,
		0 as modifier_concept_id,
		null as quantity,
		null as provider_id,
		XSTG_COHORT_OMOP.VISIT_OCCURRENCE_ID,
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID as visit_detail_id,
		condition.condition as procedure_source_value,
		source_concept.concept_id as procedure_source_concept_id,
		condition.condition_type as modifier_source_value
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
        join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 
        	and upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
        join TRACS_CDM.OMOP.CONCEPT target_concept 
        	on concept_relationship.concept_id_2 = target_concept.concept_id
        	and target_concept.domain_id = 'Procedure'
        	and target_concept.standard_concept='S' 
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)	 
),
pcdm_condition_no_enc AS 
(
    -- CONDITION
    SELECT
        cohort_omop_no_enc.PERSON_ID,
        target_concept.concept_id as procedure_concept_id,
        cast(condition.report_date as date) as procedure_date, 
		32817 as procedure_type_concept_id,
		0 as modifier_concept_id,
		null as quantity,
		null as provider_id,
		NULL as VISIT_OCCURRENCE_ID,
		null as visit_detail_id,
		condition.condition as procedure_source_value,
		source_concept.concept_id as procedure_source_concept_id,
		condition.condition_type as modifier_source_value
    FROM
    	cohort_omop_no_enc
    	join TRACS_CDM.PCDM.CONDITION condition on cohort_omop_no_enc.patid = condition.patid and condition.ENCOUNTERID is NULL
    	--pcornet_condition condition
        join TRACS_CDM.OMOP.CONCEPT source_concept
            ON source_concept.concept_code = condition.condition
            AND (
            	(source_concept.vocabulary_id = 'ICD10CM' and condition.condition_type='10')
            	OR
                (source_concept.vocabulary_id = 'ICD9CM' and condition.condition_type='09')
                )
        join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 
        	and upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
        join TRACS_CDM.OMOP.CONCEPT target_concept 
        	on concept_relationship.concept_id_2 = target_concept.concept_id
        	and target_concept.domain_id = 'Procedure'
        	and target_concept.standard_concept='S' 
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)	 
),
pcdm_diagnosis as
(
    -- DIAGNOSIS
    SELECT
    	XSTG_COHORT_OMOP.person_id,
    	target_concept.concept_id as procedure_concept_id,
    	cast(COALESCE(diagnosis.dx_date, diagnosis.admit_date) as date) as procedure_date,
    	32817 as procedure_type_concept_id,
    	0 as modifier_concept_id,
		null as quantity,
		null as provider_id,
		XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID as visit_detail_id,
		diagnosis.dx as procedure_source_value,
		source_concept.concept_id as procedure_source_concept_id,
		diagnosis.dx_type as modifier_source_value
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
        join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 
        	and upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
        join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.domain_id = 'Procedure'
        	and target_concept.standard_concept='S' 
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)     
),
procedure_occurrence as
(
	select
		PERSON_ID, PROCEDURE_CONCEPT_ID, PROCEDURE_DATE, PROCEDURE_TYPE_CONCEPT_ID, MODIFIER_CONCEPT_ID, QUANTITY, PROVIDER_ID, VISIT_OCCURRENCE_ID, VISIT_DETAIL_ID, PROCEDURE_SOURCE_VALUE, PROCEDURE_SOURCE_CONCEPT_ID, MODIFIER_SOURCE_VALUE
	from
		pcdm_procedures
	
	UNION
	
	select
		PERSON_ID, PROCEDURE_CONCEPT_ID, PROCEDURE_DATE, PROCEDURE_TYPE_CONCEPT_ID, MODIFIER_CONCEPT_ID, QUANTITY, PROVIDER_ID, VISIT_OCCURRENCE_ID, VISIT_DETAIL_ID, PROCEDURE_SOURCE_VALUE, PROCEDURE_SOURCE_CONCEPT_ID, MODIFIER_SOURCE_VALUE
	from
		pcdm_condition
	
	UNION
		
	select
		PERSON_ID, PROCEDURE_CONCEPT_ID, PROCEDURE_DATE, PROCEDURE_TYPE_CONCEPT_ID, MODIFIER_CONCEPT_ID, QUANTITY, PROVIDER_ID, VISIT_OCCURRENCE_ID, VISIT_DETAIL_ID, PROCEDURE_SOURCE_VALUE, PROCEDURE_SOURCE_CONCEPT_ID, MODIFIER_SOURCE_VALUE
	from
		pcdm_condition_no_enc
	
	UNION
			
	select
		PERSON_ID, PROCEDURE_CONCEPT_ID, PROCEDURE_DATE, PROCEDURE_TYPE_CONCEPT_ID, MODIFIER_CONCEPT_ID, QUANTITY, PROVIDER_ID, VISIT_OCCURRENCE_ID, VISIT_DETAIL_ID, PROCEDURE_SOURCE_VALUE, PROCEDURE_SOURCE_CONCEPT_ID, MODIFIER_SOURCE_VALUE
	from
		pcdm_diagnosis
)
insert into TRACS_CDM.OMOP.XSTG_PROCEDURE_OCCURRENCE WITH (TABLOCK)
(
	PROCEDURE_OCCURRENCE_ID,
	PERSON_ID,
	PROCEDURE_CONCEPT_ID,
	PROCEDURE_DATE,
	PROCEDURE_DATETIME,
	PROCEDURE_TYPE_CONCEPT_ID,
	MODIFIER_CONCEPT_ID,
	QUANTITY,
	PROVIDER_ID,
	VISIT_OCCURRENCE_ID,
	VISIT_DETAIL_ID,
	PROCEDURE_SOURCE_VALUE,
	PROCEDURE_SOURCE_CONCEPT_ID,
	MODIFIER_SOURCE_VALUE
)
select  
	row_number() over(order by visit_occurrence_id) as PROCEDURE_OCCURRENCE_ID,
	cast(person_id as NUMERIC(18,0)) as PERSON_ID,
	cast(procedure_concept_id as NUMERIC(18,0)) as PROCEDURE_CONCEPT_ID,
	cast(procedure_date as date) as PROCEDURE_DATE,
	cast(procedure_date as DATETIME) as PROCEDURE_DATETIME,
	cast(procedure_type_concept_id as NUMERIC(18,0)) as PROCEDURE_TYPE_CONCEPT_ID,
	cast(modifier_concept_id as varchar(50)) as MODIFIER_CONCEPT_ID,
	cast(quantity as NUMERIC(18,0)) as QUANTITY,
	cast(NULL as NUMERIC(18,0)) as PROVIDER_ID,
	cast(visit_occurrence_id as NUMERIC(18,0)) as VISIT_OCCURRENCE_ID,
	cast(visit_detail_id as NUMERIC(18,0)) as VISIT_DETAIL_ID,
	cast(procedure_source_value as varchar(50)) as PROCEDURE_SOURCE_VALUE,
	cast(procedure_source_concept_id as NUMERIC(18,0)) as PROCEDURE_SOURCE_CONCEPT_ID,
	cast(modifier_source_value as varchar(50)) as MODIFIER_SOURCE_VALUE
from
	procedure_occurrence
where
	procedure_date is not null
;
--ALTER INDEX ALL ON TRACS_CDM.PCDM.PROCEDURE_OCCURRENCE REBUILD with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
