
CREATE or replace secure view omop_cdm.cdm.death
AS
SELECT
 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    PATID::INTEGER AS person_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    death_date::DATE AS death_date,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::TIMESTAMP AS death_datetime,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS death_type_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS cause_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS cause_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS cause_source_concept_id

FROM pcornet_cdm.cdm_2023_april.deid_death
;