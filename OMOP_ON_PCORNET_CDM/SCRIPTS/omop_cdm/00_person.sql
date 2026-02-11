{% if site in ['mu', 'mu-id'] %}
  {% set person_id_expr = "demographic.patid::INTEGER" %}
{% elif site == 'gpc' %}
  {% set person_id_expr = "demographic.patient_num::INTEGER" %}
{% else %}
  {% set person_id_expr = "demographic.patid::INTEGER" %}
{% endif %}

CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.person (
    person_id integer NOT NULL,
    gender_concept_id integer NOT NULL,
    year_of_birth integer NOT NULL,
    month_of_birth integer NULL,
    day_of_birth integer NULL,
    birth_datetime TIMESTAMP NULL,
    race_concept_id integer NOT NULL,
    ethnicity_concept_id integer NOT NULL,
    location_id integer NULL,
    provider_id integer NULL,
    care_site_id integer NULL,
    person_source_value varchar(50) NULL,
    gender_source_value varchar(50) NULL,
    gender_source_concept_id integer NULL,
    race_source_value varchar(50) NULL,
    race_source_concept_id integer NULL,
    ethnicity_source_value varchar(50) NULL,
    ethnicity_source_concept_id integer NULL 
) AS
WITH gender_map AS (
    SELECT 
        p.sex,
        c.concept_id AS gender_concept_id
    FROM (SELECT DISTINCT sex FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ demographic_table }}) p
    LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept c
      ON (
        CASE 
            WHEN p.sex = 'A'  THEN 'A'
            WHEN p.sex = 'F'  THEN 'F'
            WHEN p.sex = 'M'  THEN 'M'
            WHEN p.sex = 'OT' THEN 'O'
            WHEN p.sex = 'UN' THEN 'U'
            ELSE '0' 
        END = c.concept_code
      )
     AND c.domain_id = 'Gender' 
     AND c.vocabulary_id = 'Gender' 
     AND c.concept_class_id = 'Gender'
),
race_map AS (
    SELECT 
        p.race,
        c.concept_id AS race_concept_id
    FROM (SELECT DISTINCT race FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ demographic_table }}) p
    LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept c
      ON (
        CASE 
            WHEN p.race = '01' THEN '1'
            WHEN p.race = '02' THEN '2'
            WHEN p.race = '03' THEN '3'
            WHEN p.race = '04' THEN '4'
            WHEN p.race = '05' THEN '5'
            WHEN p.race = '06' THEN '6'
            WHEN p.race = '07' THEN '7'
            WHEN p.race = 'NI' THEN 'UNK'
            WHEN p.race = 'UN' THEN 'UNK'
            WHEN p.race = 'OT' THEN '9'
            ELSE '0'
        END = c.concept_code
      )
     AND c.domain_id = 'Race' 
     AND c.vocabulary_id = 'Race' 
     AND c.concept_class_id = 'Race'
),
hispanic_map AS (
    SELECT 
        p.hispanic,
        c.concept_id AS ethnicity_concept_id
    FROM (SELECT DISTINCT hispanic FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ demographic_table }}) p
    LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.concept c
      ON (
        CASE 
            WHEN p.hispanic = 'Y' THEN 'Hispanic'
            WHEN p.hispanic = 'N' THEN 'Not Hispanic'
            -- R, NI, UN, OT all result in 0 via the ELSE branch
            ELSE '0'
        END = c.concept_name
      )
     AND c.domain_id = 'Ethnicity' 
     AND c.vocabulary_id = 'Ethnicity' 
     AND c.concept_class_id = 'Ethnicity'
)
SELECT
    {{ person_id_expr }}                                            AS person_id,
    coalesce(g.gender_concept_id, 0)                                AS gender_concept_id,
    EXTRACT(YEAR  FROM demographic.birth_date)::INTEGER             AS year_of_birth,
    EXTRACT(MONTH FROM demographic.birth_date)::INTEGER             AS month_of_birth,
    EXTRACT(DAY   FROM demographic.birth_date)::INTEGER             AS day_of_birth,
    CONCAT(DATE(demographic.birth_date), ' ', demographic.birth_time)::TIMESTAMP
                                                                    AS birth_datetime,
    coalesce(r.race_concept_id, 0)                                  AS race_concept_id,
    coalesce(h.ethnicity_concept_id, 0)                             AS ethnicity_concept_id,
    NULL                                                            AS location_id,
    NULL                                                            AS provider_id,
    NULL                                                            AS care_site_id,
    {{ person_id_expr }}::VARCHAR(50)                               AS person_source_value,
    demographic.sex                                                 AS gender_source_value,
    0                                                               AS gender_source_concept_id,
    demographic.race                                                AS race_source_value,
    0                                                               AS race_source_concept_id,
    demographic.hispanic                                            AS ethnicity_source_value,
    0                                                               AS ethnicity_source_concept_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ demographic_table }} demographic
LEFT JOIN gender_map g   ON demographic.sex = g.sex
LEFT JOIN race_map r     ON demographic.race = r.race
LEFT JOIN hispanic_map h ON demographic.hispanic = h.hispanic
WHERE demographic.birth_date IS NOT NULL;