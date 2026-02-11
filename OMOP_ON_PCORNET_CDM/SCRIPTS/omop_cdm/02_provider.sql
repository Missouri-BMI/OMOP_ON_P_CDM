CREATE OR REPLACE TABLE {{ cdm_db }}.{{ cdm_schema }}.provider_id_map AS
WITH ids AS (
  SELECT DISTINCT
    provider.PROVIDERID AS providerid_source
  FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ provider_table }} provider
  WHERE provider.PROVIDERID IS NOT NULL
)
SELECT
  providerid_source,
  ROW_NUMBER() OVER (ORDER BY providerid_source ASC)::INTEGER AS provider_id
FROM ids;

CREATE TABLE  {{ cdm_db }}.{{ cdm_schema }}.provider (
    provider_id integer NOT NULL,
    provider_name varchar(255) NULL,
    npi varchar(20) NULL,
    dea varchar(20) NULL,
    specialty_concept_id integer NULL,
    care_site_id integer NULL,
    year_of_birth integer NULL,
    gender_concept_id integer NULL,
    provider_source_value varchar(50) NULL,
    specialty_source_value varchar(50) NULL,
    specialty_source_concept_id integer NULL,
    gender_source_value varchar(50) NULL,
    gender_source_concept_id integer NULL
) AS
WITH gender_map AS (
    SELECT 
        p.provider_sex,
        COALESCE(c.concept_id, 0) AS gender_concept_id
    FROM (SELECT DISTINCT provider_sex FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ provider_table }}) p
    LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept c
      ON (
        CASE 
            WHEN p.provider_sex = 'A'  THEN 'A'
            WHEN p.provider_sex = 'F'  THEN 'F'
            WHEN p.provider_sex = 'M'  THEN 'M'
            WHEN p.provider_sex = 'OT' THEN 'O'
            WHEN p.provider_sex = 'UN' THEN 'U'
            ELSE '0' 
        END = c.concept_code
      )
     AND c.domain_id = 'Gender' 
     AND c.vocabulary_id = 'Gender' 
     AND c.concept_class_id = 'Gender'
)
SELECT
    idmap.provider_id                                   AS provider_id,
    NULL::VARCHAR(255)                                  AS provider_name,
    NULL::VARCHAR(20)                                   AS npi,
    NULL::VARCHAR(20)                                   AS dea,
    0::INTEGER                                          AS specialty_concept_id,
    NULL::INTEGER                                       AS care_site_id,
    NULL::INTEGER                                       AS year_of_birth,
    g.gender_concept_id                                 AS gender_concept_id,
    LEFT(idmap.providerid_source, 50)::VARCHAR(50)      AS provider_source_value,
    LEFT(p.provider_specialty_primary, 50)::VARCHAR(50) AS specialty_source_value,
    0::INTEGER                                          AS specialty_source_concept_id,
    LEFT(p.provider_sex, 50)::VARCHAR(50)               AS gender_source_value,
    0::INTEGER                                          AS gender_source_concept_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ provider_table }} p
JOIN {{ cdm_db }}.{{ cdm_schema }}.provider_id_map idmap
  ON p.PROVIDERID = idmap.providerid_source
LEFT JOIN gender_map g
  ON p.provider_sex = g.provider_sex;