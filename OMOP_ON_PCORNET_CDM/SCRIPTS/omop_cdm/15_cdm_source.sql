{% if site in ['mu', 'mu-id'] %}
  {% set cdm_source_name = 'MU PCORNET CDM Data' %}
  {% set cdm_source_abbreviation = 'MU' %}
  {% set cdm_holder = 'MU NextGen BMI' %}
  {% set source_description = 'MU PCORNET CDM IN OMOP CDM FORMAT'%}
{% elif site == 'gpc' %}
  {% set cdm_source_name = 'GPC PCORNET CDM Data' %}
  {% set cdm_source_abbreviation = 'GPC' %}
  {% set cdm_holder = 'GPC' %}
  {% set source_description = 'GPC PCORNET CDM IN OMOP CDM FORMAT'%}
{% else %}
  {% set cdm_source_name = site|upper ~ ' CDM Data' %}
  {% set cdm_source_abbreviation = site|upper %}
  {% set cdm_holder = site|upper %}
  {% set source_description = 'PCORNET CDM IN OMOP CDM FORMAT'%}
{% endif %}

CREATE TABLE {{ cdm_db }}.{{ vocabulary }}.cdm_source (
    cdm_source_name varchar(255) NOT NULL,
    cdm_source_abbreviation varchar(25) NOT NULL,
    cdm_holder varchar(255) NOT NULL,
    source_description TEXT NULL,
    source_documentation_reference varchar(255) NULL,
    cdm_etl_reference varchar(255) NULL,
    source_release_date date NOT NULL,
    cdm_release_date date NOT NULL,
    cdm_version varchar(10) NULL,
    cdm_version_concept_id integer NOT NULL,
    vocabulary_version varchar(20) NOT NULL
) AS
WITH SOURCE_VERSION AS (
    SELECT 
        MAX(REFRESH_ENCOUNTER_DATE) AS SOURCE_RELEASE_DATE 
    FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ harvest_table }}
)
SELECT
    '{{ cdm_source_name }}'           AS cdm_source_name,
    '{{ cdm_source_abbreviation }}'   AS cdm_source_abbreviation,
    '{{ cdm_holder }}'                AS cdm_holder,
    '{{ source_description }}'        AS source_description,
    NULL                              AS source_documentation_reference,
    NULL                              AS cdm_etl_reference,
    sv.SOURCE_RELEASE_DATE            AS source_release_date,
    CURRENT_DATE                      AS cdm_release_date,
    'v5.4'                            AS cdm_version,
    756265                            AS cdm_version_concept_id,
    v.vocabulary_version
FROM {{ cdm_db }}.{{ vocabulary }}.vocabulary v
CROSS JOIN SOURCE_VERSION sv
WHERE v.vocabulary_id = 'None';
