create or replace view OMOP_CDM.CDM.deid_condition_occurrence as

SELECT
    distinct
    diagnosis.diagnosisid::INTEGER AS condition_occurrence_id,

    diagnosis.patid::INTEGER AS person_id,
    
coalesce(case
        when diagnosis.dx_type='09' then cr_icd9.concept_id_2
        when diagnosis.dx_type='10' then cr_icd10.concept_id_2
        when diagnosis.dx_type='SM' then c_snomed.concept_id
    else
     0
    end,44814650)::INTEGER as condition_concept_id,
    --concept_id::INTEGER AS condition_concept_id,

    coalesce(diagnosis.dx_date,diagnosis.admit_date)::DATE AS condition_start_date,

    coalesce(diagnosis.dx_date,diagnosis.admit_date)::timestamp AS condition_start_datetime,
    NULL::DATE AS condition_end_date,
    NULL::timestamp AS condition_end_datetime,

    case  

        when enc_type='ED' and dx_origin='BI' and pdx='P'then 2000001282 

        when enc_type='ED' and dx_origin='OD' and pdx='P'then 2000001280 

        when enc_type='ED' and dx_origin='CL' and pdx='P'then 2000001281 

        when enc_type='ED' and dx_origin='BI' and pdx='S'then 2000001284 

        when enc_type='ED' and dx_origin='OD' and pdx='S'then 2000001283 

        when enc_type='ED' and dx_origin='CL' and pdx='S'then 2000001285 

        when enc_type in ('AV','OA','TH') and dx_origin='BI' and pdx='P'then 2000000096 

        when enc_type in ('AV','OA','TH') and dx_origin='OD' and pdx='P'then 2000000095 

        when enc_type in ('AV','OA','TH') and dx_origin='CL' and pdx='P'then 2000000097 

        when enc_type in ('AV','OA','TH') and dx_origin='BI' and pdx='S'then 2000000102 

        when enc_type in ('AV','OA','TH') and dx_origin='OD' and pdx='S'then 2000000101 

        when enc_type in ('AV','OA','TH') and dx_origin='CL' and pdx='S'then 2000000103 

        when enc_type in ('IP','OS','IS','EI') and dx_origin='BI' and pdx='P'then 2000000093 

        when enc_type in ('IP','OS','IS','EI') and dx_origin='OD' and pdx='P'then 2000000092 

        when enc_type in ('IP','OS','IS','EI') and dx_origin='CL' and pdx='P'then 2000000094 

        when enc_type in ('IP','OS','IS','EI') and dx_origin='BI' and pdx='S'then 2000000099 

        when enc_type in ('IP','OS','IS','EI') and dx_origin='OD' and pdx='S'then 2000000098 

        when enc_type in ('IP','OS','IS','EI') and dx_origin='CL' and pdx='S'then 2000000100 

    else  

        32817 --EHR

    end::INTEGER  as condition_type_concept_id,
    4230359::INTEGER AS condition_status_concept_id,   
    /*
    case  
    when pdx = 'P' then 32902 
    when pdx = 'S' then 32908
    when pdx = 'P' and DX_SOURCE = 'DI' then 32903
     when pdx = 'S' and DX_SOURCE = 'DI' then 32909  AS condition_status_concept_id,
*/
    NULL::varchar(20) AS stop_reason,

    diagnosis.providerid::INTEGER AS provider_id,

    diagnosis.encounterid::INTEGER AS visit_occurrence_id,

 -- [!WARNING!] no source column found. See possible comment at the INSERT INTO
    NULL::INTEGER AS visit_detail_id,

   diagnosis.dx::varchar(50) AS condition_source_value,

   coalesce(case
        when diagnosis.dx_type='09' then c_icd9.concept_id
        when diagnosis.dx_type='10' then c_icd10.concept_id
        when diagnosis.dx_type='SM' then c_snomed.concept_id
    else
        0
    end,44814650)::INTEGER as condition_source_concept_id,
   diagnosis.dx_source::varchar(50) AS condition_status_source_value

FROM pcornet_cdm.CDM.deid_diagnosis diagnosis
left join OMOP_CDM.vocabulary.concept c_icd9 on diagnosis.dx=c_icd9.concept_code
    and c_icd9.vocabulary_id='ICD9CM' and diagnosis.dx_type='09'
left join OMOP_CDM.vocabulary.concept c_icd10 on diagnosis.dx=c_icd10.concept_code
    and c_icd10.vocabulary_id='ICD10CM' and diagnosis.dx_type='10'
left join OMOP_CDM.vocabulary.concept c_snomed on diagnosis.dx=c_snomed.concept_code
    and c_snomed.vocabulary_id='SNOMED' and diagnosis.dx_type='SM'
left join OMOP_CDM.vocabulary.concept_relationship cr_icd9
    on c_icd9.concept_id = cr_icd9.concept_id_1
    and cr_icd9.relationship_id='Maps to'
left join OMOP_CDM.vocabulary.concept_relationship cr_icd10
    on c_icd10.concept_id = cr_icd10.concept_id_1
    and cr_icd10.relationship_id='Maps to'
;
--left join OMOP_CDM.OMOP_CDM.vocabulary.CONCEPT on DX = CONCEPT_CODE and vocabulary_ID in ('ICD10CM', 'ICD9CM')
--left join pcornet_cdm.CDM_2023_APRIL.encounter


/*
select distinct domain_id, vocabulary_id from OMOP_CDM.VOCABULARIES.CONCEPT
select distinct DX, DX_TYPE, CONCEPT.* from OMOP_CDM.VOCABULARIES.CONCEPT
join pcornet_cdm.CDM_2023_APRIL.diagnosis
on concept_code = DX 
where vocabulary_ID like 'ICD10CM' and DOMAIN_ID = 'Condition' order by DX


select * from omop_cdm.OMOP_CDM.vocabulary.concept where concept_code like '%N99.3%'
*/