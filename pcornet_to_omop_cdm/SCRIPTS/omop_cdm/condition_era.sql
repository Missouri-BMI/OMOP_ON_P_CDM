Create or replace view OMOP_CDM.CDM.condition_era
AS
SELECT
 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS condition_era_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS person_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS condition_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::DATE AS condition_era_start_date,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::DATE AS condition_era_end_date,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS condition_occurrence_count

FROM pcornet_cdm.cdm.deid_condition
;