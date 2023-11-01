
create or replace secure view omop_cdm.cdm.care_site
AS
SELECT distinct
    ROW_NUMBER() OVER (ORDER BY enc.facilityid) ::INTEGER AS care_site_id,

    left(enc.facilityid, 255)::VARCHAR(255) AS care_site_name,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS place_of_service_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS location_id,

    enc.facility_type::VARCHAR(50) AS care_site_source_value,

    left(enc.facility_location,50)::VARCHAR(50) AS place_of_service_source_value

FROM pcornet_cdm.cdm_2023_april.deid_encounter enc
;