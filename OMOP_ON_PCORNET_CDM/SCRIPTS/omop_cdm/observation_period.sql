CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.observation_period
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY enrl.patid)::INTEGER AS observation_period_id,
    {% if site in ['mu', 'mu-id'] %}
        enrl.patid::INTEGER AS person_id,
    {% elif site == 'gpc' %}
        enrl.person_num::INTEGER AS person_id,
    {% else %}
        enrl.patid::INTEGER AS person_id,
    {% endif %}
    enrl.enr_start_date::DATE AS observation_period_start_date,
    enrl.enr_end_date::DATE AS observation_period_end_date,
    44814722::INTEGER AS period_type_concept_id
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ enrollment_table }} enrl
;
