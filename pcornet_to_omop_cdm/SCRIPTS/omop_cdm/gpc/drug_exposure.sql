create or replace view {cdm_db}.{cdm_schema}.drug_exposure
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY presc.prescribingid) ::INTEGER AS drug_exposure_id,

    presc.patient_num::INTEGER                                                                       AS person_id,

    coalesce(rxnorm.concept_id, 0)::INTEGER                                                    AS drug_concept_id,

    presc.rx_start_date::DATE                                                                  AS drug_exposure_start_date,

    presc.rx_start_date::DATETIME                                                              AS drug_exposure_start_datetime,

       NULL::DATE                                                                                 AS drug_exposure_end_date,

       NULL::TIMESTAMP                                                                            AS drug_exposure_end_datetime,

       NULL::DATE                                                                                 AS verbatim_end_date,

       38000177::INTEGER                                                                          AS drug_type_concept_id,

       NULL::VARCHAR(50)                                                                          AS stop_reason,

       NULL::INTEGER                                                                              AS refills,

       presc.rx_quantity::NUMERIC                                                                 AS quantity,

       presc.rx_days_supply::INTEGER                                                              AS days_supply,

       NULL::TEXT                                                                                 AS sig,

       coalesce(
               case
                   when presc.rx_route = 'OT' then 44814649
                   else route.source_concept_id
                   end, 0)::INTEGER                                                               AS route_concept_id,

       NULL::VARCHAR(50)                                                                          AS lot_number,

       presc.RX_PROVIDERID::INTEGER                                                               AS provider_id,

       presc.encounter_num::INTEGER                                                                 AS visit_occurrence_id,

       NULL::INTEGER                                                                              AS visit_detail_id,

       coalesce(left(raw_rx_med_name, 200), ' ') || '|' || coalesce(rxnorm_cui, ' ')::VARCHAR(50) AS drug_source_value,

       coalesce(rxnorm.concept_id, 0)::INTEGER                                                    AS drug_source_concept_id,

       presc.rx_route::VARCHAR(50)                                                                AS route_source_value,

       presc.rx_dose_ordered_unit::VARCHAR(50)                                                    AS dose_unit_source_value
FROM {pcornet_db}.{pcornet_schema}.GPC_DEID_prescribing presc
         left join {cdm_db}.{vocabulary}.concept rxnorm
                   on presc.rxnorm_cui = rxnorm.concept_code and vocabulary_id = 'RxNorm' and standard_concept = 'S'
         left join {cdm_db}.{crosswalk}.OMOP_PCORNET_VALUESET_MAPPING route
                   on pcornet_field_name = 'RX ROUTE' and presc.rx_route = route.PCORNET_VALUESET_ITEM;
