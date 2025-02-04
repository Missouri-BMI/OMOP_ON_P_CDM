
--  DRG observations
--TODO:  observation_id,
--TODO: add more observations

CREATE OR REPLACE view {cdm_db}.{cdm_schema}.observation AS
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
   --  obs_seq.NEXTVAL AS observation_id,
   ROW_NUMBER() OVER (ORDER BY enc.encounterid) ::INTEGER AS observation_id,
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
    {pcornet_db}.{pcornet_schema}.deid_encounter enc
LEFT JOIN
    {cdm_db}.{vocabulary}.concept drg
ON
    enc.drg = drg.concept_code
    AND drg.concept_class_id = 'DRG'
    AND drg.valid_end_date = '2007-09-30'
    AND drg.invalid_reason = 'D'
LEFT JOIN
    {cdm_db}.{vocabulary}.concept msdrg
ON
    enc.drg = msdrg.concept_code
    AND msdrg.concept_class_id = 'MS-DRG'
    AND msdrg.invalid_reason IS NULL
WHERE
    enc.DRG IS NOT NULL;

