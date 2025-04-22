CREATE OR REPLACE VIEW {{ cdm_db }}.{{ cdm_schema }}.drug_exposure AS
SELECT 
    {% if site in ['mu', 'mu-id'] %}
        presc.prescribingid::INTEGER AS drug_exposure_id
    {% elif site == 'gpc' %}
        ROW_NUMBER() OVER (ORDER BY presc.prescribingid)::INTEGER AS drug_exposure_id
    {% else %}
        presc.prescribingid::INTEGER AS drug_exposure_id
    {% endif %}

    {% if site in ['mu', 'mu-id'] %}
        , presc.patid::INTEGER AS person_id
    {% elif site == 'gpc' %}
        , presc.patient_num::INTEGER AS person_id
    {% else %}
        , presc.patid::INTEGER AS person_id
    {% endif %}
    , COALESCE(rxnorm.concept_id, 0)::INTEGER AS drug_concept_id
    , presc.rx_start_date::DATE AS drug_exposure_start_date
    , presc.rx_start_date::DATETIME AS drug_exposure_start_datetime
    , NULL::DATE AS drug_exposure_end_date
    , NULL::TIMESTAMP AS drug_exposure_end_datetime
    , NULL::DATE AS verbatim_end_date
    , 38000177::INTEGER AS drug_type_concept_id
    , NULL::VARCHAR(50) AS stop_reason
    , NULL::INTEGER AS refills
    , presc.rx_quantity::NUMERIC AS quantity
    , presc.rx_days_supply::INTEGER AS days_supply
    , NULL::TEXT AS sig
    , COALESCE(
        CASE
            WHEN presc.rx_route = 'OT' THEN 44814649
            ELSE route.source_concept_id
        END, 0
      )::INTEGER AS route_concept_id
    , NULL::VARCHAR(50) AS lot_number
    , NULL::INTEGER AS provider_id
    {% if site in ['mu', 'mu-id'] %}
        , presc.encounterid::INTEGER AS visit_occurrence_id
    {% elif site == 'gpc' %}
        , presc.encounter_num::INTEGER AS visit_occurrence_id
    {% else %}
        , presc.encounterid::INTEGER AS visit_occurrence_id
    {% endif %}
    , NULL::INTEGER AS visit_detail_id
    , COALESCE(LEFT(raw_rx_med_name, 200), ' ') || '|' || COALESCE(rxnorm_cui, ' ')::VARCHAR(50) AS drug_source_value
    , COALESCE(rxnorm.concept_id, 0)::INTEGER AS drug_source_concept_id
    , presc.rx_route::VARCHAR(50) AS route_source_value
    , presc.rx_dose_ordered_unit::VARCHAR(50) AS dose_unit_source_value
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ prescribing_table }} presc
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept rxnorm
    ON presc.rxnorm_cui = rxnorm.concept_code
    AND rxnorm.vocabulary_id = 'RxNorm'
    AND rxnorm.standard_concept = 'S'
LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping route
    ON route.pcornet_field_name = 'RX ROUTE'
    AND presc.rx_route = route.pcornet_valueset_item
;