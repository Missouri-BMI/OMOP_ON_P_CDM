CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.location (
    location_id integer NOT NULL,
    address_1 varchar(50) NULL,
    address_2 varchar(50) NULL,
    city varchar(50) NULL,
    state varchar(2) NULL,
    zip varchar(9) NULL,
    county varchar(20) NULL,
    location_source_value varchar(50) NULL,
    country_concept_id integer NULL,
    country_source_value varchar(80) NULL,
    latitude float NULL,
    longitude float NULL 
) AS
WITH base AS (

{% if site == 'mu-id' %}

    -- MU-ID: full address history with dedupe (keep best ZIP9 when available)
    SELECT
        LEFT(ADDRESS_STREET, 50)::VARCHAR(50)                      AS address_1,
        LEFT(ADDRESS_DETAIL, 50)::VARCHAR(50)                      AS address_2,
        LEFT(ADDRESS_CITY, 50)::VARCHAR(50)                        AS city,
        ADDRESS_STATE::VARCHAR(2)                                  AS state,
        COALESCE(ADDRESS_ZIP9, ADDRESS_ZIP5)::VARCHAR(9)           AS zip,
        LEFT(ADDRESS_COUNTY, 20)::VARCHAR(20)                      AS county,
        NULL::VARCHAR(50)                                          AS location_source_value,
        NULL::INTEGER                                              AS country_concept_id,
        NULL::VARCHAR(80)                                          AS country_source_value,
        NULL::NUMERIC                                              AS latitude,
        NULL::NUMERIC                                              AS longitude,
        ROW_NUMBER() OVER (
            PARTITION BY
                UPPER(ADDRESS_STREET),
                UPPER(ADDRESS_CITY),
                UPPER(ADDRESS_STATE),
                UPPER(LEFT(ADDRESS_COUNTY, 20)),
                CASE
                    WHEN ADDRESS_ZIP9 IS NOT NULL THEN LEFT(ADDRESS_ZIP9, 5)
                    ELSE ADDRESS_ZIP5
                END
            ORDER BY
                CASE WHEN ADDRESS_ZIP9 IS NOT NULL THEN 0 ELSE 1 END,
                ADDRESS_ZIP9 DESC,
                ADDRESS_STREET,
                ADDRESS_CITY,
                ADDRESS_STATE,
                ADDRESS_COUNTY
        ) AS rn
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ address_history_table }}

{% elif site == 'mu' %}

    -- MU: only city/state/zip (no address lines / county)
    SELECT DISTINCT
        NULL::VARCHAR(50)                                          AS address_1,
        NULL::VARCHAR(50)                                          AS address_2,
        LEFT(ADDRESS_CITY, 50)::VARCHAR(50)                        AS city,
        ADDRESS_STATE::VARCHAR(2)                                  AS state,
        ADDRESS_ZIP5::VARCHAR(9)                                   AS zip,
        NULL::VARCHAR(20)                                          AS county,
        NULL::VARCHAR(50)                                          AS location_source_value,
        NULL::INTEGER                                              AS country_concept_id,
        NULL::VARCHAR(80)                                          AS country_source_value,
        NULL::NUMERIC                                              AS latitude,
        NULL::NUMERIC                                              AS longitude,
        1                                                         AS rn
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ address_history_table }}

{% elif site == 'gpc' %}

    -- GPC: no location rows (empty)
    SELECT
        NULL::VARCHAR(50) AS address_1,
        NULL::VARCHAR(50) AS address_2,
        NULL::VARCHAR(50) AS city,
        NULL::VARCHAR(2)  AS state,
        NULL::VARCHAR(9)  AS zip,
        NULL::VARCHAR(20) AS county,
        NULL::VARCHAR(50) AS location_source_value,
        NULL::INTEGER     AS country_concept_id,
        NULL::VARCHAR(80) AS country_source_value,
        NULL::NUMERIC     AS latitude,
        NULL::NUMERIC     AS longitude,
        1                 AS rn
    WHERE 1=0

{% else %}

    -- Default: empty
    SELECT
        NULL::VARCHAR(50) AS address_1,
        NULL::VARCHAR(50) AS address_2,
        NULL::VARCHAR(50) AS city,
        NULL::VARCHAR(2)  AS state,
        NULL::VARCHAR(9)  AS zip,
        NULL::VARCHAR(20) AS county,
        NULL::VARCHAR(50) AS location_source_value,
        NULL::INTEGER     AS country_concept_id,
        NULL::VARCHAR(80) AS country_source_value,
        NULL::NUMERIC     AS latitude,
        NULL::NUMERIC     AS longitude,
        1                 AS rn
    WHERE 1=0

{% endif %}

)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            UPPER(COALESCE(address_1, '')),
            UPPER(COALESCE(city, '')),
            UPPER(COALESCE(state, '')),
            COALESCE(zip, ''),
            UPPER(COALESCE(county, ''))
    )::INTEGER                                                    AS location_id,
    address_1,
    address_2,
    city,
    state,
    zip,
    county,
    location_source_value,
    country_concept_id,
    country_source_value,
    latitude,
    longitude
FROM base
WHERE rn = 1
;
