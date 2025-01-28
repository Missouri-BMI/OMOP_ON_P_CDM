
Create or replace view OMOP_CDM.CDM.deid_visit_occurrence AS
(SELECT
    enc.encounterid::INTEGER AS visit_occurrence_id,

    enc.patid::INTEGER AS person_id,

    COALESCE(typ.target_concept_id, 0)::INTEGER AS visit_concept_id,

    date(enc.admit_date)::DATE AS visit_start_date,

    CONCAT(date(enc.admit_date), ' ', enc.admit_time)::TIMESTAMP AS visit_start_datetime,

    date(coalesce(enc.discharge_date, enc.admit_date))::DATE AS visit_end_date,

    CONCAT(date(coalesce(enc.discharge_date, enc.admit_date)), ' ', enc.discharge_time)::TIMESTAMP AS visit_end_datetime,

    44818518::INTEGER AS visit_type_concept_id,

    enc.providerid::INTEGER AS provider_id,

    NULL::INTEGER AS care_site_id,

    enc.raw_enc_type::VARCHAR(50) AS visit_source_value,

    0::INTEGER AS visit_source_concept_id,
    vsrc.target_concept_id::INTEGER AS admitted_from_concept_id,
    enc.raw_admitting_source::VARCHAR(50) AS admitted_from_source_value,
    disp.target_concept_id::INTEGER AS discharged_to_concept_id,
    enc.raw_discharge_status::VARCHAR(50) AS discharged_to_source_value,
    NULL::INTEGER AS preceding_visit_occurrence_id

FROM pcornet_cdm.CDM.deid_encounter enc
LEFT JOIN OMOP_CDM.CROSSWALK.p2o_admitting_source_xwalk vsrc ON vsrc.cdm_tbl = 'ENCOUNTER'
                                                       AND vsrc.cdm_source = 'PCORnet'
                                                        AND vsrc.src_admitting_source_type = enc.admitting_source
LEFT JOIN OMOP_CDM.CROSSWALK.p2o_discharge_status_xwalk  disp ON disp.cdm_tbl = 'ENCOUNTER'
                                                    AND disp.cdm_source = 'PCORnet'
                                                    AND disp.src_discharge_status = enc.discharge_status
left join OMOP_CDM.VOCABULARY.VISIT_XWALK typ 
				on typ.src_visit_type = enc.enc_type 
													

);
