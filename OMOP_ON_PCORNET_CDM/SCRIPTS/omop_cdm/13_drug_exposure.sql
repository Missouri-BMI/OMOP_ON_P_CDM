CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.drug_exposure( 
    drug_exposure_id integer NOT NULL,
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
) AS
SELECT 
    -- drug_exposure_id (NOT NULL)
    {% if site in ['mu', 'mu-id'] %}
        presc.prescribingid :: INTEGER AS drug_exposure_id
    {% elif site == 'gpc' %}
        ROW_NUMBER() OVER (ORDER BY presc.prescribingid)::INTEGER AS drug_exposure_id
    {% else %}
        presc.prescribingid :: INTEGER AS drug_exposure_id
    {% endif %}

    -- person_id (NOT NULL)
    {% if site in ['mu', 'mu-id'] %}
        , presc.patid :: INTEGER AS person_id
    {% elif site == 'gpc' %}
        , presc.patient_num :: INTEGER AS person_id
    {% else %}
        , presc.patid :: INTEGER AS person_id
    {% endif %}

    -- drug_concept_id (NOT NULL)
    , COALESCE(rxnorm.concept_id, 0)::INTEGER AS drug_concept_id

    -- drug_exposure_start_date (NOT NULL)
    , COALESCE(presc.rx_start_date, '1900-01-01')::DATE AS drug_exposure_start_date

    -- drug_exposure_start_datetime
    , presc.rx_start_date::TIMESTAMP AS drug_exposure_start_datetime

    -- drug_exposure_end_date (NOT NULL)
    , COALESCE(NULL, '1900-01-01')::DATE AS drug_exposure_end_date

    -- drug_exposure_end_datetime
    , NULL::TIMESTAMP AS drug_exposure_end_datetime

    -- verbatim_end_date
    , NULL::DATE AS verbatim_end_date

    -- drug_type_concept_id (NOT NULL)
    , 38000177::INTEGER AS drug_type_concept_id

    -- stop_reason
    , NULL::VARCHAR(20) AS stop_reason

    -- refills
    , NULL::INTEGER AS refills

    -- quantity
    , presc.rx_quantity::FLOAT AS quantity

    -- days_supply
    , presc.rx_days_supply::INTEGER AS days_supply

    -- sig
    , NULL::TEXT AS sig

    -- route_concept_id
    , COALESCE(
        CASE
            WHEN presc.rx_route = 'OT' THEN 44814649
            ELSE route.source_concept_id
        END, 0
      )::INTEGER AS route_concept_id

    -- lot_number
    , NULL::VARCHAR(50) AS lot_number

    -- provider_id
    , NULL::INTEGER AS provider_id

    -- visit_occurrence_id
    {% if site in ['mu', 'mu-id'] %}
        , presc.encounterid :: INTEGER AS visit_occurrence_id
    {% elif site == 'gpc' %}
        , presc.encounter_num ::INTEGER AS visit_occurrence_id
    {% else %}
        , presc.encounterid ::INTEGER AS visit_occurrence_id
    {% endif %}

    -- visit_detail_id
    , NULL::INTEGER AS visit_detail_id

    -- drug_source_value (truncate to 50 chars)
    , COALESCE(LEFT(raw_rx_med_name, 50), ' ')::VARCHAR(50) AS drug_source_value

    -- drug_source_concept_id
    , COALESCE(rxnorm.concept_id, 0)::INTEGER AS drug_source_concept_id

    -- route_source_value (truncate to 50 chars)
    , LEFT(COALESCE(presc.rx_route, ''), 50)::VARCHAR(50) AS route_source_value

    -- dose_unit_source_value (truncate to 50 chars)
    , LEFT(COALESCE(presc.rx_dose_ordered_unit, ''), 50)::VARCHAR(50) AS dose_unit_source_value

FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ prescribing_table }} presc
LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.concept rxnorm
    ON presc.rxnorm_cui = rxnorm.concept_code
    AND rxnorm.vocabulary_id = 'RxNorm'
    AND rxnorm.standard_concept = 'S'
LEFT JOIN {{ cdm_db }}.{{ crosswalk }}.omop_pcornet_valueset_mapping route
    ON route.pcornet_field_name = 'RX ROUTE'
    AND presc.rx_route = route.pcornet_valueset_item;
