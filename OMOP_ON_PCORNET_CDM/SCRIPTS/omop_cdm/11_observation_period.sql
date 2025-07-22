CREATE  TABLE {{ cdm_db }}.{{ cdm_schema }}.observation_period (
    observation_period_id integer NOT NULL,
    person_id integer NOT NULL,
    observation_period_start_date date NOT NULL,
    observation_period_end_date date NOT NULL,
    period_type_concept_id integer NOT NULL
) AS
SELECT
    ROW_NUMBER() OVER (ORDER BY enrl.patid)::INTEGER AS observation_period_id,
    {% if site in ['mu', 'mu-id'] %}
        enrl.patid
    {% elif site == 'gpc' %}
        enrl.person_num
    {% else %}
        enrl.patid
    {% endif %} ::INTEGER AS person_id,
    enrl.enr_start_date::DATE AS observation_period_start_date,
    enrl.enr_end_date::DATE AS observation_period_end_date,
    44814722::INTEGER AS period_type_concept_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ enrollment_table }} enrl;
