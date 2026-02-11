{% if site in ['mu', 'mu-id'] %}
  {% set person_id_expr = "presc.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "presc.encounterid::INTEGER" %}
{% elif site == 'gpc' %}
  {% set person_id_expr = "presc.patient_num::INTEGER" %}
  {% set visit_occurrence_id_expr = "presc.encounter_num::INTEGER" %}
{% else %}
  {% set person_id_expr = "presc.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "presc.encounterid::INTEGER" %}
{% endif %}

CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.drug_exposure (
    drug_exposure_id integer IDENTITY(1,1) NOT NULL,
    person_id integer NOT NULL,
    drug_concept_id integer NOT NULL,
    drug_exposure_start_date date NOT NULL,
    drug_exposure_start_datetime TIMESTAMP NULL,
    drug_exposure_end_date date NOT NULL,
    drug_exposure_end_datetime TIMESTAMP NULL,
    verbatim_end_date date NULL,
    drug_type_concept_id integer NOT NULL,
    stop_reason varchar(20) NULL,
    refills integer NULL,
    quantity float NULL,
    days_supply integer NULL,
    sig TEXT NULL,
    route_concept_id integer NULL,
    lot_number varchar(50) NULL,
    provider_id integer NULL,
    visit_occurrence_id integer NULL,
    visit_detail_id integer NULL,
    drug_source_value varchar(50) NULL,
    drug_source_concept_id integer NULL,
    route_source_value varchar(50) NULL,
    dose_unit_source_value varchar(50) NULL
);

INSERT INTO {{ cdm_db }}.{{ cdm_schema }}.drug_exposure (
    person_id,
    drug_concept_id,
    drug_exposure_start_date,
    drug_exposure_start_datetime,
    drug_exposure_end_date,
    drug_exposure_end_datetime,
    verbatim_end_date,
    drug_type_concept_id,
    stop_reason,
    refills,
    quantity,
    days_supply,
    sig,
    route_concept_id,
    lot_number,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    drug_source_value,
    drug_source_concept_id,
    route_source_value,
    dose_unit_source_value
)
SELECT
    {{ person_id_expr }}                                                AS person_id,
    COALESCE(rxnorm.concept_id, 0)::INTEGER                             AS drug_concept_id,
    presc.rx_start_date::DATE                                           AS drug_exposure_start_date,
    presc.rx_start_date::TIMESTAMP                                      AS drug_exposure_start_datetime,
    COALESCE(presc.rx_end_date, presc.rx_start_date)::DATE              AS drug_exposure_end_date,
    COALESCE(
      presc.rx_end_date::TIMESTAMP,
      presc.rx_start_date::TIMESTAMP
    )                                                                   AS drug_exposure_end_datetime,
    NULL::DATE                                                          AS verbatim_end_date,
    38000177::INTEGER                                                   AS drug_type_concept_id,
    NULL::VARCHAR(20)                                                   AS stop_reason,
    NULL::INTEGER                                                       AS refills,
    presc.rx_quantity::FLOAT                                            AS quantity,
    presc.rx_days_supply::INTEGER                                       AS days_supply,
    NULL::TEXT                                                          AS sig,
    COALESCE(
      CASE
        WHEN presc.rx_route = 'OT' THEN 44814649
        ELSE route.source_concept_id
      END, 0
    )::INTEGER                                                          AS route_concept_id,
    NULL::VARCHAR(50)                                                   AS lot_number,
    pm.provider_id                                                      AS provider_id,
    {{ visit_occurrence_id_expr }}                                      AS visit_occurrence_id,
    {{ visit_occurrence_id_expr }}                                      AS visit_detail_id,
    COALESCE(LEFT(presc.raw_rx_med_name, 50), ' ')::VARCHAR(50)         AS drug_source_value,
    COALESCE(rxnorm.concept_id, 0)::INTEGER                             AS drug_source_concept_id,
    LEFT(COALESCE(presc.rx_route, ''), 50)::VARCHAR(50)                 AS route_source_value,
    LEFT(COALESCE(presc.rx_dose_ordered_unit, ''), 50)::VARCHAR(50)     AS dose_unit_source_value
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ prescribing_table }} presc
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.provider_id_map pm
  ON pm.providerid_source = presc.rx_providerid
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept rxnorm
  ON presc.rxnorm_cui = rxnorm.concept_code
 AND rxnorm.vocabulary_id = 'RxNorm'
 AND rxnorm.standard_concept = 'S'
LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping route
  ON route.pcornet_field_name = 'RX ROUTE'
 AND presc.rx_route = route.pcornet_valueset_item
WHERE presc.rx_start_date IS NOT NULL 
  AND presc.rxnorm_cui IS NOT NULL; -- only include records with start date with rxnorm code