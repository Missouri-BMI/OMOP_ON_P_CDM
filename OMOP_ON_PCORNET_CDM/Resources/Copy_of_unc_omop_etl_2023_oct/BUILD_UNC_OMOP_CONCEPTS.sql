--- metadata table ----

drop table if exists tracs_cdm.XOMOP.UNC_OMOP_CONCEPTS;

SELECT
	DOMAIN_ID,
	CONCEPT_ID,
	SUM(NUM_ROWS) AS CONCEPT_COUNT
INTO TRACS_CDM.XOMOP.UNC_OMOP_CONCEPTS
FROM
(
select
	concept.DOMAIN_ID,
	concept.CONCEPT_ID,
	count(*) as num_rows
from
	tracs_cdm.omop.CONDITION_OCCURRENCE
	join tracs_cdm.omop.concept on condition_occurrence.CONDITION_CONCEPT_ID = concept.CONCEPT_ID
group by
	concept.DOMAIN_ID,
	concept.concept_id

UNION

select
	concept.DOMAIN_ID,
	concept.CONCEPT_ID,
	count(*) as num_rows
from
	tracs_cdm.omop.DRUG_EXPOSURE
	join tracs_cdm.omop.concept on DRUG_EXPOSURE.DRUG_CONCEPT_ID = concept.CONCEPT_ID
group by
	concept.DOMAIN_ID,
	concept.concept_id

UNION

select
	concept.DOMAIN_ID,
	concept.CONCEPT_ID,
	count(*) as num_rows
from
	tracs_cdm.omop.PROCEDURE_OCCURRENCE
	join tracs_cdm.omop.concept on PROCEDURE_OCCURRENCE.PROCEDURE_CONCEPT_ID = concept.CONCEPT_ID
group by
	concept.DOMAIN_ID,
	concept.concept_id

UNION

select
	concept.DOMAIN_ID,
	concept.CONCEPT_ID,
	count(*) as num_rows
from
	tracs_cdm.omop.MEASUREMENT
	join tracs_cdm.omop.concept on MEASUREMENT.MEASUREMENT_CONCEPT_ID = concept.CONCEPT_ID
group by
	concept.DOMAIN_ID,
	concept.concept_id

UNION

select
	concept.DOMAIN_ID,
	concept.CONCEPT_ID,
	count(*) as num_rows
from
	tracs_cdm.omop.OBSERVATION
	join tracs_cdm.omop.concept on OBSERVATION.OBSERVATION_CONCEPT_ID = concept.CONCEPT_ID
group by
	concept.DOMAIN_ID,
	concept.concept_id

) subq
group by
	DOMAIN_ID,
	CONCEPT_ID
;
create index unc_omop_concept_idx on tracs_cdm.XOMOP.UNC_OMOP_CONCEPTS(concept_id);

ALTER TABLE tracs_cdm.[XOMOP].[UNC_OMOP_CONCEPTS] REBUILD WITH (DATA_COMPRESSION=PAGE)
