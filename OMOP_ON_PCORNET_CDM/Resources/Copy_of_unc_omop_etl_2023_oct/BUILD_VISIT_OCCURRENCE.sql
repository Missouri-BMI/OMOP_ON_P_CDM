--alter index all on TRACS_CDM.OMOP.XSTG_VISIT_OCCURRENCE DISABLE;
truncate table TRACS_CDM.OMOP.XSTG_VISIT_OCCURRENCE;

with
cohort as
(
	select distinct
		XSTG_COHORT_OMOP.*,
		xstg_care_site.CARE_SITE_ID
	from
		TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
		left outer join clarity.dbo.pat_enc on xstg_cohort_omop.PAT_ENC_CSN_ID = pat_enc.pat_enc_csn_id
		left outer join TRACS_CDM.OMOP.XSTG_CARE_SITE on pat_enc.EFFECTIVE_DEPT_ID = XSTG_CARE_SITE.CARE_SITE_SOURCE_VALUE
	where	-- drop encounters that will be merged with primary encounter, excluded encounters will be in visit_detail
		primary_encounterid = encounterid
),
omop_visit_occurrence as 
(
-- encounter
    SELECT 
        cohort.encounterid,
        cohort.primary_encounterid,
        encounter.patid,
        encounter.enc_type,
        cohort.visit_occurrence_id,
        cohort.person_id,
        COALESCE(map_enc_type.TARGET_CONCEPT_ID, 0) as visit_concept_id,
        encounter.admit_date as visit_start_date,
		case
			when encounter.discharge_date is NOT NULL then encounter.discharge_date
			when encounter.enc_type in ('EI','IP') then harvest.refresh_encounter_date
			else encounter.admit_date
		end as visit_end_date,
        case
        	when encounter.enc_type in ('EI','IP') and encounter.DISCHARGE_DATE is null then 32220 -- still patient.  this is from the 5.3 docs. concept is non-standard, don't know why it's used this way
        	else 32817 -- this concept is visit derived from EHR type concept
        end as visit_type_concept_id, 
        xstg_provider.PROVIDER_ID as provider_id,
        cohort.care_site_id,
        cast(coalesce(ZC_DISP_ENC_TYPE.NAME,encounter.enc_type) as varchar(100)) as visit_source_value,
        cast(null as int) as visit_source_concept_id,
        cast(map_admit.TARGET_CONCEPT_ID as int) AS ADMITTING_SOURCE_CONCEPT_ID,
        cast(encounter.admitting_source as varchar(100)) AS ADMITTING_SOURCE_VALUE,
        cast(map_disch.TARGET_CONCEPT_ID as int) AS DISCHARGE_TO_CONCEPT_ID,
        cast(encounter.discharge_status as varchar(100)) AS DISCHARGE_TO_SOURCE_VALUE,
        cast(null as int) AS PRECEDING_VISIT_OCCURRENCE_ID
    FROM 
    	cohort
    	join TRACS_CDM.PCDM.harvest harvest on 1=1  -- one row for date of encounter run
    	join TRACS_CDM.PCDM.encounter encounter on cohort.patid = encounter.patid and cohort.encounterid = encounter.encounterid
		left outer join tracs_cdm.omop.XSTG_PROVIDER on encounter.PROVIDERID = xstg_provider.PROVIDER_SOURCE_VALUE
		left outer join clarity.dbo.ZC_DISP_ENC_TYPE on encounter.raw_enc_type = ZC_DISP_ENC_TYPE.DISP_ENC_TYPE_C
        LEFT outer JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_enc_type 
            ON map_enc_type.SOURCE_TABLE = 'ENCOUNTER' 
            AND map_enc_type.SOURCE_COLUMN = 'ENC_TYPE'
            AND map_enc_type.SOURCE_VALUE = trim(encounter.enc_type)
        LEFT outer JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_admit 
            ON map_admit.SOURCE_TABLE = 'ENCOUNTER' 
            AND map_admit.SOURCE_COLUMN = 'ADMITTING_SOURCE'
            AND map_admit.SOURCE_VALUE = encounter.admitting_source 
        LEFT outer JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_disch 
            ON map_disch.SOURCE_TABLE = 'ENCOUNTER' 
            AND map_disch.SOURCE_COLUMN ='DISCHARGE_STATUS'
            AND map_disch.SOURCE_VALUE = encounter.discharge_status 
)
insert into TRACS_CDM.OMOP.XSTG_VISIT_OCCURRENCE WITH (TABLOCK)
(
	VISIT_OCCURRENCE_ID,
	PERSON_ID,
	VISIT_CONCEPT_ID,
	VISIT_START_DATE,
	VISIT_START_DATETIME,
	VISIT_END_DATE,
	VISIT_END_DATETIME,
	VISIT_TYPE_CONCEPT_ID,
	PROVIDER_ID,
	CARE_SITE_ID,
	VISIT_SOURCE_VALUE,
	VISIT_SOURCE_CONCEPT_ID,
	ADMITTING_SOURCE_CONCEPT_ID,
	ADMITTING_SOURCE_VALUE,
	DISCHARGE_TO_CONCEPT_ID,
	DISCHARGE_TO_SOURCE_VALUE,
	PRECEDING_VISIT_OCCURRENCE_ID
)
 
select DISTINCT
	VISIT_OCCURRENCE_ID,
	PERSON_ID,
	VISIT_CONCEPT_ID,
	cast(visit_start_date as date) as VISIT_START_DATE,
	cast(visit_start_date as datetime) as 	VISIT_START_DATETIME,
	cast(visit_end_date as date) as VISIT_END_DATE,
	cast(visit_end_date as datetime) as VISIT_END_DATETIME,
	VISIT_TYPE_CONCEPT_ID,
	PROVIDER_ID,
	CARE_SITE_ID,
	VISIT_SOURCE_VALUE,
	VISIT_SOURCE_CONCEPT_ID,
	ADMITTING_SOURCE_CONCEPT_ID,
	ADMITTING_SOURCE_VALUE,
	DISCHARGE_TO_CONCEPT_ID,
	DISCHARGE_TO_SOURCE_VALUE,
	PRECEDING_VISIT_OCCURRENCE_ID
 from
 	omop_visit_occurrence
;
--ALTER INDEX ALL ON TRACS_CDM.OMOP.XSTG_VISIT_OCCURRENCE REBUILD with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
