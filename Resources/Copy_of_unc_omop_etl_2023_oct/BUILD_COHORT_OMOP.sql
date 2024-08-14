---- CREATE OMOP COHORT TABLE
---- SELECT PRIMARY ENCOUNTER - USE AS VISIT_OCCURRENCE_ID
---- CREATE PERSON_ID
---- CREATE VISIT_OCCURRENCE_ID
---- CREATE VISIT_DETAIL_ID
---- note: some patients will have no encounters

drop table if exists TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
;
with
omop_encs as
(
	select distinct
		coalesce(hsp_account.prim_enc_csn_id, encounter.internal_pat_enc_csn_id) as PRIMARY_CSN_ID,
		demographic.PATID,
		encounter.ENCOUNTERID,
		demographic.INTERNAL_PAT_ID,
		encounter.INTERNAL_PAT_ENC_CSN_ID
		--hsp_account.PRIM_ENC_CSN_ID
	from
		TRACS_CDM.PCDM.DEMOGRAPHIC demographic
		left outer join TRACS_CDM.PCDM.ENCOUNTER encounter on demographic.patid = encounter.patid
		left outer join clarity.dbo.pat_enc_hsp on encounter.internal_pat_enc_csn_id = pat_enc_hsp.PAT_ENC_CSN_ID
		left outer join clarity.dbo.hsp_account on  pat_enc_hsp.HSP_ACCOUNT_ID = hsp_account.HSP_ACCOUNT_ID
	where
		demographic.BIRTH_DATE is not null
)
select
	-- OMOP
	substring( omop_encs.internal_pat_id, 2, len(omop_encs.internal_pat_id)-1 ) as PERSON_ID,
	case when omop_encs.ENCOUNTERID is null then null else rank() over( order by coalesce(cast(omop_encs.PRIMARY_CSN_ID as varchar(32)), omop_encs.ENCOUNTERID) ) end as VISIT_OCCURRENCE_ID,
	case when omop_encs.ENCOUNTERID is null then null else rank() over( order by omop_encs.ENCOUNTERID ) end as VISIT_DETAIL_ID,	
	-- CLARITY
	omop_encs.internal_pat_id as PAT_ID,			-- USE CLARITY_PAT_ID MINUS 'Z' AS OMOP PERSON ID
	omop_encs.PRIMARY_CSN_ID,
	omop_encs.internal_pat_enc_csn_id as PAT_ENC_CSN_ID,
	-- PCDM
	omop_encs.PATID,
	case 
		when omop_encs.ENCOUNTERID like 'ADS%' then omop_encs.ENCOUNTERID
		else prim_encounter.encounterid 
	end as PRIMARY_ENCOUNTERID,	
	-- changed to above 2023-07-26 prim_encounter.encounterid as PRIMARY_ENCOUNTERID,
	omop_encs.ENCOUNTERID

	
into
	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
from
	omop_encs
	left outer join TRACS_CDM.PCDM.ENCOUNTER prim_encounter on omop_encs.PRIMARY_CSN_ID = prim_encounter.internal_pat_enc_csn_id
;

ALTER TABLE TRACS_CDM.XOMOP.XSTG_COHORT_OMOP REBUILD WITH (DATA_COMPRESSION = PAGE);
create index cohort_o_person_idx on tracs_cdm.xomop.xstg_cohort_omop(person_id);
create index cohort_o_visit_idx on tracs_cdm.xomop.xstg_cohort_omop(visit_occurrence_id);
create index cohort_o_visitd_idx on tracs_cdm.xomop.xstg_cohort_omop(visit_detail_id);
;
