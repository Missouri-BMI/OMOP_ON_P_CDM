--alter index all on TRACS_CDM.OMOP.XSTG_DEATH DISABLE;
truncate table TRACS_CDM.OMOP.XSTG_DEATH;


with
cohort as
(
	select distinct PATID, PERSON_ID from TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
),


omop_death as 
(
	select distinct
		cohort.person_id
		,death_date
		,cast (death_date as datetime) as death_datetime 
		,cast('32817' as numeric(18,0)) as death_type_concept_id 
		-- REMOVING DEATH CAUSE UNTIL TIME TO REVIEW
		-- JOINING TO DEATH CAUSE IS CREATING DUPLICATE PERSON_IDS, CAN ONLY HAVE ONE DEATH ROW PER PERSON
		--,coalesce(target_concept.concept_id, 0) as cause_concept_id 
		--,death_cause as cause_source_value 
		--,coalesce(source_concept.concept_id, 0) as cause_source_concept_id 
		,cast(null as int) as cause_concept_id 
		,null as cause_source_value 
		,cast(null as int) as cause_source_concept_id 

	from 
		cohort
		join TRACS_CDM.PCDM.DEATH death on cohort.patid = death.patid and death.death_date is not null
		left join TRACS_CDM.PCDM.DEATH_CAUSE death_cause on cohort.patid = death_cause.patid
		left join TRACS_CDM.OMOP.CONCEPT source_concept on source_concept.concept_code = death_cause.DEATH_CAUSE
			AND (
            		(source_concept.vocabulary_id = 'ICD10CM' and death_cause.death_cause_code='10')
            		OR
					(source_concept.vocabulary_id = 'ICD9CM' and death_cause.death_cause_code='09')
					)
		left join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1 
			AND upper(concept_relationship.RELATIONSHIP_ID) = 'MAPS TO'
		left join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id 
        		and target_concept.standard_concept='S' 
        		and (target_concept.INVALID_REASON not in ('U', 'D') OR target_concept.INVALID_REASON is null)  
        	   	
)	     
insert into TRACS_CDM.OMOP.XSTG_DEATH with (tablock)
(
 PERSON_ID,
 DEATH_DATE,
 DEATH_DATETIME,
 DEATH_TYPE_CONCEPT_ID,
 CAUSE_CONCEPT_ID,
 CAUSE_SOURCE_VALUE,
 CAUSE_SOURCE_CONCEPT_ID
 )
select
         PERSON_ID,
         DEATH_DATE,
         DEATH_DATETIME,
         DEATH_TYPE_CONCEPT_ID,
         CAUSE_CONCEPT_ID,
         CAUSE_SOURCE_VALUE,
         CAUSE_SOURCE_CONCEPT_ID
         
from omop_death
;
--ALTER INDEX ALL ON TRACS_CDM.OMOP.XSTG_DEATH REBUILD with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
