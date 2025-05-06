--alter index all on TRACS_CDM.OMOP.XSTG_MEASUREMENT DISABLE;
truncate table TRACS_CDM.OMOP.XSTG_MEASUREMENT;

with 
meas_labs as 
(
    SELECT
    	XSTG_COHORT_OMOP.person_id,
        coalesce(target_concept.concept_id,0) as measurement_concept_id, --concept id for lab - measurement
        lab_result_cm.result_date as measurement_date, 
        coalesce(map_type.target_concept_id,0) AS measurement_type_concept_id,
        
        coalesce(map_operator.target_concept_id,0) as operator_concept_id,  -- not mapped at N3C, add mapping later, see ohdsi clinical data tables docs
        case 
        	when lab_result_cm.result_num is not null then lab_result_cm.result_num
        	else null
        end as value_as_number,
		--cast(xw3.TARGET_CONCEPT_ID as int) as value_as_concept_id,
		coalesce(map_value.target_concept_id,0) as value_as_concept_id,
        --cast(u.TARGET_CONCEPT_ID as int) as unit_concept_id,
        coalesce(map_unit.target_concept_id,0) as unit_concept_id,
        try_cast(norm_range_low as float) as range_low,
		try_cast(norm_range_high as float) as range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id, 
		XSTG_COHORT_OMOP.visit_detail_id,
        COALESCE(lab_result_cm.lab_loinc, lab_result_cm.raw_lab_code )  as measurement_source_value,
        coalesce(source_concept.concept_id,0) as measurement_source_concept_id,  -- not mapped at n3c
        lab_result_cm.result_unit as unit_source_value,
        case
        	when lab_result_cm.result_qual <> 'NI' then lab_result_cm.result_qual
        	else lab_result_cm.raw_result
        end as value_source_value
    FROM 
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.LAB_RESULT_CM lab_result_cm on XSTG_COHORT_OMOP.patid = lab_result_cm.patid and XSTG_COHORT_OMOP.encounterid = lab_result_cm.encounterid
    	-- loinc
    	left outer join TRACS_CDM.OMOP.CONCEPT source_concept on source_concept.concept_code = lab_result_cm.lab_loinc and source_concept.vocabulary_id = 'LOINC'
        left outer join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        left outer join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id and target_concept.standard_concept='S'
       
        -- map result_unit to unit_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_unit on lab_result_cm.result_unit = map_unit.source_value
			and map_unit.source_table = 'LAB_RESULT_CM'
			and map_unit.source_column = 'RESULT_UNIT'

		-- map lab_result_source to measurement_type_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_type on lab_result_cm.LAB_RESULT_SOURCE = map_type.source_value
			and map_type.source_table='LAB_RESULT_CM' 
			and map_type.source_column='LAB_RESULT_SOURCE'
			
		-- map result_modifier to operator_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_operator on lab_result_cm.result_modifier = map_operator.SOURCE_VALUE
			and map_operator.source_table='LAB_RESULT_CM'
			and map_operator.source_column='RESULT_MODIFIER'

		-- map result_qual to value_as_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_value on upper(lab_result_cm.result_qual) = map_value.SOURCE_VALUE
			and map_value.source_table = 'LAB_RESULT_CM'
			and map_value.source_column = 'RESULT_QUAL'

		-- BLOOD TYPE JOIN NOT NEEDED, BLOOD TYPE IS LOINC CODED AND STANDARD JOIN ABOVE FOR RESULT_QUAL PICKS UP ALL BLOOD TYPE LABS
    where 
		( source_concept.domain_id is null or source_concept.domain_id = 'Measurement' ) 
		and 
		( target_concept.domain_id is null or target_concept.domain_id = 'Measurement' ) 		  
		--and lab_result_cm.lab_loinc is not null
),
meas_obs_clin as (
    SELECT
    	obs_clin.OBSCLIN_RESULT_MODIFIER,
    	XSTG_COHORT_OMOP.person_id,
        target_concept.concept_id AS measurement_concept_id,
        obs_clin.obsclin_start_date AS measurement_date,
        32817 AS measurement_type_concept_id, -- EHR
        map_operator.target_concept_id AS operator_concept_id,
        cast(obs_clin.obsclin_result_num as float) AS value_as_number,
        map_value.target_concept_id AS value_as_concept_id,
        map_unit.target_concept_id  AS unit_concept_id,
        null AS range_low,
        null AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        obs_clin.obsclin_code AS measurement_source_value,
        coalesce(source_concept.concept_id, 0)  AS measurement_source_concept_id,
        obs_clin.obsclin_result_unit  AS unit_source_value,
        case
        	when obs_clin.obsclin_result_qual <> 'NI' then obs_clin.obsclin_result_qual
        	else cast(obs_clin.obsclin_result_num as varchar(50))
        end AS value_source_value
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.OBS_CLIN obs_clin on XSTG_COHORT_OMOP.patid = obs_clin.patid and XSTG_COHORT_OMOP.encounterid = obs_clin.encounterid
    	INNER join TRACS_CDM.OMOP.CONCEPT source_concept on source_concept.concept_code = obs_clin.obsclin_code
    		and ( (obs_clin.obsclin_type = 'LC' and source_concept.vocabulary_id = 'LOINC') OR (obs_clin.obsclin_type = 'SM' and source_concept.vocabulary_id = 'SNOMED') )
        INNER join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        INNER join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id and target_concept.standard_concept='S' and target_concept.domain_id = 'Measurement'
		
		-- UNIT - use lab_result_cm mappings
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_unit on obs_clin.obsclin_result_unit = map_unit.source_value
			and map_unit.source_table = 'LAB_RESULT_CM'
			and map_unit.source_column = 'RESULT_UNIT'
		
		-- OPERATOR - use lab_result_cm mappings
		-- map result_modifier to operator_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_operator on obs_clin.obsclin_result_modifier = map_operator.SOURCE_VALUE
			and map_operator.source_table='LAB_RESULT_CM'
			and map_operator.source_column='RESULT_MODIFIER'
			
		-- VALUE - use lab_result_cm mappings
		-- we currently have NO result-qual values in obs_clin of type LC or SM
		-- map result_qual to value_as_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_value on upper(obs_clin.obsclin_result_qual) = map_value.SOURCE_VALUE
			and obs_clin.obsclin_result_qual <> 'NI'
			and map_value.source_table = 'LAB_RESULT_CM'
			and map_value.source_column = 'RESULT_QUAL'
),
meas_obs_gen as
(
	SELECT
    	XSTG_COHORT_OMOP.person_id,
        target_concept.concept_id AS measurement_concept_id,
        obs_gen.obsgen_start_date AS measurement_date,
        32817 AS measurement_type_concept_id, -- EHR
        map_operator.target_concept_id AS operator_concept_id,
        cast(obs_gen.obsgen_result_num as float) AS value_as_number,
        map_value.target_concept_id AS value_as_concept_id,
        map_unit.target_concept_id  AS unit_concept_id,
        null AS range_low,
        null AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        obs_gen.obsgen_code AS measurement_source_value,
        coalesce(source_concept.concept_id, 0)  AS measurement_source_concept_id,
        obs_gen.obsgen_result_unit  AS unit_source_value,
        case
        	when obs_gen.obsgen_result_qual <> 'NI' then obs_gen.obsgen_result_qual
        	else cast(obs_gen.obsgen_result_num as varchar(50))
        end AS value_source_value
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.OBS_GEN obs_gen on XSTG_COHORT_OMOP.patid = obs_gen.patid and XSTG_COHORT_OMOP.encounterid = obs_gen.encounterid
    	INNER join TRACS_CDM.OMOP.CONCEPT source_concept on source_concept.concept_code = obs_gen.obsgen_code
    		and ( (obs_gen.obsgen_type = 'LC' and source_concept.vocabulary_id = 'LOINC') OR (obs_gen.obsgen_type = 'SM' and source_concept.vocabulary_id = 'SNOMED') )
        INNER join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        INNER join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id and target_concept.standard_concept='S' and target_concept.domain_id = 'Measurement'
		
		-- UNIT - use lab_result_cm mappings
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_unit on obs_gen.obsgen_result_unit = map_unit.source_value
			and map_unit.source_table = 'LAB_RESULT_CM'
			and map_unit.source_column = 'RESULT_UNIT'
		
		-- OPERATOR - use lab_result_cm mappings
		-- map result_modifier to operator_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_operator on obs_gen.obsgen_result_modifier = map_operator.SOURCE_VALUE
			and map_operator.source_table='LAB_RESULT_CM'
			and map_operator.source_column='RESULT_MODIFIER'
			
		-- VALUE - use lab_result_cm mappings
		-- we currently have NO result-qual values in obs_clin of type LC or SM
		-- map result_qual to value_as_concept_id
		left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_value on upper(obs_gen.obsgen_result_qual) = map_value.SOURCE_VALUE
			and obs_gen.obsgen_result_qual <> 'NI'
			and map_value.source_table = 'LAB_RESULT_CM'
			and map_value.source_column = 'RESULT_QUAL'
	where
		obs_gen.obsgen_code not in (select loinc from TRACS_CDM.XOMOP.OMOP_LOINC_EXCLUSION)

),
meas_vital as (
	-- Height

    SELECT
        XSTG_COHORT_OMOP.person_id, 
        4177340 AS measurement_concept_id, --concept id for Height, from notes
        vital.measure_date AS measurement_date,
        32817 AS measurement_type_concept_id, -- EHR
        cast(null as int) AS operator_concept_id,
        cast(vital.ht as float) AS value_as_number, --Height (in inches) Weight (in pounds) Diastolic blood pressure (in mmHg)
        cast(null as int) AS value_as_concept_id,
        9327 AS unit_concept_id,
        cast(null as float) AS range_low,
        cast(null as float) AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        'Height in inches' AS measurement_source_value,
        0 AS measurement_source_concept_id,
        'Inches' AS unit_source_value,
        cast(vital.ht as varchar(50)) AS value_source_value
    FROM 
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.VITAL vital on XSTG_COHORT_OMOP.patid = vital.patid and XSTG_COHORT_OMOP.encounterid = vital.encounterid
    WHERE 
    	vital.ht IS NOT NULL

	UNION

	---- Weight
    SELECT
        XSTG_COHORT_OMOP.person_id, 
        4099154 AS measurement_concept_id,
        vital.measure_date AS measurement_date,
        32817 AS measurement_type_concept_id, -- EHR
        cast(null as int) AS operator_concept_id,
        cast(vital.wt as float) AS value_as_number, 
        cast(null as int) AS value_as_concept_id,
        8739 AS unit_concept_id,
        cast(null as float) AS range_low,
        cast(null as float) AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        'Weight in pounds' AS measurement_source_value,
        0 AS measurement_source_concept_id,
        'Pounds' AS unit_source_value,
        cast(vital.wt as varchar(50)) AS value_source_value
    FROM 
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.VITAL vital on XSTG_COHORT_OMOP.patid = vital.patid and XSTG_COHORT_OMOP.encounterid = vital.encounterid
    WHERE 
    	vital.wt IS NOT NULL

	UNION ALL

	---- Diastolic BP
    SELECT
        XSTG_COHORT_OMOP.person_id, 
        coalesce(map_concept.TARGET_CONCEPT_ID,3012888) AS measurement_concept_id, -- concept diastolic BP
        vital.measure_date AS measurement_date,
        32817 AS measurement_type_concept_id, -- EHR
        cast(null as int) AS operator_concept_id,
        cast(vital.diastolic as float) AS value_as_number, 
        cast(null as int) AS value_as_concept_id,
        8876 AS unit_concept_id,
        cast(null as float) AS range_low,
        cast(null as float) AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        concat('diastolic:',coalesce(vital.BP_POSITION,'')) AS measurement_source_value,
        0 AS measurement_source_concept_id,
        'millimeter mercury column' AS unit_source_value,
        cast(vital.diastolic as varchar(50)) AS value_source_value
    FROM 
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.VITAL vital on XSTG_COHORT_OMOP.patid = vital.patid and XSTG_COHORT_OMOP.encounterid = vital.encounterid
    	-- concept using bp-position
    	left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_concept on vital.BP_POSITION = map_concept.SOURCE_VALUE
    		and map_concept.source_table = 'VITAL' 
    		and map_concept.source_column = 'DIASTOLIC_BP_POSITION'
    WHERE 
    	vital.diastolic IS NOT NULL


	UNION ALL

	---- Systolic BP
    SELECT
        XSTG_COHORT_OMOP.person_id, 
        coalesce(map_concept.TARGET_CONCEPT_ID,3004249) AS measurement_concept_id,  -- concept systolic BP
        vital.measure_date AS measurement_date,
        32817 AS measurement_type_concept_id, -- EHR
        cast(null as int) AS operator_concept_id,
        cast(vital.systolic as float) AS value_as_number, 
        cast(null as int) AS value_as_concept_id,
        8876 AS unit_concept_id,
        cast(null as float) AS range_low,
        cast(null as float) AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        concat('systolic:', coalesce(vital.BP_POSITION,'')) AS measurement_source_value,
        0 AS measurement_source_concept_id,
        'millimeter mercury column' AS unit_source_value,
        cast(vital.systolic as varchar(50)) AS value_source_value
    FROM 
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.VITAL vital on XSTG_COHORT_OMOP.patid = vital.patid and XSTG_COHORT_OMOP.encounterid = vital.encounterid
    	-- concept using bp-position
    	left outer join TRACS_CDM.XOMOP.pcdm_to_omop_map map_concept on vital.BP_POSITION = map_concept.SOURCE_VALUE
    		and map_concept.source_table = 'VITAL' 
    		and map_concept.source_column = 'SYSTOLIC_BP_POSITION'  
    WHERE 
    	vital.systolic IS NOT NULL


	UNION ALL

	---- Original BMI
    SELECT
        XSTG_COHORT_OMOP.person_id, 
        4245997 AS measurement_concept_id,
        vital.measure_date AS measurement_date,
        32817 AS measurement_type_concept_id, -- EHR
        cast(null as int) AS operator_concept_id,
        cast(vital.original_bmi as float) AS value_as_number, 
        cast(null as int) AS value_as_concept_id,
        0 AS unit_concept_id,
        cast(null as float) AS range_low,
        cast(null as float) AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        'Original BMI' AS measurement_source_value,
        0 AS measurement_source_concept_id,
        null AS unit_source_value,
        cast(vital.original_bmi as varchar(50)) AS value_source_value
    FROM 
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.VITAL vital on XSTG_COHORT_OMOP.patid = vital.patid and XSTG_COHORT_OMOP.encounterid = vital.encounterid
    WHERE 
    	vital.original_bmi IS NOT NULL

),
meas_procedures as
(
    SELECT
    	XSTG_COHORT_OMOP.person_id,
    	target_concept.concept_id as measurement_concept_id,
    	procedures.px_date as measurement_date,
    	map_type.TARGET_CONCEPT_ID AS measurement_type_concept_id,
        cast(null as int) AS operator_concept_id,
        cast(null as float) AS value_as_number, 
        cast(null as int) AS value_as_concept_id,
        cast(null as int) AS unit_concept_id,
        cast(null as float) AS range_low,
        cast(null as float) AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        cast(procedures.px as varchar(50)) AS measurement_source_value,
        coalesce(source_concept.concept_id, 0) as measurement_source_concept_id,
        cast(null as varchar(50)) AS unit_source_value,
        cast(null as varchar(50)) AS value_source_value    	
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	JOIN TRACS_CDM.PCDM.PROCEDURES procedures ON XSTG_COHORT_OMOP.patid = procedures.patid AND XSTG_COHORT_OMOP.encounterid = procedures.encounterid
    	-- INNER JOIN TO VOCAB, ONLY WANT STANDARD MEASUREMENTS
    	JOIN TRACS_CDM.OMOP.CONCEPT source_concept ON source_concept.concept_code = procedures.px
			AND (
					(source_concept.vocabulary_id = 'CPT4' and procedures.px_type='CH') 
					OR
					(source_concept.vocabulary_id = 'HCPCS' and procedures.px_type='CH')			
					OR
					(source_concept.vocabulary_id = 'ICD10PCS' and procedures.px_type='10')  
					OR
					(source_concept.vocabulary_id = 'ICD9Proc' and procedures.px_type='09')  	 			  			
				)
        JOIN TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP ON source_concept.concept_id = concept_relationship.concept_id_1 
            AND concept_relationship.RELATIONSHIP_ID = 'Maps to'
        JOIN TRACS_CDM.OMOP.CONCEPT target_concept ON concept_relationship.concept_id_2 = target_concept.concept_id 
            AND target_concept.standard_concept='S' 
            AND target_concept.domain_id='Measurement'
            AND (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null) -- invalid_reason for CPT4 has additional value empty character other than null, U and D
		-- SOURCE -> TYPE
		LEFT OUTER JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_type ON procedures.px_source = map_type.SOURCE_VALUE 
			AND map_type.SOURCE_TABLE = 'PROCEDURES' AND map_type.SOURCE_COLUMN = 'PX_SOURCE'    
),
meas_diagnosis as
(

    SELECT
    	XSTG_COHORT_OMOP.person_id,
    	target_concept.concept_id as measurement_concept_id,
    	COALESCE(diagnosis.dx_date, diagnosis.admit_date) as measurement_date,
    	coalesce(map_condition_type.target_concept_id,32817 )  as measurement_type_concept_id,  -- EHR = 32817
        cast(null as int) AS operator_concept_id,
        cast(null as float) AS value_as_number, 
        cast(null as int) AS value_as_concept_id,
        cast(null as int) AS unit_concept_id,
        cast(null as float) AS range_low,
        cast(null as float) AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        cast(diagnosis.dx as varchar(50)) AS measurement_source_value,
        coalesce(source_concept.concept_id, 0) as measurement_source_concept_id,
        cast(null as varchar(50)) AS unit_source_value,
        cast(null as varchar(50)) AS value_source_value    
    FROM 
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.DIAGNOSIS diagnosis on XSTG_COHORT_OMOP.patid = diagnosis.patid and XSTG_COHORT_OMOP.ENCOUNTERID = diagnosis.ENCOUNTERID
    	-- INNER JOIN, ONLY WANT STANDARD MEASUREMENTS
        JOIN TRACS_CDM.OMOP.CONCEPT source_concept
            ON source_concept.concept_code = diagnosis.dx
            AND (
            	(source_concept.vocabulary_id = 'ICD10CM' and diagnosis.dx_type='10')
            	OR
                (source_concept.vocabulary_id = 'ICD9CM' and diagnosis.dx_type='09')
                )
        join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP 
        	on source_concept.concept_id = concept_relationship.concept_id_1
			and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        join TRACS_CDM.OMOP.CONCEPT target_concept 
        	on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.standard_concept='S'
        	and target_concept.domain_id = 'Measurement'
			and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)  

		left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_condition_type
			on diagnosis.raw_dx_source = map_condition_type.SOURCE_VALUE
			and map_condition_type.source_table = 'DIAGNOSIS'
			and map_condition_type.source_column = 'RAW_DX_SOURCE'
			and map_condition_type.target_table = 'CONDITION_OCCURRENCE'
			and map_condition_type.target_column = 'CONDITION_TYPE_CONCEPT_ID'
),
cohort_omop_no_enc as
(
	select distinct patid, person_id from TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
),
meas_condition AS 
(
    -- CONDITION
    SELECT
    	XSTG_COHORT_OMOP.person_id,
    	target_concept.concept_id as measurement_concept_id,
    	condition.report_date as measurement_date,
    	coalesce(map_condition_type.target_concept_id,32817 )  as measurement_type_concept_id,  -- EHR = 32817
        cast(null as int) AS operator_concept_id,
        cast(null as float) AS value_as_number, 
        cast(null as int) AS value_as_concept_id,
        cast(null as int) AS unit_concept_id,
        cast(null as float) AS range_low,
        cast(null as float) AS range_high,
        XSTG_COHORT_OMOP.visit_occurrence_id,
		XSTG_COHORT_OMOP.visit_detail_id,
        cast(condition.condition as varchar(50)) AS measurement_source_value,
        coalesce(source_concept.concept_id, 0) as measurement_source_concept_id,
        cast(null as varchar(50)) AS unit_source_value,
        cast(null as varchar(50)) AS value_source_value     
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.CONDITION condition on XSTG_COHORT_OMOP.patid = condition.patid and XSTG_COHORT_OMOP.ENCOUNTERID = condition.ENCOUNTERID -- need another join for null encounters from prob list -- or condition.ENCOUNTERID is NULL)  -- need to allow for null with patient problem list
    	-- INNER JOIN, ONLY WANT STANDARD MEASURMENTS
        join TRACS_CDM.OMOP.CONCEPT source_concept
            ON source_concept.concept_code = condition.condition
            AND (
            	(source_concept.vocabulary_id = 'ICD10CM' and condition.condition_type='10')
            	OR
                (source_concept.vocabulary_id = 'ICD9CM' and condition.condition_type='09')
                )
        join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 
        	and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.standard_concept='S' 
        	and target_concept.domain_id='Measurement'
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)        
		
		-- mapping for condition_type_concept_id
		left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_condition_type
			on condition.raw_condition_source = map_condition_type.SOURCE_VALUE
			and map_condition_type.source_table = 'CONDITION'
			and map_condition_type.source_column = 'RAW_CONDITION_SOURCE'
			and map_condition_type.target_table = 'CONDITION_OCCURRENCE'
			and map_condition_type.target_column = 'CONDITION_TYPE_CONCEPT_ID'
),
meas_condition_no_enc AS 
(
    -- CONDITION
    SELECT
    	cohort_omop_no_enc.person_id,
    	target_concept.concept_id as measurement_concept_id,
    	condition.report_date as measurement_date,
    	coalesce(map_condition_type.target_concept_id,32817 )  as measurement_type_concept_id,  -- EHR = 32817
        cast(null as int) AS operator_concept_id,
        cast(null as float) AS value_as_number, 
        cast(null as int) AS value_as_concept_id,
        cast(null as int) AS unit_concept_id,
        cast(null as float) AS range_low,
        cast(null as float) AS range_high,
        cast(null as int) as visit_occurrence_id,
		cast(null as int) as visit_detail_id,
        cast(condition.condition as varchar(50)) AS measurement_source_value,
        coalesce(source_concept.concept_id, 0) as measurement_source_concept_id,
        cast(null as varchar(50)) AS unit_source_value,
        cast(null as varchar(50)) AS value_source_value    
    FROM
    	cohort_omop_no_enc
    	join TRACS_CDM.PCDM.CONDITION condition on cohort_omop_no_enc.patid = condition.patid and condition.encounterid is null
    	
    	-- INNER JOIN, ONLY WANT STANDARD MEASURMENTS
        join TRACS_CDM.OMOP.CONCEPT source_concept
            ON source_concept.concept_code = condition.condition
            AND (
            	(source_concept.vocabulary_id = 'ICD10CM' and condition.condition_type='10')
            	OR
                (source_concept.vocabulary_id = 'ICD9CM' and condition.condition_type='09')
                )
        join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 
        	and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id 
        	and target_concept.standard_concept='S' 
        	and target_concept.domain_id='Measurement'
        	and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)              
		
		-- mapping for condition_type_concept_id
		left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_condition_type
			on condition.raw_condition_source = map_condition_type.SOURCE_VALUE
			and map_condition_type.source_table = 'CONDITION'
			and map_condition_type.source_column = 'RAW_CONDITION_SOURCE'
			and map_condition_type.target_table = 'CONDITION_OCCURRENCE'
			and map_condition_type.target_column = 'CONDITION_TYPE_CONCEPT_ID'
)

insert into TRACS_CDM.OMOP.XSTG_MEASUREMENT WITH (TABLOCK)
(
	MEASUREMENT_ID,
	PERSON_ID,
	MEASUREMENT_CONCEPT_ID,
	MEASUREMENT_DATE,
	MEASUREMENT_DATETIME,
	MEASUREMENT_TIME,
	MEASUREMENT_TYPE_CONCEPT_ID,
	OPERATOR_CONCEPT_ID,
	VALUE_AS_NUMBER,
	VALUE_AS_CONCEPT_ID,
	UNIT_CONCEPT_ID,
	RANGE_LOW,
	RANGE_HIGH,
	PROVIDER_ID,
	VISIT_OCCURRENCE_ID,
	VISIT_DETAIL_ID,
	MEASUREMENT_SOURCE_VALUE,
	MEASUREMENT_SOURCE_CONCEPT_ID,
	UNIT_SOURCE_VALUE,
	VALUE_SOURCE_VALUE
)
select 
	row_number() over(order by visit_occurrence_id) as MEASUREMENT_ID,
	cast(PERSON_ID as int) as person_id,
	cast(MEASUREMENT_CONCEPT_ID as int) as measurement_concept_id,
	cast(measurement_date as date) as measurement_date,
	cast(measurement_date as datetime) as measurement_datetime,
	convert(varchar, measurement_date, 108) as measurement_time,
	cast( measurement_type_concept_id as int) as measurement_type_concept_id,
	coalesce(operator_concept_id,0) as operator_concept_id,
	cast( value_as_number as float) as value_as_number,
	coalesce(value_as_concept_id,0) as value_as_concept_id,
	coalesce(unit_concept_id,0) as unit_concept_id,
	cast( range_low as float) as range_low,
	cast( range_high as float) as range_high,
	cast( null as int) as provider_id,
	cast( visit_occurrence_id as int) as visit_occurrence_id,
	cast( VISIT_DETAIL_ID as int) as visit_detail_id,
	cast( measurement_source_value as varchar(50)) as measurement_source_value,
	cast( measurement_source_concept_id as int) as measurement_source_concept_id,
	cast( unit_source_value as varchar(50)) as unit_source_value,
	cast( value_source_value as varchar(50)) as value_source_value
	
from 
	(
		select distinct
			person_id, measurement_concept_id, measurement_date, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high, visit_occurrence_id, visit_detail_id, measurement_source_value, measurement_source_concept_id, unit_source_value, value_source_value
		from meas_labs
		
		UNION
		
		select distinct
			person_id, measurement_concept_id, measurement_date, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high, visit_occurrence_id, visit_detail_id, measurement_source_value, measurement_source_concept_id, unit_source_value, value_source_value
		from meas_obs_clin
		
		UNION
		
		select distinct
			person_id, measurement_concept_id, measurement_date, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high, visit_occurrence_id, visit_detail_id, measurement_source_value, measurement_source_concept_id, unit_source_value, value_source_value
		from meas_obs_gen
		
		UNION
		
		select distinct
			person_id, measurement_concept_id, measurement_date, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high, visit_occurrence_id, visit_detail_id, measurement_source_value, measurement_source_concept_id, unit_source_value, value_source_value
		from meas_vital
		
		UNION
		
		select distinct
			person_id, measurement_concept_id, measurement_date, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high, visit_occurrence_id, visit_detail_id, measurement_source_value, measurement_source_concept_id, unit_source_value, value_source_value
		from meas_procedures
		
		UNION
		
		select distinct
			person_id, measurement_concept_id, measurement_date, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high, visit_occurrence_id, visit_detail_id, measurement_source_value, measurement_source_concept_id, unit_source_value, value_source_value
		from meas_diagnosis
		
		UNION
		
		select distinct
			person_id, measurement_concept_id, measurement_date, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high, visit_occurrence_id, visit_detail_id, measurement_source_value, measurement_source_concept_id, unit_source_value, value_source_value
		from meas_condition
		
		UNION
		
		select distinct
			person_id, measurement_concept_id, measurement_date, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high, visit_occurrence_id, visit_detail_id, measurement_source_value, measurement_source_concept_id, unit_source_value, value_source_value
		from meas_condition_no_enc

	) union_meas
;
--ALTER INDEX ALL ON TRACS_CDM.OMOP.XSTG_MEASUREMENT REBUILD with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
