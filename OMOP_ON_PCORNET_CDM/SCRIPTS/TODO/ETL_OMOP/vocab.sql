--
create or replace table OMOP_CDM.CDM.COHORT_DEFINITION
as
select * from OMOP_CDM.VOCABULARY.COHORT_DEFINITION;


--
create or replace table OMOP_CDM.CDM.CONCEPT
as
select * from OMOP_CDM.VOCABULARY.CONCEPT;


--
create or replace table OMOP_CDM.CDM.CONCEPT_ANCESTOR
as
select * from OMOP_CDM.VOCABULARY.CONCEPT_ANCESTOR;


--
create or replace table OMOP_CDM.CDM.CONCEPT_CLASS
as
select * from OMOP_CDM.VOCABULARY.CONCEPT_CLASS;

--
create or replace table OMOP_CDM.CDM.CONCEPT_RELATIONSHIP
as
select * from OMOP_CDM.VOCABULARY.CONCEPT_RELATIONSHIP;

--
create or replace table OMOP_CDM.CDM.CONCEPT_SYNONYM
as
select * from OMOP_CDM.VOCABULARY.CONCEPT_SYNONYM;

--
create or replace table OMOP_CDM.CDM.DOMAIN
as
select * from OMOP_CDM.VOCABULARY.DOMAIN;

--
create or replace table OMOP_CDM.CDM.DRUG_STRENGTH
as
select * from OMOP_CDM.VOCABULARY.DRUG_STRENGTH;

--
create or replace table OMOP_CDM.CDM.RELATIONSHIP
as
select * from OMOP_CDM.VOCABULARY.RELATIONSHIP;

---
create or replace table OMOP_CDM.CDM.SOURCE_TO_CONCEPT_MAP
as
select * from OMOP_CDM.VOCABULARY.SOURCE_TO_CONCEPT_MAP;

--
create or replace table OMOP_CDM.CDM.VISIT_XWALK
as
select * from OMOP_CDM.VOCABULARY.VISIT_XWALK;

--
create or replace table OMOP_CDM.CDM.VOCABULARY
as
select * from OMOP_CDM.VOCABULARY.VOCABULARY;
