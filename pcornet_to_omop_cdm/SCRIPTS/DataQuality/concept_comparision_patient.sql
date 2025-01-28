/*

 created by Rana in April. This query pulls all concepts from omop concept table(athena) and all concept ids from omop cdm tables

 */


create or replace table OMOP_CDM.DCQ.CONCEPT_COMPARISON_PATIENT_WISE_May_23("CONCEPT_ID" bigint not null,
                                                                     "CONCEPT_NAME" string(255) not null,
                                                                     "DOMAIN_ID" string(20) not null,
                                                                     "VOCABULARY_ID" string(20) not null,
                                                                     "CONCEPT_CLASS_ID" string(20) not null,
                                                                     "CONCEPT_CODE" string(50) not null,
                                                                     "OMOP_N_PAT" bigint, "PCORNET_N_PAT" bigint) as
select *
from (
         select "CONCEPT_ID"
             , "CONCEPT_NAME"
             , "DOMAIN_ID"
             , "VOCABULARY_ID"
             , "CONCEPT_CLASS_ID"
             , "CONCEPT_CODE"
             , "OMOP_N_PAT"
             , "PCORNET_N_PAT"
         from (
                 select *
                 from ((
                          select "CONCEPT_ID"       as "CONCEPT_ID"
                              , "CONCEPT_NAME"     as "CONCEPT_NAME"
                              , "DOMAIN_ID"        as "DOMAIN_ID"
                              , "VOCABULARY_ID"    as "VOCABULARY_ID"
                              , "CONCEPT_CLASS_ID" as "CONCEPT_CLASS_ID"
                              , "CONCEPT_CODE"     as "CONCEPT_CODE"
                              , "OMOP_N_PAT"       as "OMOP_N_PAT"
                          from (
                                  select "CONCEPT_ID"
                                      , "CONCEPT_NAME"
                                      , "DOMAIN_ID"
                                      , "VOCABULARY_ID"
                                      , "CONCEPT_CLASS_ID"
                                      , "CONCEPT_CODE"
                                      , "N_PAT" as "OMOP_N_PAT"
                                  from (
                                          select *
                                          from ((
                                                   select "CONCEPT_ID"       as "CONCEPT_ID"
                                                       , "CONCEPT_NAME"     as "CONCEPT_NAME"
                                                       , "DOMAIN_ID"        as "DOMAIN_ID"
                                                       , "VOCABULARY_ID"    as "VOCABULARY_ID"
                                                       , "CONCEPT_CLASS_ID" as "CONCEPT_CLASS_ID"
                                                       , "CONCEPT_CODE"     as "CONCEPT_CODE"
                                                   from OMOP_CDM.CDM.CONCEPT
                                                ) as SNOWPARK_LEFT left outer join (
                                                                                      select "CONCEPT" as "CONCEPT", "N_PAT" as "N_PAT"
                                                                                      from (
                                                                                              select "CONCEPT", count(distinct "PATID") as "N_PAT"
                                                                                              from (
                                                                                                      (
                                                                                                         select "PERSON_ID"                            as "PATID"
                                                                                                             , cast("PROCEDURE_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.PROCEDURE_OCCURRENCE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                                 as "PATID"
                                                                                                             , cast("PROCEDURE_TYPE_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.PROCEDURE_OCCURRENCE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                           as "PATID"
                                                                                                             , cast("MODIFIER_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.PROCEDURE_OCCURRENCE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                                   as "PATID"
                                                                                                             , cast("PROCEDURE_SOURCE_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.PROCEDURE_OCCURRENCE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                            as "PATID"
                                                                                                             , cast("CONDITION_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.CONDITION_OCCURRENCE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                                 as "PATID"
                                                                                                             , cast("CONDITION_TYPE_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.CONDITION_OCCURRENCE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                                   as "PATID"
                                                                                                             , cast("CONDITION_STATUS_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.CONDITION_OCCURRENCE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                                   as "PATID"
                                                                                                             , cast("CONDITION_SOURCE_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.CONDITION_OCCURRENCE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                       as "PATID"
                                                                                                             , cast("DRUG_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.DRUG_EXPOSURE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                            as "PATID"
                                                                                                             , cast("DRUG_TYPE_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.DRUG_EXPOSURE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                        as "PATID"
                                                                                                             , cast("ROUTE_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.DRUG_EXPOSURE
                                                                                                      )
                                                                                                      union
                                                                                                      (
                                                                                                         select "PERSON_ID"                              as "PATID"
                                                                                                             , cast("DRUG_SOURCE_CONCEPT_ID" as string) as "CONCEPT"
                                                                                                         from OMOP_CDM.DEID_CDM.DRUG_EXPOSURE
                                                                                                      )
                                                                                                   )
                                                                                              group by "CONCEPT"
                                                                                           )
                                                                                   ) as SNOWPARK_RIGHT
                                                on ("CONCEPT_ID" = "CONCEPT"))
                                       )
                               )
                       ) as SNOWPARK_LEFT inner join (
                                                        select "CONCEPT_ID"       as "CONCEPT_ID"
                                                            , "CONCEPT_NAME"     as "CONCEPT_NAME"
                                                            , "DOMAIN_ID"        as "DOMAIN_ID"
                                                            , "VOCABULARY_ID"    as "VOCABULARY_ID"
                                                            , "CONCEPT_CLASS_ID" as "CONCEPT_CLASS_ID"
                                                            , "CONCEPT_CODE"     as "CONCEPT_CODE"
                                                            , "PCORNET_N_PAT"    as "PCORNET_N_PAT"
                                                        from (
                                                                select "CONCEPT_ID"
                                                                    , "CONCEPT_NAME"
                                                                    , "DOMAIN_ID"
                                                                    , "VOCABULARY_ID"
                                                                    , "CONCEPT_CLASS_ID"
                                                                    , "CONCEPT_CODE"
                                                                    , "N_PAT" as "PCORNET_N_PAT"
                                                                from (
                                                                        select *
                                                                        from ((
                                                                                 select "CONCEPT_ID"       as "CONCEPT_ID"
                                                                                     , "CONCEPT_NAME"     as "CONCEPT_NAME"
                                                                                     , "DOMAIN_ID"        as "DOMAIN_ID"
                                                                                     , "VOCABULARY_ID"    as "VOCABULARY_ID"
                                                                                     , "CONCEPT_CLASS_ID" as "CONCEPT_CLASS_ID"
                                                                                     , "CONCEPT_CODE"     as "CONCEPT_CODE"
                                                                                 from OMOP_CDM.CDM.CONCEPT
                                                                              ) as SNOWPARK_LEFT left outer join (
                                                                                                                    select "CONCEPT" as "CONCEPT", "N_PAT" as "N_PAT"
                                                                                                                    from (
                                                                                                                            select "CONCEPT", count(distinct "PATID") as "N_PAT"
                                                                                                                            from (
                                                                                                                                    (
                                                                                                                                       select "PATID" as "PATID", cast("PX" as string) as "CONCEPT"
                                                                                                                                       from PCORNET_CDM.CDM.DEID_PROCEDURES
                                                                                                                                    )
                                                                                                                                    union
                                                                                                                                    (
                                                                                                                                       select "PATID" as "PATID", cast("DX" as string) as "CONCEPT"
                                                                                                                                       from PCORNET_CDM.CDM.DEID_DIAGNOSIS
                                                                                                                                    )
                                                                                                                                    union
                                                                                                                                    (
                                                                                                                                       select "PATID" as "PATID", cast("RXNORM_CUI" as string) as "CONCEPT"
                                                                                                                                       from PCORNET_CDM.CDM.DEID_PRESCRIBING
                                                                                                                                    )
                                                                                                                                    union
                                                                                                                                    (
                                                                                                                                       select "PATID" as "PATID", cast("MEDADMIN_CODE" as string) as "CONCEPT"
                                                                                                                                       from PCORNET_CDM.CDM.DEID_MED_ADMIN
                                                                                                                                    )
                                                                                                                                    union
                                                                                                                                    (
                                                                                                                                       select "PATID" as "PATID", cast("NDC" as string) as "CONCEPT"
                                                                                                                                       from PCORNET_CDM.CDM.DEID_DISPENSING
                                                                                                                                    )
                                                                                                                                 )
                                                                                                                            group by "CONCEPT"
                                                                                                                         )
                                                                                                                 ) as SNOWPARK_RIGHT
                                                                              on ("CONCEPT_CODE" = "CONCEPT"))
                                                                     )
                                                             )
                                                     ) as SNOWPARK_RIGHT
                       using (CONCEPT_ID, CONCEPT_NAME, DOMAIN_ID, VOCABULARY_ID, CONCEPT_CLASS_ID, CONCEPT_CODE))
              )
     )
;