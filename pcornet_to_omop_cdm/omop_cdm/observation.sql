
CREATE OR REPLACE SEQUENCE cdm.obs_seq;

-- Create or replace the Snowflake view for DRG observations
CREATE OR REPLACE VIEW omop_cdm.cdm.DEID_observation AS
SELECT DISTINCT
    3040464 AS observation_concept_id,
    CASE
        WHEN enc.discharge_date IS NOT NULL AND TRY_TO_DATE(enc.discharge_date::varchar, 'YYYY-MM-DD') IS NOT NULL THEN TRY_TO_DATE(enc.discharge_date::varchar, 'YYYY-MM-DD')
        WHEN enc.admit_date IS NOT NULL AND TRY_TO_DATE(enc.admit_date::varchar, 'YYYY-MM-DD') IS NOT NULL THEN TRY_TO_DATE(enc.admit_date::varchar, 'YYYY-MM-DD')
        ELSE '0001-01-01'::date
    END AS observation_date,
    CASE
        WHEN enc.discharge_date IS NOT NULL AND TRY_TO_TIMESTAMP(enc.discharge_date::varchar, 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL THEN TRY_TO_TIMESTAMP(enc.discharge_date::varchar, 'YYYY-MM-DD HH24:MI:SS')
        WHEN enc.admit_date IS NOT NULL AND TRY_TO_TIMESTAMP(enc.admit_date::varchar, 'YYYY-MM-DD HH24:MI:SS') IS NOT NULL THEN TRY_TO_TIMESTAMP(enc.admit_date::varchar, 'YYYY-MM-DD HH24:MI:SS')
        ELSE '0001-01-01'::timestamp
    END AS observation_datetime,
    obs_seq.NEXTVAL AS observation_id,
    0 AS observation_source_concept_id,
    'DRG|'||enc.DRG AS observation_source_value,
    38000280 AS observation_type_concept_id,
    enc.patid AS person_id,
    enc.providerid AS provider_id,
    4269228 AS qualifier_concept_id,
    'Primary' AS qualifier_source_value, -- Only primary DRG recorded in PCORnet
    NULL AS unit_concept_id,
    NULL AS unit_source_value,
    CASE
        WHEN TRY_TO_DATE(enc.discharge_date::varchar, 'YYYY-MM-DD') < '2007-10-01' OR TRY_TO_DATE(enc.admit_date::varchar, 'YYYY-MM-DD') < '2007-10-01'
        THEN COALESCE(drg.concept_id, msdrg.concept_id)
        ELSE msdrg.concept_id
    END AS value_as_concept_id,
    NULL AS value_as_number,
    NULL AS value_as_string,
    CASE
        WHEN TRY_TO_DATE(enc.discharge_date::varchar, 'YYYY-MM-DD') < '2007-10-01' OR TRY_TO_DATE(enc.admit_date::varchar, 'YYYY-MM-DD') < '2007-10-01'
        THEN COALESCE(drg.concept_id, msdrg.concept_id)::varchar
        ELSE msdrg.concept_id::varchar
    END AS value_source_value,
    enc.encounterid AS visit_occurrence_id
FROM
    pcornet_cdm.cdm.deid_encounter enc
LEFT JOIN
    omop_cdm.vocabulary.concept drg
ON
    enc.drg = drg.concept_code
    AND drg.concept_class_id = 'DRG'
    AND drg.valid_end_date = '2007-09-30'
    AND drg.invalid_reason = 'D'
LEFT JOIN
    omop_cdm.vocabulary.concept msdrg
ON
    enc.drg = msdrg.concept_code
    AND msdrg.concept_class_id = 'MS-DRG'
    AND msdrg.invalid_reason IS NULL
WHERE
    enc.DRG IS NOT NULL;

/*
create or replace view omop_cdm.cdm.deid_observation
AS
select
 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS observation_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS person_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS observation_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::DATE AS observation_date,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::TIMESTAMP AS observation_datetime,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS observation_type_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::NUMERIC AS value_as_number,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(60) AS value_as_string,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS value_as_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS qualifier_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS unit_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS provider_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS visit_occurrence_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS visit_detail_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS observation_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS observation_source_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS unit_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS qualifier_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS value_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS observation_event_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS obs_event_field_concept_id

FROM pcornet_cdm.cdm_2023_april.deid_immunization;
*/