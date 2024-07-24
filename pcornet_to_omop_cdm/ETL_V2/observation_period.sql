Create or replace secure view OMOP_CDM.CDM.observation_period AS
(
SELECT
 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS observation_period_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS person_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::date AS observation_period_start_date,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::date AS observation_period_end_date,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS period_type_concept_id

FROM pcornet_cdm.CDM_2023_APRIL.deid_enrollment
);