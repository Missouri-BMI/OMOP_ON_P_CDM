
--TODO: dispensingid, prescribingid, medadminid id can have same id, cannot be used in drug_exposure_id
create or replace view CDM.drug_exposure
AS
--dispensing
SELECT disp.dispensingid::INTEGER                 AS drug_exposure_id,

       disp.patid::INTEGER                        AS person_id,

       coalesce(ndc.concept_id, 0)::INTEGER AS drug_concept_id,

       disp.dispense_date::DATE                   AS drug_exposure_start_date,

       disp.dispense_date::DATETIME               AS drug_exposure_start_datetime,

       NULL::DATE                                 AS drug_exposure_end_date,

       NULL::TIMESTAMP                            AS drug_exposure_end_datetime,

       NULL::DATE                                 AS verbatim_end_date,

       38000175::INTEGER                          AS drug_type_concept_id,

       NULL::VARCHAR(50)                          AS stop_reason,

       NULL::INTEGER                              AS refills,

       disp.dispense_amt::NUMERIC                 AS quantity,

       disp.dispense_sup::INTEGER                 AS days_supply,

       NULL::TEXT                                 AS sig,

       coalesce(
               case
                   when disp.dispense_route = 'OT' then 44814649
                   else route.source_concept_id
                   end, 0)::INTEGER               AS route_concept_id,

       NULL::VARCHAR(50)                          AS lot_number,

       NULL::INTEGER                              AS provider_id,

       NULL::INTEGER                              AS visit_occurrence_id,

       NULL::INTEGER                              AS visit_detail_id,

       ndc::VARCHAR(50)                           AS drug_source_value,

       (case
            when dispense_source = 'OD' then 38000275
            when dispense_source = 'BI' then 44786630
            else 44814653
           end)::INTEGER                          AS drug_source_concept_id,

       disp.dispense_route::VARCHAR(50)           AS route_source_value,

       disp.dispense_dose_disp_unit::VARCHAR(50)  AS dose_unit_source_value

FROM DEIDENTIFIED_PCORNET_CDM.CDM.deid_dispensing disp
         left join vocabulary.concept ndc
                   on disp.ndc = ndc.concept_code and ndc.vocabulary_id = 'NDC' and ndc.invalid_reason is null
         left join CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING route
                   on pcornet_field_name = 'DISPENSE ROUTE' and disp.dispense_route = route.PCORNET_VALUESET_ITEM

union

--prescribing
SELECT presc.prescribingid::INTEGER                                                               AS drug_exposure_id,

       presc.patid::INTEGER                                                                       AS person_id,

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

       presc.encounterid::INTEGER                                                                 AS visit_occurrence_id,

       NULL::INTEGER                                                                              AS visit_detail_id,

       coalesce(left(raw_rx_med_name, 200), ' ') || '|' || coalesce(rxnorm_cui, ' ')::VARCHAR(50) AS drug_source_value,

       coalesce(rxnorm.concept_id, 0)::INTEGER                                                    AS drug_source_concept_id,

       presc.rx_route::VARCHAR(50)                                                                AS route_source_value,

       presc.rx_dose_ordered_unit::VARCHAR(50)                                                    AS dose_unit_source_value

FROM DEIDENTIFIED_PCORNET_CDM.CDM.deid_prescribing presc
         left join vocabulary.concept rxnorm
                   on presc.rxnorm_cui = rxnorm.concept_code and vocabulary_id = 'RxNorm' and standard_concept = 'S'
         left join CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING route
                   on pcornet_field_name = 'RX ROUTE' and presc.rx_route = route.PCORNET_VALUESET_ITEM

union

--med admin
SELECT medadmin.medadminid::INTEGER                                                                    AS drug_exposure_id,

       medadmin.patid::INTEGER                                                                         AS person_id,

       coalesce(
               case
                   when medadmin_type = 'ND' then ndc.concept_id
                   when medadmin_type = 'RX' then rxnorm.concept_id
                   else 0
                   end,
               0)::INTEGER                                                                             AS drug_concept_id,

       medadmin_start_date::DATE                                                                       AS drug_exposure_start_date,

       (date(medadmin_start_date) || ' ' || medadmin_start_time)::DATETIME                             AS drug_exposure_start_datetime,

       NULL::DATE                                                                                      AS drug_exposure_end_date,

       NULL::TIMESTAMP                                                                                 AS drug_exposure_end_datetime,

       NULL::DATE                                                                                      AS verbatim_end_date,

       38000180::INTEGER                                                                               AS drug_type_concept_id,

       NULL::VARCHAR(50)                                                                               AS stop_reason,

       NULL::INTEGER                                                                                   AS refills,

       NULL::NUMERIC                                                                                   AS quantity,

       NULL::INTEGER                                                                                   AS days_supply,

       NULL::TEXT                                                                                      AS sig,

       coalesce(
               case
                   when medadmin.medadmin_route = 'OT' then 44814649
                   else route.source_concept_id::int
                   end,
               0)::INTEGER                                                                             AS route_concept_id,

       NULL::VARCHAR(50)                                                                               AS lot_number,

       MEDADMIN_PROVIDERID::INTEGER                                                                    AS provider_id,

       encounterid::INTEGER                                                                            AS visit_occurrence_id,

       NULL::INTEGER                                                                                   AS visit_detail_id,

       coalesce(left(raw_medadmin_med_name, 200) || '...', ' ') || '|' ||
       coalesce(medadmin_code, ' ')                                                                    AS drug_source_value,

       (case
            when medadmin_type = 'ND' then ndc.concept_id
            when medadmin_type = 'RX' then rxnorm.concept_id
            else 0 end)::INTEGER                                                                       AS drug_source_concept_id,

       medadmin_route::VARCHAR(50)                                                                     AS route_source_value,

       medadmin_dose_admin_unit::VARCHAR(50)                                                           AS dose_unit_source_value

FROM DEIDENTIFIED_PCORNET_CDM.CDM.deid_med_admin medadmin
         left join vocabulary.concept ndc
                   on medadmin.medadmin_code = ndc.concept_code and medadmin_type = 'ND' and
                      ndc.vocabulary_id = 'NDC' and ndc.invalid_reason is null
         left join vocabulary.concept rxnorm
                   on medadmin.medadmin_code = rxnorm.concept_code and medadmin_type = 'RX' and
                      rxnorm.vocabulary_id = 'RxNorm' and rxnorm.standard_concept = 'S'
         left join CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING route
                   on pcornet_field_name = 'MEDADMIN ROUTE' and medadmin.medadmin_route = route.PCORNET_VALUESET_ITEM;

    

