/*
    File        : concept_wise_counts
    Purpose     : 
    CreateDate  : 3/8/24
    UpdateDate  : 3/8/24
    Author      : Md Kamruz Zaman Rana
    GitHub      : kzraryan-mu
    Email       : mrkfw@umsystem.edu   
*/





call ANALYTICSDB.PUBLIC.GET_COLUMN_COMPLETENESS
     (
		'OMOP_CDM.DCQ.DEID_TABLE_COMPLETENESS', 'OMOP_CDM', 'CDM', ' and TABLE_NAME like ''DEID_%'''
     )
;


create or replace table OMOP_CDM.DCQ.CONCEPT_WISE_COUNTS
as
with CDMS as (
	             select 'OMOP'                    as CDM_NAME
		              , 'DEID_PERSON'             as TABLE_NAME
		              , 'Gender'                  as TYPE
		              , GENDER_CONCEPT_ID::string as CONCEPT
		              , count(distinct PERSON_ID) as N_PATIENT
		              , 0                         as N_ENCOUNTER
		              , count(distinct PERSON_ID) as N_PK
		              , count(*)                  as N_OCCURRENCE
	             from OMOP_CDM.CDM.DEID_PERSON
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'OMOP'                         as CDM_NAME
		              , 'DEID_PERSON'                  as TABLE_NAME
		              , 'Race'                         as TYPE
		              , RACE_SOURCE_CONCEPT_ID::string as CONCEPT
		              , count(distinct PERSON_ID)      as N_PATIENT
		              , 0                              as N_ENCOUNTER
		              , count(distinct PERSON_ID)      as N_PK
		              , count(*)                       as N_OCCURRENCE
	             from OMOP_CDM.CDM.DEID_PERSON
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'OMOP'                       as CDM_NAME
		              , 'DEID_PERSON'                as TABLE_NAME
		              , 'Ethnicity'                  as TYPE
		              , ETHNICITY_CONCEPT_ID::string as CONCEPT
		              , count(distinct PERSON_ID)    as N_PATIENT
		              , 0                            as N_ENCOUNTER
		              , count(distinct PERSON_ID)    as N_PK
		              , count(*)                     as N_OCCURRENCE
	             from OMOP_CDM.CDM.DEID_PERSON
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'OMOP'                                  as CDM_NAME
		              , 'DEID_PROCEDURE_OCCURRENCE'             as TABLE_NAME
		              , 'PROCEDURE'                             as TYPE
		              , PROCEDURE_SOURCE_CONCEPT_ID::string     as CONCEPT
		              , count(distinct PERSON_ID)               as N_PATIENT
		              , count(distinct VISIT_OCCURRENCE_ID)     as N_ENCOUNTER
		              , count(distinct PROCEDURE_OCCURRENCE_ID) as N_PK
		              , count(*)                                as N_OCCURRENCE
	             from OMOP_CDM.CDM.DEID_PROCEDURE_OCCURRENCE
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'OMOP'                                  as CDM_NAME
		              , 'DEID_CONDITION_OCCURRENCE'             as TABLE_NAME
		              , 'CONDITION'                             as TYPE
		              , CONDITION_SOURCE_CONCEPT_ID::string     as CONCEPT
		              , count(distinct PERSON_ID)               as N_PATIENT
		              , count(distinct VISIT_OCCURRENCE_ID)     as N_ENCOUNTER
		              , count(distinct CONDITION_OCCURRENCE_ID) as N_PK
		              , count(*)                                as N_OCCURRENCE
	             from OMOP_CDM.CDM.DEID_CONDITION_OCCURRENCE
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'OMOP'                              as CDM_NAME
		              , 'DEID_DRUG_EXPOSURE'                as TABLE_NAME
		              , 'DRUG'                              as TYPE
		              , DRUG_SOURCE_CONCEPT_ID::string      as CONCEPT
		              , count(distinct PERSON_ID)           as N_PATIENT
		              , count(distinct VISIT_OCCURRENCE_ID) as N_ENCOUNTER
		              , count(distinct DRUG_EXPOSURE_ID)    as N_PK
		              , count(*)                            as N_OCCURRENCE
	             from OMOP_CDM.CDM.DEID_DRUG_EXPOSURE
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'PCORNET'             as CDM_NAME
		              , 'DEID_DEMOGRAPHIC'    as TABLE_NAME
		              , 'Sex'                 as TYPE
		              , 'Sex-' || SEX         as CONCEPT
		              , count(distinct PATID) as N_PATIENT
		              , 0                     as N_ENCOUNTER
		              , count(distinct PATID) as N_PK
		              , count(*)              as N_OCCURRENCE
	             from PCORNET_CDM.CDM.DEID_DEMOGRAPHIC
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'PCORNET'             as CDM_NAME
		              , 'DEID_DEMOGRAPHIC'    as TABLE_NAME
		              , 'Race'                as TYPE
		              , 'Race-' || RACE       as CONCEPT
		              , count(distinct PATID) as N_PATIENT
		              , 0                     as N_ENCOUNTER
		              , count(distinct PATID) as N_PK
		              , count(*)              as N_OCCURRENCE
	             from PCORNET_CDM.CDM.DEID_DEMOGRAPHIC
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'PCORNET'               as CDM_NAME
		              , 'DEID_DEMOGRAPHIC'      as TABLE_NAME
		              , 'Hispanic'              as TYPE
		              , 'Hispanic-' || HISPANIC as CONCEPT
		              , count(distinct PATID)   as N_PATIENT
		              , 0                       as N_ENCOUNTER
		              , count(distinct PATID)   as N_PK
		              , count(*)                as N_OCCURRENCE
	             from PCORNET_CDM.CDM.DEID_DEMOGRAPHIC
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'PCORNET'                    as CDM_NAME
		              , 'DEID_PROCEDURES'            as TABLE_NAME
		              , PX_TYPE                      as TYPE
		              , PX::string                   as CONCEPT
		              , count(distinct PATID)        as N_PATIENT
		              , count(distinct ENCOUNTERID)  as N_ENCOUNTER
		              , count(distinct PROCEDURESID) as N_PK
		              , count(*)                     as N_OCCURRENCE
	             from PCORNET_CDM.CDM.DEID_PROCEDURES
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'PCORNET'                   as CDM_NAME
		              , 'DEID_DIAGNOSIS'            as TABLE_NAME
		              , DX_TYPE                     as TYPE
		              , DX::string                  as CONCEPT
		              , count(distinct PATID)       as N_PATIENT
		              , count(distinct ENCOUNTERID) as N_ENCOUNTER
		              , count(distinct DIAGNOSISID) as N_PK
		              , count(*)                    as N_OCCURRENCE
	             from PCORNET_CDM.CDM.DEID_DIAGNOSIS
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'PCORNET'                     as CDM_NAME
		              , 'DEID_PRESCRIBING'            as TABLE_NAME
		              , 'RXNORM'                      as TYPE
		              , RXNORM_CUI::string            as CONCEPT
		              , count(distinct PATID)         as N_PATIENT
		              , count(distinct ENCOUNTERID)   as N_ENCOUNTER
		              , count(distinct PRESCRIBINGID) as N_PK
		              , count(*)                      as N_OCCURRENCE
	             from PCORNET_CDM.CDM.DEID_PRESCRIBING
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'PCORNET'                   as CDM_NAME
		              , 'DEID_MED_ADMIN'            as TABLE_NAME
		              , MEDADMIN_TYPE               as TYPE
		              , MEDADMIN_CODE::string       as CONCEPT
		              , count(distinct PATID)       as N_PATIENT
		              , count(distinct ENCOUNTERID) as N_ENCOUNTER
		              , count(distinct MEDADMINID)  as N_PK
		              , count(*)                    as N_OCCURRENCE
	             from PCORNET_CDM.CDM.DEID_MED_ADMIN
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT

	             union all

	             select 'PCORNET'                    as CDM_NAME
		              , 'DEID_DISPENSING'            as TABLE_NAME
		              , 'ND'                         as TYPE
		              , NDC::string                  as CONCEPT
		              , count(distinct PATID)        as N_PATIENT
		              , 0                            as N_ENCOUNTER
		              , count(distinct DISPENSINGID) as N_PK
		              , count(*)                     as N_OCCURRENCE
	             from PCORNET_CDM.CDM.DEID_DISPENSING
	             group by CDM_NAME
	                    , TABLE_NAME
	                    , TYPE
	                    , CONCEPT
             )
select *
from CDMS
;



create or replace table OMOP_CDM.DCQ.CONCEPT_WISE_COUNTS2
as
with CDMS   as (
	               select 'OMOP'                                                          as CDM_NAME
		                , 'DEID_PROCEDURE_OCCURRENCE'                                     as TABLE_NAME
		                , 'PROCEDURE'                                                     as TYPE
		                , coalesce(PROCEDURE_SOURCE_CONCEPT_ID::string, 'DCQ_NOT_MAPPED') as CONCEPT
		                , count(distinct PERSON_ID)                                       as N_PATIENT
		                , count(distinct VISIT_OCCURRENCE_ID)                             as N_ENCOUNTER
		                , count(distinct PROCEDURE_OCCURRENCE_ID)                         as N_PK
		                , count(*)                                                        as N_OCCURRENCE
	               from OMOP_CDM.CDM.DEID_PROCEDURE_OCCURRENCE
	               group by CDM_NAME
	                      , TABLE_NAME
	                      , TYPE
	                      , CONCEPT

	               union all

	               select 'OMOP'                                                          as CDM_NAME
		                , 'DEID_CONDITION_OCCURRENCE'                                     as TABLE_NAME
		                , 'CONDITION'                                                     as TYPE
		                , coalesce(CONDITION_SOURCE_CONCEPT_ID::string, 'DCQ_NOT_MAPPED') as CONCEPT
		                , count(distinct PERSON_ID)                                       as N_PATIENT
		                , count(distinct VISIT_OCCURRENCE_ID)                             as N_ENCOUNTER
		                , count(distinct CONDITION_OCCURRENCE_ID)                         as N_PK
		                , count(*)                                                        as N_OCCURRENCE
	               from OMOP_CDM.CDM.DEID_CONDITION_OCCURRENCE
	               group by CDM_NAME
	                      , TABLE_NAME
	                      , TYPE
	                      , CONCEPT

	               union all

	               select 'OMOP'                                                     as CDM_NAME
		                , 'DEID_DRUG_EXPOSURE'                                       as TABLE_NAME
		                , 'DRUG'                                                     as TYPE
		                , coalesce(DRUG_SOURCE_CONCEPT_ID::string, 'DCQ_NOT_MAPPED') as CONCEPT
		                , count(distinct PERSON_ID)                                  as N_PATIENT
		                , count(distinct VISIT_OCCURRENCE_ID)                        as N_ENCOUNTER
		                , count(distinct DRUG_EXPOSURE_ID)                           as N_PK
		                , count(*)                                                   as N_OCCURRENCE
	               from OMOP_CDM.CDM.DEID_DRUG_EXPOSURE
	               group by CDM_NAME
	                      , TABLE_NAME
	                      , TYPE
	                      , CONCEPT

	               union all

	               select 'PCORNET'                                        as CDM_NAME
		                , 'DEID_PROCEDURES'                                as TABLE_NAME
		                , PX_TYPE                                          as TYPE
		                , coalesce(C.CONCEPT_ID::string, 'DCQ_NOT_MAPPED') as CONCEPT
		                , count(distinct PATID)                            as N_PATIENT
		                , count(distinct ENCOUNTERID)                      as N_ENCOUNTER
		                , count(distinct PROCEDURESID)                     as N_PK
		                , count(*)                                         as N_OCCURRENCE
	               from PCORNET_CDM.CDM.DEID_PROCEDURES           D
		                    left join OMOP_CDM.VOCABULARY.CONCEPT C
		                              on D.PX = C.CONCEPT_CODE
			                              and (
			                                 (D.PX_TYPE = 'CH' and C.CONCEPT_CODE = 'HCPCS' and D.PX rlike '[A-Z]')
				                                 or (D.PX_TYPE = 'CH' and C.CONCEPT_CODE = 'CPT4')
				                                 or (D.PX_TYPE = '09' and
				                                     (C.VOCABULARY_ID = 'ICD9Proc' or C.VOCABULARY_ID = 'ICD9ProcCN'))
				                                 or (D.PX_TYPE = '10' and C.CONCEPT_CODE = 'ICD10PCS')
			                                 )
	               group by CDM_NAME
	                      , TABLE_NAME
	                      , TYPE
	                      , CONCEPT

	               union all


	               select 'PCORNET'                                        as CDM_NAME
		                , 'DEID_DIAGNOSIS'                                 as TABLE_NAME
		                , DX_TYPE                                          as TYPE
		                , coalesce(C.CONCEPT_ID::string, 'DCQ_NOT_MAPPED') as CONCEPT
		                , count(distinct PATID)                            as N_PATIENT
		                , count(distinct ENCOUNTERID)                      as N_ENCOUNTER
		                , count(distinct DIAGNOSISID)                      as N_PK
		                , count(*)                                         as N_OCCURRENCE
	               from PCORNET_CDM.CDM.DEID_DIAGNOSIS            D
		                    left join OMOP_CDM.VOCABULARY.CONCEPT C
		                              on D.DX = C.CONCEPT_CODE
			                              and (
			                                 (D.DX_TYPE = '10' and C.CONCEPT_CODE = 'IC10CM')
				                                 or (D.DX_TYPE = '09' and C.CONCEPT_CODE = 'ICD9CM')
				                                 or (D.DX_TYPE = 'SM' and C.CONCEPT_CODE = 'SNOMED')
			                                 )
	               group by CDM_NAME
	                      , TABLE_NAME
	                      , TYPE
	                      , CONCEPT

	               union all

	               select 'PCORNET'                                        as CDM_NAME
		                , 'DEID_PRESCRIBING'                               as TABLE_NAME
		                , C.VOCABULARY_ID                                  as TYPE
		                , coalesce(C.CONCEPT_ID::string, 'DCQ_NOT_MAPPED') as CONCEPT
		                , count(distinct PATID)                            as N_PATIENT
		                , count(distinct ENCOUNTERID)                      as N_ENCOUNTER
		                , count(distinct PRESCRIBINGID)                    as N_PK
		                , count(*)                                         as N_OCCURRENCE
	               from PCORNET_CDM.CDM.DEID_PRESCRIBING          D
		                    left join OMOP_CDM.VOCABULARY.CONCEPT C
		                              on C.CONCEPT_CODE = D.RXNORM_CUI
			                              and C.VOCABULARY_ID = 'RxNorm' and C.STANDARD_CONCEPT = 'S'
	               group by CDM_NAME
	                      , TABLE_NAME
	                      , TYPE
	                      , CONCEPT

	               union all

	               select 'PCORNET'                                        as CDM_NAME
		                , 'DEID_MED_ADMIN'                                 as TABLE_NAME
		                , C.VOCABULARY_ID                                  as TYPE
		                , coalesce(C.CONCEPT_ID::string, 'DCQ_NOT_MAPPED') as CONCEPT
		                , count(distinct PATID)                            as N_PATIENT
		                , count(distinct ENCOUNTERID)                      as N_ENCOUNTER
		                , count(distinct MEDADMINID)                       as N_PK
		                , count(*)                                         as N_OCCURRENCE
	               from PCORNET_CDM.CDM.DEID_MED_ADMIN            D
		                    left join OMOP_CDM.VOCABULARY.CONCEPT C
		                              on D.MEDADMIN_CODE = C.CONCEPT_CODE
			                              and D.MEDADMIN_TYPE = 'ND'
			                              and C.VOCABULARY_ID = 'NDC'
			                              and C.INVALID_REASON is null
	               group by CDM_NAME
	                      , TABLE_NAME
	                      , TYPE
	                      , CONCEPT

	               union all

	               select 'PCORNET'                                        as CDM_NAME
		                , 'DEID_DISPENSING'                                as TABLE_NAME
		                , C.VOCABULARY_ID                                  as TYPE
		                , coalesce(C.CONCEPT_ID::string, 'DCQ_NOT_MAPPED') as CONCEPT
		                , count(distinct PATID)                            as N_PATIENT
		                , 0                                                as N_ENCOUNTER
		                , count(distinct DISPENSINGID)                     as N_PK
		                , count(*)                                         as N_OCCURRENCE
	               from PCORNET_CDM.CDM.DEID_DISPENSING           D
		                    left join OMOP_CDM.VOCABULARY.CONCEPT C
		                              on D.NDC = C.CONCEPT_CODE
			                              and C.VOCABULARY_ID = 'NDC'
			                              and C.INVALID_REASON is null
	               group by CDM_NAME
	                      , TABLE_NAME
	                      , TYPE
	                      , CONCEPT
               )
   , MERGED as (
	               select C.CONCEPT_ID::string           as CONCEPT_ID
		                , C.CONCEPT_NAME
		                , C.VOCABULARY_ID::string        as VOCUBULARY_ID
		                , C.CONCEPT_CODE::string         as CONCEPT_CODE
		                , TYPE
		                , CDM_NAME || '__' || TABLE_NAME as CDM_TABLE
		                , N_PATIENT
		                , N_ENCOUNTER
		                , N_PK
		                , N_OCCURRENCE
	               from OMOP_CDM.VOCABULARY.CONCEPT C
		                    full outer join CDMS
		                                    on CONCEPT::string = C.CONCEPT_ID::string
               )
select *
from MERGED
;


create or replace table OMOP_CDM.DCQ.CONCEPT_WISE_COUNTS2
as
with N_PAT as (
	              select CONCEPT_ID
		               , CONCEPT_NAME
		               , VOCUBULARY_ID
		               , CONCEPT_CODE
		               , TYPE
	              from OMOP_CDM.DCQ.CONCEPT_WISE_COUNTS2
		              pivot (
		              max(N_PATIENT) for CDM_TABLE in
			              ('OMOP__DEID_CONDITION_OCCURRENCE'
			              ,'OMOP__DEID_PERSON'
			              ,'PCORNET__DEID_PROCEDURES'
			              ,'PCORNET__DEID_DISPENSING'
			              ,'PCORNET__DEID_DEMOGRAPHIC'
			              ,'OMOP__DEID_PROCEDURE_OCCURRENCE'
			              ,'OMOP__DEID_DRUG_EXPOSURE'
			              ,'PCORNET__DEID_PRESCRIBING'
			              ,'PCORNET__DEID_MED_ADMIN'
			              ,'PCORNET__DEID_DIAGNOSIS'

			              )
		              )
              )
   , N_ENC as (
	              select CONCEPT_ID
		               , CONCEPT_NAME
		               , VOCUBULARY_ID
		               , CONCEPT_CODE
		               , TYPE
	              from OMOP_CDM.DCQ.CONCEPT_WISE_COUNTS2
		              pivot (
		              max(N_ENCOUNTER) for CDM_TABLE in
			              ('OMOP__DEID_CONDITION_OCCURRENCE'
			              ,'OMOP__DEID_PERSON'
			              ,'PCORNET__DEID_PROCEDURES'
			              ,'PCORNET__DEID_DISPENSING'
			              ,'PCORNET__DEID_DEMOGRAPHIC'
			              ,'OMOP__DEID_PROCEDURE_OCCURRENCE'
			              ,'OMOP__DEID_DRUG_EXPOSURE'
			              ,'PCORNET__DEID_PRESCRIBING'
			              ,'PCORNET__DEID_MED_ADMIN'
			              ,'PCORNET__DEID_DIAGNOSIS'
			              )
		              )
              )


select CONCEPT_ID
	 , CONCEPT_NAME
	 , VOCUBULARY_ID
	 , CONCEPT_CODE
	 , TYPE
from OMOP_CDM.DCQ.CONCEPT_WISE_COUNTS2
	pivot (
	max(N_ENCOUNTER) for CDM_TABLE in
		('OMOP__DEID_CONDITION_OCCURRENCE'
		,'OMOP__DEID_PERSON'
		,'PCORNET__DEID_PROCEDURES'
		,'PCORNET__DEID_DISPENSING'
		,'PCORNET__DEID_DEMOGRAPHIC'
		,'OMOP__DEID_PROCEDURE_OCCURRENCE'
		,'OMOP__DEID_DRUG_EXPOSURE'
		,'PCORNET__DEID_PRESCRIBING'
		,'PCORNET__DEID_MED_ADMIN'
		,'PCORNET__DEID_DIAGNOSIS'
		)
	)
;



create or replace table OMOP_CDM.DCQ.CONCEPT_COMPARISON
as
select CONCEPT_ID
	 , CONCEPT_NAME
	 , VOCUBULARY_ID
	 , CONCEPT_CODE
	 , TYPE
	 , iff(CDM_TABLE = 'OMOP__DEID_PROCEDURE_OCCURRENCE', N_PATIENT, null)    as "OMOP__DEID_PROCEDURE_OCCURRENCE_N_PATIENT"
	 , iff(CDM_TABLE = 'PCORNET__DEID_PROCEDURES_', N_PATIENT, null)          as "PCORNET__DEID_PROCEDURES_N_PATIENT"
	 , iff(CDM_TABLE = 'OMOP__DEID_PROCEDURE_OCCURRENCE', N_ENCOUNTER, null)  as "OMOP__DEID_PROCEDURE_OCCURRENCE_N_ENCOUNTER"
	 , iff(CDM_TABLE = 'PCORNET__DEID_PROCEDURES_', N_ENCOUNTER, null)        as "PCORNET__DEID_PROCEDURES_N_ENCOUNTER"
	 , iff(CDM_TABLE = 'OMOP__DEID_PROCEDURE_OCCURRENCE', N_PK, null)         as "OMOP__DEID_PROCEDURE_OCCURRENCE_N_PK"
	 , iff(CDM_TABLE = 'PCORNET__DEID_PROCEDURES_', N_PK, null)               as "PCORNET__DEID_PROCEDURES_N_PK"
	 , iff(CDM_TABLE = 'OMOP__DEID_PROCEDURE_OCCURRENCE', N_OCCURRENCE, null) as "OMOP__DEID_PROCEDURE_OCCURRENCE_N_OCCURRENCE"
	 , iff(CDM_TABLE = 'PCORNET__DEID_PROCEDURES_', N_OCCURRENCE, null)       as "PCORNET__DEID_PROCEDURES_N_OCCURRENCE"

	 , iff(CDM_TABLE = 'OMOP__DEID_DRUG_EXPOSURE', N_PATIENT, null)           as "OMOP__DEID_DRUG_EXPOSURE_N_PATIENT"
	 , iff(CDM_TABLE = 'PCORNET__DEID_DISPENSING', N_PATIENT, null)           as "PCORNET__DEID_DISPENSING_N_PATIENT"
	 , iff(CDM_TABLE = 'PCORNET__DEID_PRESCRIBING', N_PATIENT, null)          as "PCORNET__DEID_PRESCRIBING_N_PATIENT"
	 , iff(CDM_TABLE = 'PCORNET__DEID_MED_ADMIN', N_PATIENT, null)            as "PCORNET__DEID_MED_ADMIN_N_PATIENT"
	 , iff(CDM_TABLE = 'OMOP__DEID_DRUG_EXPOSURE', N_ENCOUNTER, null)         as "OMOP__DEID_DRUG_EXPOSURE_N_ENCOUNTER"
	 , iff(CDM_TABLE = 'PCORNET__DEID_DISPENSING', N_ENCOUNTER, null)         as "PCORNET__DEID_DISPENSING_N_ENCOUNTER"
	 , iff(CDM_TABLE = 'PCORNET__DEID_PRESCRIBING', N_ENCOUNTER, null)        as "PCORNET__DEID_PRESCRIBING_N_ENCOUNTER"
	 , iff(CDM_TABLE = 'PCORNET__DEID_MED_ADMIN', N_ENCOUNTER, null)          as "PCORNET__DEID_MED_ADMIN_N_ENCOUNTER"
	 , iff(CDM_TABLE = 'OMOP__DEID_DRUG_EXPOSURE', N_PK, null)                as "OMOP__DEID_DRUG_EXPOSURE_N_PK"
	 , iff(CDM_TABLE = 'PCORNET__DEID_DISPENSING', N_PK, null)                as "PCORNET__DEID_DISPENSING_N_PK"
	 , iff(CDM_TABLE = 'PCORNET__DEID_PRESCRIBING', N_PK, null)               as "PCORNET__DEID_PRESCRIBING_N_PK"
	 , iff(CDM_TABLE = 'PCORNET__DEID_MED_ADMIN', N_PK, null)                 as "PCORNET__DEID_MED_ADMIN_N_PK"
	 , iff(CDM_TABLE = 'OMOP__DEID_DRUG_EXPOSURE', N_OCCURRENCE, null)        as "OMOP__DEID_DRUG_EXPOSURE_N_OCCURRENCE"
	 , iff(CDM_TABLE = 'PCORNET__DEID_DISPENSING', N_OCCURRENCE, null)        as "PCORNET__DEID_DISPENSING_N_OCCURRENCE"
	 , iff(CDM_TABLE = 'PCORNET__DEID_PRESCRIBING', N_OCCURRENCE, null)       as "PCORNET__DEID_PRESCRIBING_N_OCCURRENCE"
	 , iff(CDM_TABLE = 'PCORNET__DEID_MED_ADMIN', N_OCCURRENCE, null)         as "PCORNET__DEID_MED_ADMIN_N_OCCURRENCE"

	 , iff(CDM_TABLE = 'OMOP__DEID_CONDITION_OCCURRENCE', N_PATIENT, null)    as "OMOP__DEID_CONDITION_OCCURRENCE_N_PATIENT"
	 , iff(CDM_TABLE = 'PCORNET__DEID_DIAGNOSIS', N_PATIENT, null)            as "PCORNET__DEID_DIAGNOSIS_N_PATIENT"
	 , iff(CDM_TABLE = 'OMOP__DEID_CONDITION_OCCURRENCE', N_ENCOUNTER, null)  as "OMOP__DEID_CONDITION_OCCURRENCE_N_ENCOUNTER"
	 , iff(CDM_TABLE = 'PCORNET__DEID_DIAGNOSIS', N_ENCOUNTER, null)          as "PCORNET__DEID_DIAGNOSIS_N_ENCOUNTER"
	 , iff(CDM_TABLE = 'OMOP__DEID_CONDITION_OCCURRENCE', N_PK, null)         as "OMOP__DEID_CONDITION_OCCURRENCE_N_PK"
	 , iff(CDM_TABLE = 'PCORNET__DEID_DIAGNOSIS', N_PK, null)                 as "PCORNET__DEID_DIAGNOSIS_N_PK"
	 , iff(CDM_TABLE = 'OMOP__DEID_CONDITION_OCCURRENCE', N_OCCURRENCE, null) as "OMOP__DEID_CONDITION_OCCURRENCE_N_OCCURRENCE"
	 , iff(CDM_TABLE = 'PCORNET__DEID_DIAGNOSIS', N_OCCURRENCE, null)         as "PCORNET__DEID_DIAGNOSIS_N_OCCURRENCE"

from OMOP_CDM.DCQ.CONCEPT_WISE_COUNTS2
;
