USE TRACS_CDM;
drop index if exists OMOP.XSTG_PROVIDER.omop_provider_src_idx;
truncate table TRACS_CDM.OMOP.XSTG_PROVIDER;

insert into TRACS_CDM.OMOP.XSTG_PROVIDER with (tablock)
(
	PROVIDER_ID,
	PROVIDER_NAME,
	NPI,
	DEA,
	SPECIALTY_CONCEPT_ID,
	CARE_SITE_ID,
	YEAR_OF_BIRTH,
	GENDER_CONCEPT_ID,
	PROVIDER_SOURCE_VALUE,
	SPECIALTY_SOURCE_VALUE,
	SPECIALTY_SOURCE_CONCEPT_ID,
	GENDER_SOURCE_VALUE,
	GENDER_SOURCE_CONCEPT_ID
)
select
	row_number() over(order by provider.providerid) as PROVIDER_ID,
	NULL as PROVIDER_NAME,
	provider_npi as NPI,
	NULL as DEA,
	target_concept.concept_id as SPECIALTY_CONCEPT_ID,
	NULL as CARE_SITE_ID,
	NULL as YEAR_OF_BIRTH,
	gender_map.target_concept_id as GENDER_CONCEPT_ID,
	providerid as PROVIDER_SOURCE_VALUE,
	specialty_concept.CONCEPT_CODE as SPECIALTY_SOURCE_VALUE,
	specialty_concept.CONCEPT_ID as SPECIALTY_SOURCE_CONCEPT_ID,
	provider_sex as GENDER_SOURCE_VALUE,
	0 as GENDER_SOURCE_CONCEPT_ID
from
	TRACS_CDM.PCDM.PROVIDER
	-- GENDER CONCEPT:  USE DEMOGRAPHIC SEX TO MAP
	--SOURCE_TABLE	SOURCE_COLUMN	SOURCE_VALUE	SOURCE_DESCRIPTION	TARGET_TABLE	TARGET_COLUMN	TARGET_CONCEPT_ID_CHAR	COMMENTS	TARGET_CONCEPT_ID
	--DEMOGRAPHIC	SEX	F	NULL	PERSON	GENDER_CONCEPT_ID	8532	From N3C	8532
	left outer join TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP gender_map on provider.provider_sex = gender_map.SOURCE_VALUE
		and gender_map.source_table='DEMOGRAPHIC'
		and gender_map.SOURCE_COLUMN='SEX'
		and gender_map.target_table='PERSON'
		and gender_map.target_column='GENDER_CONCEPT_ID'
	left outer join TRACS_CDM.OMOP.CONCEPT specialty_concept on provider.PROVIDER_SPECIALTY_PRIMARY = specialty_concept.CONCEPT_CODE and specialty_concept.VOCABULARY_ID='NUCC' and specialty_concept.DOMAIN_ID='Provider'
	left outer join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on specialty_concept.concept_id = concept_relationship.CONCEPT_ID_1 and CONCEPT_RELATIONSHIP.RELATIONSHIP_ID = 'Maps to'
	left outer join TRACS_CDM.OMOP.CONCEPT target_concept on CONCEPT_RELATIONSHIP.CONCEPT_ID_2 = target_concept.CONCEPT_ID and target_concept.STANDARD_CONCEPT='S'
;
create index omop_provider_src_idx on tracs_cdm.omop.xstg_provider(provider_source_value)
;
