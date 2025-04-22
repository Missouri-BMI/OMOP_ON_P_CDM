CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.care_site AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY enc.facilityid)::INTEGER AS care_site_id,
    LEFT(enc.facilityid, 255)::VARCHAR(255) AS care_site_name,
    COALESCE(place.source_concept_id, 44814650)::INTEGER AS place_of_service_concept_id,
    NULL::INTEGER AS location_id,
    LEFT(enc.facility_type, 50)::VARCHAR(50) AS care_site_source_value,
    LEFT(enc.facility_type, 50)::VARCHAR(50) AS place_of_service_source_value
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ encounter_table }} enc
LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping place
    ON place.pcornet_valueset_item = enc.facility_type
    AND place.source_concept_id IS NOT NULL
    AND place.source_concept_class = 'Facility type';
