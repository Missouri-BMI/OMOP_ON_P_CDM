-- 1) Build deterministic care_site_id mapping (rebuild-style)
CREATE OR REPLACE TABLE {{ cdm_db }}.{{ cdm_schema }}.care_site_map AS
WITH facility AS (
  SELECT DISTINCT
    enc.facilityid,
    enc.facility_type
  FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ encounter_table }} enc
  WHERE enc.facilityid IS NOT NULL
)
SELECT
  facilityid                                                     AS facilityid_source,
  ROW_NUMBER() OVER (ORDER BY facilityid)::INTEGER               AS care_site_id,
  facility_type                                                  AS facility_type
FROM facility;

-- 2) Create CARE_SITE from the mapper (single source of truth for IDs)
CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.care_site AS
SELECT
  m.care_site_id::INTEGER                                        AS care_site_id,
  NULL::VARCHAR(255)                                             AS care_site_name,
  COALESCE(place.source_concept_id, 44814650)::INTEGER           AS place_of_service_concept_id,
  NULL::INTEGER                                                  AS location_id,
  LEFT(m.facilityid_source::VARCHAR, 50)::VARCHAR(50)            AS care_site_source_value,
  NULL                                                          AS place_of_service_source_value
FROM {{ cdm_db }}.{{ cdm_schema }}.care_site_map m
LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping place
  ON place.pcornet_valueset_item = m.facility_type
 AND place.source_concept_id IS NOT NULL
 AND place.source_concept_class = 'Facility type';
