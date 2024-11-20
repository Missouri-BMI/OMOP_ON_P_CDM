--TODO: all columns are null


create or replace view cdm.provider
AS
SELECT
 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS provider_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(255) AS provider_name,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(20) AS npi,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(20) AS dea,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS specialty_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS care_site_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS year_of_birth,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS gender_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS provider_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS specialty_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS specialty_source_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS gender_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS gender_source_concept_id

FROM DEIDENTIFIED_PCORNET_CDM.CDM.deid_provider
;