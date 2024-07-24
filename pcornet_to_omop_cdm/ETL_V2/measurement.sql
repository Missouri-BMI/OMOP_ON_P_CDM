
create or replace secure view omop_cdm.cdm.measurement
AS
SELECT
    lab.lab_result_cm_id::INTEGER AS measurement_id,

    lab.patid::INTEGER AS person_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS measurement_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::DATE AS measurement_date,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::TIMESTAMP AS measurement_datetime,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(10) AS measurement_time,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS measurement_type_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS operator_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::NUMERIC AS value_as_number,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS value_as_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS unit_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::NUMERIC AS range_low,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::NUMERIC AS range_high,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS provider_id,

    lab.patid::INTEGER AS visit_occurrence_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS visit_detail_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS measurement_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS measurement_source_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS unit_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS unit_source_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS value_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS measurement_event_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS meas_event_field_concept_id

FROM pcornet_cdm.cdm_2023_april.deid_lab_result_cm lab
;