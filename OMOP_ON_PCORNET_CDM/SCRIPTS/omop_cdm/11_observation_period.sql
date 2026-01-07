{% if site in ['mu', 'mu-id'] %}
  {% set person_id_expr = "enrl.patid::INTEGER" %}
  {% set order_expr = "enrl.patid" %}
{% elif site == 'gpc' %}
  {% set person_id_expr = "enrl.patient_num::INTEGER" %}
  {% set order_expr = "enrl.patient_num" %}
{% else %}
  {% set person_id_expr = "enrl.patid::INTEGER" %}
  {% set order_expr = "enrl.patid" %}
{% endif %}

CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.observation_period (
    observation_period_id integer NOT NULL,
    person_id integer NOT NULL,
    observation_period_start_date date NOT NULL,
    observation_period_end_date date NOT NULL,
    period_type_concept_id integer NOT NULL
) AS
SELECT
    ROW_NUMBER() OVER (
      ORDER BY {{ order_expr }}, enrl.enr_start_date, enrl.enr_end_date
    )::INTEGER                                                     AS observation_period_id,
    {{ person_id_expr }}                                           AS person_id,
    enrl.enr_start_date::DATE                                      AS observation_period_start_date,
    enrl.enr_end_date::DATE                                        AS observation_period_end_date,
    44814722::INTEGER                                              AS period_type_concept_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ enrollment_table }} enrl
WHERE enrl.enr_start_date IS NOT NULL
  AND enrl.enr_end_date IS NOT NULL
;
