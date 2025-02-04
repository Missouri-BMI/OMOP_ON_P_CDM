Create or replace view {cdm_db}.{cdm_schema}.LOCATION AS
(
SELECT
distinct
   ROW_NUMBER() OVER (ORDER BY (SELECT NULL))::INTEGER AS location_id,

    NULL::VARCHAR(50) AS address_1,

    NULL::VARCHAR(50) AS address_2,

 ADDRESS_CITY::VARCHAR(50) AS city,

ADDRESS_STATE::VARCHAR(2) AS state,

 ADDRESS_ZIP5::VARCHAR(9) AS zip,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(20) AS county,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(50) AS location_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS country_concept_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::VARCHAR(80) AS country_source_value,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::NUMERIC AS latitude,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::NUMERIC AS longitude

FROM {pcornet_db}.{pcornet_schema}.deid_lds_address_history
);
