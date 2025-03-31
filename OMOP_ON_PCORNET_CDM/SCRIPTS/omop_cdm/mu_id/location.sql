
CREATE OR REPLACE SECURE VIEW {cdm_db}.{cdm_schema}.LOCATION AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY 
                UPPER(address_1), 
                UPPER(city), 
                UPPER(state), 
                zip, 
                UPPER(county)
        )::INTEGER AS location_id,
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
    FROM (
        SELECT
            ADDRESS_STREET::VARCHAR(50) AS address_1,
            ADDRESS_DETAIL::VARCHAR(50) AS address_2,
            ADDRESS_CITY::VARCHAR(50) AS city,
            ADDRESS_STATE::VARCHAR(2) AS state,
            COALESCE(ADDRESS_ZIP9, ADDRESS_ZIP5)::VARCHAR(9) AS zip,
            LEFT(ADDRESS_COUNTY,20)::VARCHAR(20) AS county,
            NULL::VARCHAR(50) AS location_source_value,
            NULL::INTEGER AS country_concept_id,
            NULL::VARCHAR(80) AS country_source_value,
            NULL::NUMERIC AS latitude,
            NULL::NUMERIC AS longitude,
            ROW_NUMBER() OVER (
                PARTITION BY 
                    UPPER(ADDRESS_STREET),
                    UPPER(ADDRESS_CITY),
                    UPPER(ADDRESS_STATE),
                    UPPER(LEFT(ADDRESS_COUNTY,20)),
                    CASE 
                        WHEN ADDRESS_ZIP9 IS NOT NULL 
                        THEN LEFT(ADDRESS_ZIP9,5) 
                        ELSE ADDRESS_ZIP5 
                    END
                ORDER BY 
                    -- Prioritize records with ZIP9
                    CASE WHEN ADDRESS_ZIP9 IS NOT NULL THEN 0 ELSE 1 END,
                    ADDRESS_ZIP9 DESC,  
                    ADDRESS_STREET,
                    ADDRESS_CITY,
                    ADDRESS_STATE,
                    ADDRESS_COUNTY
            ) AS rn
        FROM {pcornet_db}.{pcornet_schema}.private_address_history
    )
    WHERE rn = 1
    ORDER BY address_1, city, state, zip, county
);

