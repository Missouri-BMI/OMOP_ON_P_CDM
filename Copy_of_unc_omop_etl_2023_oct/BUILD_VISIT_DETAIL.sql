--alter index all on TRACS_CDM.OMOP.XSTG_VISIT_DETAIL DISABLE;
truncate table TRACS_CDM.OMOP.XSTG_VISIT_DETAIL;

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
),
visit_detail as
(
	select DISTINCT
		cast(cohort.person_id as int) as person_id,
		cast(cohort.VISIT_OCCURRENCE_ID as int) as visit_occurrence_id,
		cast(cohort.VISIT_DETAIL_ID as int) as visit_detail_id,
		cast(COALESCE(map_enc_type.TARGET_CONCEPT_ID, 0) as int) as visit_detail_concept_id,
		encounter.admit_date as visit_detail_start_date,
		case
			when encounter.discharge_date is NOT NULL then encounter.discharge_date
			when encounter.enc_type in ('EI','IP') then harvest.refresh_encounter_date
			else encounter.admit_date
		end as visit_detail_end_date,
		cast(32817 as int) as visit_detail_type_concept_id,  -- EHR
        xstg_provider.PROVIDER_ID as provider_id,
		cast(cohort.care_site_id as int) as care_site_id,
		cast(coalesce(ZC_DISP_ENC_TYPE.NAME,encounter.enc_type) as varchar(100)) as visit_detail_source_value,
		cast(0 as int) as visit_detail_source_concept_id,
		cast(null as int) as admitting_source_value,
		cast(null as int) as admitting_source_concept_id,
		cast(null as int) as discharge_to_source_value,
		cast(null as int) as discharge_to_concept_id,
		cast(null as int) as preceding_visit_detail_id,
		cast(null as int) as visit_detail_parent_id
	from
		cohort
		join TRACS_CDM.PCDM.harvest harvest on 1=1
		--join tracs_cdm.omop.XSTG_VISIT_OCCURRENCE on XSTG_COHORT_OMOP.VISIT_OCCURRENCE_ID = XSTG_VISIT_OCCURRENCE.VISIT_OCCURRENCE_ID
		join tracs_cdm.pcdm.encounter on cohort.patid = encounter.patid and cohort.encounterid = encounter.encounterid
		left outer join tracs_cdm.omop.XSTG_PROVIDER on encounter.PROVIDERID = xstg_provider.PROVIDER_SOURCE_VALUE
		left outer join clarity.dbo.ZC_DISP_ENC_TYPE on encounter.raw_enc_type = ZC_DISP_ENC_TYPE.DISP_ENC_TYPE_C
		LEFT outer JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP map_enc_type 
            ON map_enc_type.SOURCE_TABLE = 'ENCOUNTER' 
            AND map_enc_type.SOURCE_COLUMN = 'ENC_TYPE'
            AND map_enc_type.SOURCE_VALUE = trim(encounter.enc_type)
)
insert into TRACS_CDM.OMOP.XSTG_VISIT_DETAIL WITH (TABLOCK)
(
	visit_detail_id,
	person_id,
	visit_detail_concept_id,
	visit_detail_start_date,
	visit_detail_start_datetime,
	visit_detail_end_date,
	visit_detail_end_datetime,
	visit_detail_type_concept_id,
	provider_id,
	care_site_id,
	visit_detail_source_value,
	visit_detail_source_concept_id,
	admitting_source_value,
	admitting_source_concept_id,
	discharge_to_source_value,
	discharge_to_concept_id,
	preceding_visit_detail_id,
	visit_detail_parent_id,
	visit_occurrence_id
)
select
	visit_detail_id,
	person_id,
	visit_detail_concept_id,
	visit_detail_start_date,
	cast(visit_detail_start_date as datetime) as visit_detail_start_datetime,
	visit_detail_end_date,
	cast(visit_detail_end_date as datetime) as visit_detail_end_datetime,
	visit_detail_type_concept_id,
	provider_id,
	care_site_id,
	visit_detail_source_value,
	visit_detail_source_concept_id,
	admitting_source_value,
	admitting_source_concept_id,
	discharge_to_source_value,
	discharge_to_concept_id,
	preceding_visit_detail_id,
	visit_detail_parent_id,
	visit_occurrence_id
from
	visit_detail
;
--ALTER INDEX ALL ON TRACS_CDM.OMOP.XSTG_VISIT_DETAIL REBUILD with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
