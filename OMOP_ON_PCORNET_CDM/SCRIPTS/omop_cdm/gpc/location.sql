CREATE OR REPLACE VIEW {cdm_db}.{cdm_schema}.LOCATION AS
(
   SELECT
      1::INTEGER AS location_id,
      NULL::VARCHAR(50) AS address_1,
      NULL::VARCHAR(50) AS address_2,
      NULL::VARCHAR(50) AS city,
      NULL::VARCHAR(2) AS state,
      NULL::VARCHAR(9) AS zip,
      NULL::VARCHAR(20) AS county,
      NULL::VARCHAR(50) AS location_source_value,
      NULL::INTEGER AS country_concept_id,
      NULL::VARCHAR(80) AS country_source_value,
      NULL::NUMERIC AS latitude,
      NULL::NUMERIC AS longitude
   -- FROM {pcornet_db}.{pcornet_schema}.deid_lds_address_history
);
