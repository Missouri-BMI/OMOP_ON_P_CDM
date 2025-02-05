Create or replace table {cdm_db}.{cdm_schema}.visit_occurrence AS
(
SELECT 
    enc.encounter_num::INTEGER                                      AS visit_occurrence_id,
    enc.patient_num::INTEGER                                        AS person_id,
    coalesce(enctyp.source_concept_id, 0)::INTEGER                  AS visit_concept_id,
    date(enc.admit_date)::DATE                                      AS visit_start_date,
    -- CONCAT(date(enc.admit_date), ' ', enc.admit_time)::TIMESTAMP    AS visit_start_datetime,
    enc.admit_date::TIMESTAMP                                       AS visit_start_datetime,
    date(coalesce(enc.discharge_date, enc.admit_date))::DATE        AS visit_end_date,
    -- CONCAT(date(coalesce(enc.discharge_date, enc.admit_date)), ' ',
    -- coalesce(enc.discharge_time, enc.admit_time))::TIMESTAMP        AS visit_end_datetime,
    date(coalesce(enc.discharge_date, enc.admit_date)) :: TIMESTAMP AS visit_end_datetime,
    44818518::INTEGER                                               AS visit_type_concept_id,
    -- enc.providerid::INTEGER                                         AS provider_id,
    -1::INTEGER                                                     AS provider_id,

    NULL::INTEGER                                                   AS care_site_id,
    --cs.care_site_id::INTEGER                                        AS care_site_id,
    enc.raw_enc_type::VARCHAR(50)                                   AS visit_source_value,
    NULL::INTEGER                                                   AS visit_source_concept_id,

    as_map.source_concept_id::INTEGER                               AS admitted_from_concept_id,
    enc.raw_admitting_source::VARCHAR(50)                           AS admitted_from_source_value,

    ds_map.source_concept_id::INTEGER                               AS discharged_to_concept_id,
    CASE 
        WHEN LENGTH(enc.raw_discharge_status) > 50 
            THEN LEFT(TRIM(enc.raw_discharge_status), 50)
        ELSE enc.raw_discharge_status
    END                                                             AS discharged_to_source_value,

    NULL::INTEGER                                                   AS preceding_visit_occurrence_id

FROM {pcornet_db}.{pcornet_schema}.GPC_DEID_encounter enc
      /*   left join
     {cdm_db}.{cdm_schema}.care_site cs
     on enc.facilityid = cs.care_site_id */
    LEFT JOIN
     {cdm_db}.{crosswalk}.OMOP_PCORNET_VALUESET_MAPPING as_map
     ON as_map.PCORNET_FIELD_NAME = 'ADMITTING SOURCE'
     AND as_map.pcornet_table_name = 'ENCOUNTER'
     AND as_map.PCORNET_VALUESET_ITEM = enc.admitting_source
    LEFT JOIN
     {cdm_db}.{crosswalk}.OMOP_PCORNET_VALUESET_MAPPING ds_map
     ON ds_map.PCORNET_FIELD_NAME = 'DISCHARGE STATUS'
     and ds_map.pcornet_table_name = 'ENCOUNTER'
     AND ds_map.PCORNET_VALUESET_ITEM = enc.discharge_status
    left join
     {cdm_db}.{crosswalk}.OMOP_PCORNET_VALUESET_MAPPING enctyp
     on enctyp.PCORNET_VALUESET_ITEM = enc.enc_type
     and enctyp.PCORNET_FIELD_NAME = 'ENC TYPE' 
     and enctyp.pcornet_table_name = 'ENCOUNTER'
     --and source_concept_id not in ('2000000469','42898160')
    );
