-- OBSERVATION
--alter index all on TRACS_CDM.OMOP.XSTG_OBSERVATION DISABLE;
truncate table TRACS_CDM.OMOP.XSTG_OBSERVATION;

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
        coalesce(target_concept.concept_id,0) as observation_concept_id,
        cast(condition.report_date as date) as observation_date, 
		32817 as observation_type_concept_id,  -- EHR = 32817
		NULL as value_as_number,
		NULL as value_as_string,
        NULL as provider_id,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID,
        condition.condition AS observation_source_value,
        source_concept.concept_id as observation_source_concept_id,
		0 as VALUE_AS_CONCEPT_ID,
		0 as QUALIFIER_CONCEPT_ID,
		0 as UNIT_CONCEPT_ID

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
        	and target_concept.domain_id = 'Observation'
        	and target_concept.standard_concept='S' 
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)     
	WHERE
		(source_concept.domain_id = 'Observation' and target_concept.domain_id is NULL)
		OR
		target_concept.domain_id = 'Observation'
),
pcdm_condition_no_enc AS 
(
    -- CONDITION
    SELECT
        cohort_omop_no_enc.PERSON_ID,
        coalesce(target_concept.concept_id,0) as observation_concept_id,
        cast(condition.report_date as date) as observation_date, 
		32817 as observation_type_concept_id,  -- EHR = 32817
		NULL as value_as_number,
		NULL as value_as_string,		
        NULL as provider_id,
        NULL as visit_occurrence_id,
		NULL as visit_detail_id,
        condition.condition AS observation_source_value,
        source_concept.concept_id as observation_source_concept_id,
		0 as VALUE_AS_CONCEPT_ID,
		0 as QUALIFIER_CONCEPT_ID,
		0 as UNIT_CONCEPT_ID
    FROM
    	cohort_omop_no_enc
    	join TRACS_CDM.PCDM.CONDITION condition on cohort_omop_no_enc.patid = condition.patid and condition.ENCOUNTERID is NULL -- need another join for null encounters from prob list -- or condition.ENCOUNTERID is NULL)  -- need to allow for null with patient problem list
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
        	and target_concept.domain_id = 'Observation'
        	and target_concept.standard_concept='S' 
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)     
	WHERE
		(source_concept.domain_id = 'Observation' and target_concept.domain_id is NULL)
		OR
		target_concept.domain_id = 'Observation'     
),
pcdm_diagnosis as
(
    -- DIAGNOSIS
    SELECT
    	XSTG_COHORT_OMOP.person_id,
        coalesce(target_concept.concept_id,0) as observation_concept_id,
        cast(COALESCE(diagnosis.dx_date, diagnosis.admit_date) as date) as observation_date,
        32817 as observation_type_concept_id,  -- EHR = 32817
		NULL as value_as_number,
		NULL as value_as_string,        
        NULL as provider_id,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID,
        diagnosis.dx AS observation_source_value,
        source_concept.concept_id as observation_source_concept_id,
		0 as VALUE_AS_CONCEPT_ID,
		0 as QUALIFIER_CONCEPT_ID,
		0 as UNIT_CONCEPT_ID
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
        left outer join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 
        	and upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
        left outer join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.domain_id = 'Observation'
        	and target_concept.standard_concept='S' 
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)     
	WHERE
		(source_concept.domain_id = 'Observation' and target_concept.domain_id is NULL)
		OR
		target_concept.domain_id = 'Observation'
),
pcdm_procedure as
(
    SELECT DISTINCT
    	XSTG_COHORT_OMOP.person_id,
    	target_concept.concept_id as observation_concept_id, 
    	procedures.px_date as observation_date,
    	32817 as observation_type_concept_id,  -- EHR = 32817
		NULL as value_as_number,
		NULL as value_as_string,    	
    	NULL as provider_id,
    	XSTG_COHORT_OMOP.visit_occurrence_id as visit_occurrence_id,
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID,
		procedures.px as observation_source_value,
		source_concept.concept_id as observation_source_concept_id,
		0 as VALUE_AS_CONCEPT_ID,
		0 as QUALIFIER_CONCEPT_ID,
		0 as UNIT_CONCEPT_ID
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.PROCEDURES procedures on XSTG_COHORT_OMOP.patid = procedures.patid and XSTG_COHORT_OMOP.encounterid = procedures.encounterid
    	JOIN TRACS_CDM.OMOP.CONCEPT source_concept
			ON source_concept.concept_code = procedures.px
			AND (
					(source_concept.vocabulary_id = 'CPT4' and procedures.px_type='CH')  -- good! CPT4 is standard vocabulary concept, but still join to second concept table 
					OR
					(source_concept.vocabulary_id = 'HCPCS' and procedures.px_type='CH')			
					OR
					(source_concept.vocabulary_id = 'ICD10PCS' and procedures.px_type='10')  -- 	no vocab mapping for this	!!!!!!!!!!
					OR
					(source_concept.vocabulary_id = 'ICD9Proc' and procedures.px_type='09')  -- good!	
				)
        join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP 
        	on source_concept.concept_id = concept_relationship.concept_id_1
			and upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
        join TRACS_CDM.OMOP.CONCEPT target_concept 
        	on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.domain_id = 'Observation'
        	and target_concept.standard_concept='S'
			and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)                                                                  
),
pcdm_lab_result_cm as
(
    SELECT
    	XSTG_COHORT_OMOP.person_id,
    	target_concept.concept_id as observation_concept_id, 
        cast(lab_result_cm.result_date as date) as observation_date, 
    	32817 as observation_type_concept_id,  -- EHR = 32817
		cast(lab_result_cm.result_num as float) as value_as_number,
		cast(lab_result_cm.result_qual as varchar(60)) as value_as_string,
		lab_result_cm.result_num,
		lab_result_cm.result_qual,
		NULL as provider_id,
        XSTG_COHORT_OMOP.visit_occurrence_id, 
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID,
        lab_result_cm.lab_loinc  as observation_source_value,
		source_concept.concept_id as observation_source_concept_id,
		
		-- VALUE AS CONCEPT ID
		-- &
		-- UNIT AS CONCEPT ID
		-- GET THESE FROM MEASURMENT
		coalesce(map_value.target_concept_id,0) as value_as_concept_id,
        --cast(u.TARGET_CONCEPT_ID as int) as unit_concept_id,
        coalesce(map_unit.target_concept_id,0) as unit_concept_id,
		0 as QUALIFIER_CONCEPT_ID
       		
    FROM 
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.LAB_RESULT_CM lab_result_cm on XSTG_COHORT_OMOP.patid = lab_result_cm.patid and XSTG_COHORT_OMOP.encounterid = lab_result_cm.encounterid
    	join TRACS_CDM.OMOP.CONCEPT source_concept on source_concept.concept_code = lab_result_cm.lab_loinc and source_concept.vocabulary_id = 'LOINC'
        join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP 
        	on source_concept.concept_id = concept_relationship.concept_id_1
			and upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
        join TRACS_CDM.OMOP.CONCEPT target_concept 
        	on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.domain_id = 'Observation'
        	and target_concept.standard_concept='S'
			and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)
			
        -- map result_unit to unit_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_unit on lab_result_cm.result_unit = map_unit.source_value
			and map_unit.source_table = 'LAB_RESULT_CM'
			and map_unit.source_column = 'RESULT_UNIT'
			
		-- map result_qual to value_as_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_value on upper(lab_result_cm.result_qual) = map_value.SOURCE_VALUE
			and map_value.source_table = 'LAB_RESULT_CM'
			and map_value.source_column = 'RESULT_QUAL'			
),
min_enc_date as
(
	select
		XSTG_COHORT_OMOP.patid,
		min(admit_date) as admit_date
	from
		TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
		join TRACS_CDM.PCDM.ENCOUNTER encounter on XSTG_COHORT_OMOP.encounterid = encounter.encounterid
	group by
		XSTG_COHORT_OMOP.patid
),
pcdm_demographic as
(
	-- PAT_PREF_LANGUAGE_SPOKEN
	SELECT DISTINCT
		cohort_omop_no_enc.person_id,
		4152283 as observation_concept_id,		-- = main spoken language
		CAST(min_enc_date.admit_date as date) as observation_date,
		32817 as observation_type_concept_id,	-- EHR
		cast(null as float) as value_as_number,
		CAST(demographic.pat_pref_language_spoken as varchar(60)) as value_as_string,
		CAST(coalesce(pcdm_to_omop_map.TARGET_CONCEPT_ID,0) as int) as value_as_concept_id,
		0 as qualifier_concept_id,
		0 as unit_concept_id,
		null as provider_id,
		cast(null as int) as visit_occurrence_id,
		cast(null as int) as visit_detail_id,
		cast('PAT_PREF_LANGUAGE_SPOKEN' as varchar(50)) AS observation_source_value,
		0 observation_source_concept_id,
		CAST(null as varchar(50)) as unit_source_value,
		CAST(null as varchar(50)) as qualifier_source_value
	from
		cohort_omop_no_enc
		join TRACS_CDM.PCDM.DEMOGRAPHIC demographic on cohort_omop_no_enc.patid = demographic.patid
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map on demographic.pat_pref_language_spoken = pcdm_to_omop_map.SOURCE_VALUE
			and pcdm_to_omop_map.source_table='DEMOGRAPHIC'
			and pcdm_to_omop_map.source_column='PAT_PREF_LANGUAGE_SPOKEN'
		join min_enc_date on demographic.patid = min_enc_date.patid
	where
		demographic.pat_pref_language_spoken <> 'NI'

	UNION
	
-- GENDER_IDENTITY
    SELECT DISTINCT
        cohort_omop_no_enc.person_id,
        4110772 as observation_concept_id,		-- gender identity finding
 		CAST(min_enc_date.admit_date as date) as observation_date,
		32817 as observation_type_concept_id,	-- EHR
		cast(null as float) as value_as_number,
		CAST(demographic.gender_identity as varchar(60)) as value_as_string,
		CAST(coalesce(pcdm_to_omop_map.TARGET_CONCEPT_ID,0) as int) as value_as_concept_id,
		0 as qualifier_concept_id,
		0 as unit_concept_id,
		null as provider_id,		
		cast(null as int) as visit_occurrence_id,
		cast(null as int) as visit_detail_id,
		cast('GENDER_IDENTITY' as varchar(50)) AS observation_source_value,
		0 observation_source_concept_id,
		CAST(null as varchar(50)) as unit_source_value,
		CAST(null as varchar(50)) as qualifier_source_value
	from
		cohort_omop_no_enc
		join TRACS_CDM.PCDM.DEMOGRAPHIC demographic on cohort_omop_no_enc.patid = demographic.patid
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map on demographic.gender_identity = pcdm_to_omop_map.SOURCE_VALUE
			and pcdm_to_omop_map.source_table='DEMOGRAPHIC'
			and pcdm_to_omop_map.source_column='GENDER_IDENTITY'
		join min_enc_date on demographic.patid = min_enc_date.patid
	where
		demographic.gender_identity <> 'NI'

	UNION
	
-- SEXUAL_ORIENTATION
    SELECT DISTINCT
        cohort_omop_no_enc.person_id,
        4283657 as observation_concept_id,		-- sexual orientation
 		CAST(min_enc_date.admit_date as date) as observation_date,
		32817 as observation_type_concept_id,	-- EHR
		cast(null as float) as value_as_number,
		CAST(demographic.sexual_orientation as varchar(60)) as value_as_string,
		CAST(coalesce(pcdm_to_omop_map.TARGET_CONCEPT_ID,0) as int) as value_as_concept_id,
		0 as qualifier_concept_id,
		0 as unit_concept_id,
		null as provider_id,	
		cast(null as int) as visit_occurrence_id,
		cast(null as int) as visit_detail_id,
		cast('SEXUAL_ORIENTATION' as varchar(50)) AS observation_source_value,
		0 observation_source_concept_id,
		CAST(null as varchar(50)) as unit_source_value,
		CAST(null as varchar(50)) as qualifier_source_value
	from
		cohort_omop_no_enc
		join TRACS_CDM.PCDM.DEMOGRAPHIC demographic on cohort_omop_no_enc.patid = demographic.patid
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map on demographic.sexual_orientation = pcdm_to_omop_map.SOURCE_VALUE
			and pcdm_to_omop_map.source_table='DEMOGRAPHIC'
			and pcdm_to_omop_map.source_column='SEXUAL_ORIENTATION'
		join min_enc_date on demographic.patid = min_enc_date.patid
	where
		demographic.sexual_orientation <> 'NI'
),
pcdm_vital as 
(
-- Smoking
	SELECT
		XSTG_COHORT_OMOP.person_id,
		4275495 AS observation_concept_id, 		-- Tobacco smoking behavior - finding
		CAST(vital.measure_date as date) AS observation_date,
		coalesce(vital_source_map.TARGET_CONCEPT_ID,32817) AS observation_type_concept_id,
		cast(null as float) as value_as_number,
		CAST(vital.smoking as varchar(60)) as value_as_string,
		CAST(coalesce(smoking_map.TARGET_CONCEPT_ID,0) as int) as value_as_concept_id,
		0 as qualifier_concept_id,
		0 as unit_concept_id,
		null as provider_id,
		XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
		cast('SMOKING' as varchar(50)) AS observation_source_value,
		0 observation_source_concept_id,
		CAST(null as varchar(50)) as unit_source_value,
		CAST(null as varchar(50)) as qualifier_source_value
	from
		TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
		join TRACS_CDM.PCDM.VITAL vital on XSTG_COHORT_OMOP.patid = vital.patid and XSTG_COHORT_OMOP.encounterid = vital.encounterid
		left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP smoking_map on vital.smoking = smoking_map.SOURCE_VALUE
			and smoking_map.SOURCE_TABLE = 'VITAL'
			and smoking_map.SOURCE_COLUMN = 'SMOKING'
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map vital_source_map on vital.vital_source = vital_source_map.source_value
			and vital_source_map.SOURCE_TABLE = 'IMMUNIZATION' -- USE IMMUNIZATION MAPPINGS HERE
			and vital_source_map.SOURCE_COLUMN = 'VX_SOURCE' 
	WHERE 
		vital.smoking NOT IN ('NI', 'UN')
	
	UNION
	
-- Tobacco
	SELECT
		XSTG_COHORT_OMOP.person_id,
		4268843 AS observation_concept_id, 		-- Tobacco use and exposure - finding
		CAST(vital.measure_date as date) AS observation_date,
		coalesce(vital_source_map.TARGET_CONCEPT_ID,32817) AS observation_type_concept_id,
		cast(null as float) as value_as_number,
		CAST(vital.tobacco as varchar(60)) as value_as_string,
		CAST(coalesce(tobacco_map.TARGET_CONCEPT_ID,0) as int) as value_as_concept_id,
		0 as qualifier_concept_id,
		0 as unit_concept_id,
		null as provider_id,
		XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
		cast('TOBACCO' as varchar(50)) AS observation_source_value,
		0 observation_source_concept_id,
		CAST(null as varchar(50)) as unit_source_value,
		CAST(null as varchar(50)) as qualifier_source_value
	from
		TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
		join TRACS_CDM.PCDM.VITAL vital on XSTG_COHORT_OMOP.patid = vital.patid and XSTG_COHORT_OMOP.encounterid = vital.encounterid
		left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP tobacco_map on vital.tobacco = tobacco_map.SOURCE_VALUE
			and tobacco_map.SOURCE_TABLE = 'VITAL'
			and tobacco_map.SOURCE_COLUMN = 'TOBACCO'
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map vital_source_map on vital.vital_source = vital_source_map.source_value
			and vital_source_map.SOURCE_TABLE = 'IMMUNIZATION' -- USE IMMUNIZATION MAPPINGS HERE
			and vital_source_map.SOURCE_COLUMN = 'VX_SOURCE' 
	WHERE 
		vital.tobacco NOT IN ('NI', 'UN')

),
pcdm_obs_gen as
(
	SELECT
		XSTG_COHORT_OMOP.person_id,
    	target_concept.concept_id as observation_concept_id, 
        cast(obs_gen.obsgen_start_date as date) as observation_date, 
    	32817 as observation_type_concept_id,  -- EHR = 32817
		cast(obs_gen.obsgen_result_num as float) as value_as_number,
		cast( coalesce(obs_gen.obsgen_result_qual,obs_gen.obsgen_result_text) as varchar(60)) as value_as_string,
		--obs_gen.obsgen_result_num,
		--obs_gen.obsgen_result_qual,
		NULL as provider_id,
        XSTG_COHORT_OMOP.visit_occurrence_id, 
		XSTG_COHORT_OMOP.VISIT_DETAIL_ID,
        obs_gen.obsgen_code  as observation_source_value,
		source_concept.concept_id as observation_source_concept_id,
		coalesce(map_value.target_concept_id,target_answer_concept.concept_id,0) as value_as_concept_id,
        coalesce(map_unit.target_concept_id,0) as unit_concept_id,
		0 as QUALIFIER_CONCEPT_ID
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.OBS_GEN obs_gen on XSTG_COHORT_OMOP.patid = obs_gen.patid and XSTG_COHORT_OMOP.encounterid = obs_gen.encounterid
    	INNER join TRACS_CDM.OMOP.CONCEPT source_concept on source_concept.concept_code = obs_gen.obsgen_code
    		and ( (obs_gen.obsgen_type = 'LC' and source_concept.vocabulary_id = 'LOINC') OR (obs_gen.obsgen_type = 'SM' and source_concept.vocabulary_id = 'SNOMED') )
        INNER join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        INNER join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id and target_concept.standard_concept='S' and target_concept.domain_id = 'Observation'
		
		-- UNIT - use lab_result_cm mappings
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_unit on obs_gen.obsgen_result_unit = map_unit.source_value
			and map_unit.source_table = 'LAB_RESULT_CM'
			and map_unit.source_column = 'RESULT_UNIT'
		
		-- OPERATOR - use lab_result_cm mappings
		-- map result_modifier to operator_concept_id
		--left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_operator on obs_gen.obsgen_result_modifier = map_operator.SOURCE_VALUE
		--	and map_operator.source_table='LAB_RESULT_CM'
		--	and map_operator.source_column='RESULT_MODIFIER'
			
		---- VALUE - use lab_result_cm mappings
		---- we currently have NO result-qual values in obs_clin of type LC or SM
		---- map result_qual to value_as_concept_id
		-- sdoh answer value is in obsgen_result_text, adding that to mapping join.  BUT, this is loinc, will need mapped through vocab
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_value on upper( coalesce(obs_gen.obsgen_result_qual, obs_gen.obsgen_result_text) ) = map_value.SOURCE_VALUE
			and obs_gen.obsgen_result_qual <> 'NI'
			and map_value.source_table = 'LAB_RESULT_CM'
			and map_value.source_column = 'RESULT_QUAL'
		-- SDOH answers are in LOINC and stored in obsgen_result_text
		left outer join tracs_cdm.omop.concept answer_concept on obs_gen.obsgen_result_text = answer_concept.concept_code
		left outer join tracs_cdm.omop.CONCEPT_RELATIONSHIP answer_relationship on answer_concept.concept_id = answer_relationship.CONCEPT_ID_1 and answer_relationship.RELATIONSHIP_ID = 'Maps to'
		left outer join tracs_cdm.omop.concept target_answer_concept on answer_relationship.CONCEPT_ID_2 = target_answer_concept.CONCEPT_ID and target_answer_concept.standard_concept='S' and target_answer_concept.domain_id = 'Meas value'
	   where
        obs_gen.obsgen_code not in (select loinc from TRACS_CDM.XOMOP.OMOP_LOINC_EXCLUSION)

)
--- **** NO VALUES IN OBS_CLIN MAP TO OBSERVATION DOMAIN ****


insert into TRACS_CDM.OMOP.XSTG_OBSERVATION WITH (TABLOCK)
(
	OBSERVATION_ID,
	PERSON_ID,
	OBSERVATION_CONCEPT_ID,
	OBSERVATION_DATE,
	OBSERVATION_DATETIME,
	OBSERVATION_TYPE_CONCEPT_ID,
	VALUE_AS_NUMBER,
	VALUE_AS_STRING,
	VALUE_AS_CONCEPT_ID,
	QUALIFIER_CONCEPT_ID,
	UNIT_CONCEPT_ID,
	PROVIDER_ID,
	VISIT_OCCURRENCE_ID,
	VISIT_DETAIL_ID,
	OBSERVATION_SOURCE_VALUE,
	OBSERVATION_SOURCE_CONCEPT_ID,
	UNIT_SOURCE_VALUE,
	QUALIFIER_SOURCE_VALUE
)
select
	row_number() over(order by visit_occurrence_id) as OBSERVATION_ID,
	PERSON_ID,
	OBSERVATION_CONCEPT_ID,
	cast(OBSERVATION_DATE as date) as OBSERVATION_DATE,
	cast(OBSERVATION_DATE as datetime) as OBSERVATION_DATETIME,
	OBSERVATION_TYPE_CONCEPT_ID,
	value_as_number as VALUE_AS_NUMBER,
	value_as_string as VALUE_AS_STRING,
	VALUE_AS_CONCEPT_ID,
	QUALIFIER_CONCEPT_ID,
	UNIT_CONCEPT_ID,
	cast(NULL as int) as PROVIDER_ID,
	VISIT_OCCURRENCE_ID,
	VISIT_DETAIL_ID,
	OBSERVATION_SOURCE_VALUE,
	OBSERVATION_SOURCE_CONCEPT_ID,
	null as UNIT_SOURCE_VALUE,
	null as QUALIFIER_SOURCE_VALUE

from
(
	select person_id, observation_concept_id, observation_date, observation_type_concept_id, value_as_number, value_as_string, visit_occurrence_id, visit_detail_id, observation_source_value, observation_source_concept_id, value_as_concept_id, qualifier_concept_id, unit_concept_id from pcdm_condition
	UNION
	select person_id, observation_concept_id, observation_date, observation_type_concept_id, value_as_number, value_as_string, visit_occurrence_id, visit_detail_id, observation_source_value, observation_source_concept_id, value_as_concept_id, qualifier_concept_id, unit_concept_id from pcdm_condition_no_enc
	UNION
	select person_id, observation_concept_id, observation_date, observation_type_concept_id, value_as_number, value_as_string, visit_occurrence_id, visit_detail_id, observation_source_value, observation_source_concept_id, value_as_concept_id, qualifier_concept_id, unit_concept_id from pcdm_diagnosis
	UNION
	select person_id, observation_concept_id, observation_date, observation_type_concept_id, value_as_number, value_as_string, visit_occurrence_id, visit_detail_id, observation_source_value, observation_source_concept_id, value_as_concept_id, qualifier_concept_id, unit_concept_id from pcdm_procedure
	UNION
	select person_id, observation_concept_id, observation_date, observation_type_concept_id, value_as_number, value_as_string, visit_occurrence_id, visit_detail_id, observation_source_value, observation_source_concept_id, value_as_concept_id, qualifier_concept_id, unit_concept_id from pcdm_lab_result_cm
	UNION
	select person_id, observation_concept_id, observation_date, observation_type_concept_id, value_as_number, value_as_string, visit_occurrence_id, visit_detail_id, observation_source_value, observation_source_concept_id, value_as_concept_id, qualifier_concept_id, unit_concept_id from pcdm_demographic
	UNION
	select person_id, observation_concept_id, observation_date, observation_type_concept_id, value_as_number, value_as_string, visit_occurrence_id, visit_detail_id, observation_source_value, observation_source_concept_id, value_as_concept_id, qualifier_concept_id, unit_concept_id from pcdm_vital
	UNION
	select person_id, observation_concept_id, observation_date, observation_type_concept_id, value_as_number, value_as_string, visit_occurrence_id, visit_detail_id, observation_source_value, observation_source_concept_id, value_as_concept_id, qualifier_concept_id, unit_concept_id from pcdm_obs_gen
	
) subq
where observation_date is not null
;
--ALTER INDEX ALL ON TRACS_CDM.OMOP.XSTG_OBSERVATION REBUILD with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
