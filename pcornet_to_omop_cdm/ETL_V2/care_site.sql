
create or replace secure view OMOP_CDM.DEID_CDM.CARE_SITE
AS
SELECT distinct
    ROW_NUMBER() OVER (ORDER BY enc.facilityid) ::INTEGER AS care_site_id,
    left(enc.facilityid, 255)::VARCHAR(255) AS care_site_name,
    coalesce(place.source_concept_id, 44814650)::INTEGER AS place_of_service_concept_id,

    NULL::INTEGER AS location_id,

    left(enc.facility_type, 50)::VARCHAR(50) AS care_site_source_value,
    left(enc.facility_type,50)::VARCHAR(50) AS place_of_service_source_value

FROM pcornet_cdm.CDM.deid_encounter enc
left join
    OMOP_CDM.CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING place
    on place.PCORNET_VALUESET_ITEM = enc.facility_type
    and place.source_concept_id is not null
    and place.source_concept_class='Facility type'
;