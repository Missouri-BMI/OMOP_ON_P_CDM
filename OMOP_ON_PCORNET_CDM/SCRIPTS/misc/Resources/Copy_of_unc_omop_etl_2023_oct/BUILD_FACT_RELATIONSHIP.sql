/*
mom person_id = 111
baby person_id = 999
domain concept for person tab;e = 1147314
relationship concept for natural mother = 4277283
relationship concept for natural child = 4326600

	DOMAIN_CONCEPT_ID_1	FACT_ID_1	DOMAIN_CONCEPT_ID_2	FACT_ID_2	RELATIONSHIP_CONCEPT_ID	
row 1	1147314	111	1147314	999	4277283	natural mother relationship
row 2	1147314	999	1147314	111	4326600	natural child relationship
*/

/*
select top 100 *
into #OB_DEL_RECORDS
from clarity.dbo.V_OB_DEL_RECORDS
*/


declare @DOMAIN_PERSON int = 1147314;
declare @RELATIONSHIP_NATURAL_MOTHER int = 4277283;
declare @RELATIONSHIP_NATURAL_CHILD int = 4326600;

truncate table TRACS_CDM.OMOP.XSTG_FACT_RELATIONSHIP;

insert into TRACS_CDM.OMOP.XSTG_FACT_RELATIONSHIP with (tablock)
(
	DOMAIN_CONCEPT_ID_1,
	FACT_ID_1,
	DOMAIN_CONCEPT_ID_2,
	FACT_ID_2,
	RELATIONSHIP_CONCEPT_ID
)
-- MOM relationship
select
	--ob_del_records.mom_id,
	--ob_del_records.baby_id,
	@DOMAIN_PERSON as DOMAIN_CONCEPT_ID_1,
	person_mom.person_id as FACT_ID_1,
	@DOMAIN_PERSON as DOMAIN_CONCEPT_ID_2,
	person_child.person_id as FACT_ID_2,
	@RELATIONSHIP_NATURAL_MOTHER as RELATIONSHIP_CONCEPT_ID
from
	clarity.dbo.V_OB_DEL_RECORDS ob_del_records with (nolock)
	join tracs_cdm.omop.xstg_person person_mom with (nolock) on substring( ob_del_records.mom_id, 2, len(ob_del_records.mom_id)-1 ) = person_mom.person_id
	join tracs_cdm.omop.xstg_person person_child with (nolock) on substring( ob_del_records.baby_id, 2, len(ob_del_records.baby_id)-1 ) = person_child.person_id


UNION

-- CHILD relationship
select
	--ob_del_records.mom_id,
	--ob_del_records.baby_id,
	@DOMAIN_PERSON as DOMAIN_CONCEPT_ID_1,
	person_child.person_id as FACT_ID_1,
	@DOMAIN_PERSON as DOMAIN_CONCEPT_ID_2,
	person_mom.person_id as FACT_ID_2,
	@RELATIONSHIP_NATURAL_CHILD as RELATIONSHIP_CONCEPT_ID
from
	clarity.dbo.V_OB_DEL_RECORDS ob_del_records with (nolock)
	join tracs_cdm.omop.xstg_person person_mom with (nolock) on substring( ob_del_records.mom_id, 2, len(ob_del_records.mom_id)-1 ) = person_mom.person_id
	join tracs_cdm.omop.xstg_person person_child with (nolock) on substring( ob_del_records.baby_id, 2, len(ob_del_records.baby_id)-1 ) = person_child.person_id

;
