Create or replace view {cdm_db}.{cdm_schema}.procedure_occurrence AS
SELECT
        procedures.proceduresid::INTEGER AS procedure_occurrence_id,
        procedures.patient_num::INTEGER AS person_id,
        case
                        when c_hcpcs.concept_id is not null then c_hcpcs.concept_id
                        when procedures.px_type='CH' then c_cpt.concept_id
                        when procedures.px_type='10' then c_icd9.concept_id
                        when procedures.px_type='09' then c_icd10.concept_id
                        else 0 
          end::INTEGER as procedure_concept_id,
   coalesce(procedures.px_date,procedures.admit_date)::DATE AS procedure_date,
        procedures.admit_date::TIMESTAMP AS procedure_datetime,
        NULL::DATE AS procedure_end_date,
        NULL::TIMESTAMP AS procedure_end_datetime,
        case 
                        when procedures.px_source = 'OD' then 38000275
                        when procedures.px_source ='BI' then 44786631
                        else 44814650
          end::INTEGER AS procedure_type_concept_id,
   0::INTEGER AS modifier_concept_id,
        NULL::INTEGER AS quantity,
        procedures.providerid::INTEGER AS provider_id,
        procedures.encounter_num::INTEGER AS visit_occurrence_id,
        NULL::INTEGER AS visit_detail_id,
        procedures.px::VARCHAR(50) AS procedure_source_value,
        case
                        when c_hcpcs.concept_id is not null then c_hcpcs.concept_id
                        when procedures.px_type='CH' then c_cpt.concept_id
                        when procedures.px_type='10' then c_icd9.concept_id
                        when procedures.px_type='09' then c_icd10.concept_id
          else 0 
          end::INTEGER as procedure_source_concept_id,
        NULL::VARCHAR(50) AS modifier_source_value

FROM {pcornet_db}.{pcornet_schema}.GPC_DEID_procedures procedures
left join {cdm_db}.{vocabulary}.CONCEPT c_hcpcs
          on procedures.px=c_hcpcs.concept_code and procedures.px_type='CH' and c_hcpcs.vocabulary_id='HCPCS' and procedures.px RLIKE '[A-Z]'
left join {cdm_db}.{vocabulary}.CONCEPT c_cpt
          on procedures.px=c_cpt.concept_code and procedures.px_type='CH' and c_cpt.vocabulary_id='CPT4'
left join {cdm_db}.{vocabulary}.CONCEPT c_icd10
          on procedures.px=c_icd10.concept_code and procedures.px_type='10' and c_cpt.vocabulary_id='ICD10CM'
 left join {cdm_db}.{vocabulary}.CONCEPT c_icd9
          on procedures.px=c_icd9.concept_code and procedures.px_type='09' and c_cpt.vocabulary_id='ICD9CM';
