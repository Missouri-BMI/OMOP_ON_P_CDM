
create or replace secure view omop_cdm.cdm.drug_exposure
AS
SELECT
    disp.dispensingid::INTEGER AS drug_exposure_id,

    disp.patid::INTEGER AS person_id,

    disp.ndc::INTEGER AS drug_concept_id,

    disp.dispense_date::DATE AS drug_exposure_start_date,

    disp.dispense_date::TIMESTAMP AS drug_exposure_start_datetime,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::DATE AS drug_exposure_end_date,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::TIMESTAMP AS drug_exposure_end_datetime,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::DATE AS verbatim_end_date,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS drug_type_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS stop_reason,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS refills,

    disp.dispense_amt::NUMERIC AS quantity,

    disp.dispense_sup::INTEGER AS days_supply,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::TEXT AS sig,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS route_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS lot_number,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS provider_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS visit_occurrence_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS visit_detail_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS drug_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS drug_source_concept_id,

    disp.dispense_route::VARCHAR(50) AS route_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS dose_unit_source_value

FROM pcornet_cdm.cdm_2023_april.deid_dispensing disp
;