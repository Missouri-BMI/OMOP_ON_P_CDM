//Modified from the file at https://github.com/PEDSnet/pcornetcdm_to_pedsnetcdm/blob/main/sql_etl/scripts/etl_scripts/a_p2o_discharge_status_xwalk.sql
//Edited by CMS 2022/03/28
//SnowSQL

CREATE TABLE CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK 
(
  CDM_SOURCE character varying(20) 
, CDM_TBL character varying(20) 
, SRC_DISCHARGE_STATUS character varying(20) NOT NULL 
, SRC_DISCHARGE_STATUS_DISCRP character varying(200) 
, TARGET_CONCEPT_ID integer
, TARGET_CONCEPT_NAME character varying(200) 
, TARGET_DOMAIN_ID character varying(20) 
, TARGET_VOCABULARY_ID character varying(30) 
, TARGET_CONCEPT_CLASS_ID character varying(20) 
, TARGET_STANDARD_CONCEPT character varying(1) 
, TARGET_CONCEPT_CODE character varying(50) 
) 
;

Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','AF','Adult  Foster  Home',8882,'(visit) Adult Living Care Facility (concept_id = 8882)','Visit','CMS Place of Service','Visit','S','35');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','AL','Assisted  Living  Facility',8615,'(visit) Assisted Living Facility (concept_id = 8615)','Visit','CMS Place of Service','Visit','S','13');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','AM','Against  Medical  Advice',0,'GAP','-','-','-','-','-');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','AW','Absent  without  leave',0,'GAP','-','-','-','-','-');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','EX','Expired',0,'GAP','-','-','-','-','-');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','HH','Home  Health',38004519,'(visit) Home Health Agency (concept_id = 38004519)','Visit','Medicare Specialty','Visit','S','A4');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','HO','Home  /  Self  Care',0,'Gap','-','-','-','-','-');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','HS','Hospice',8546,'(visit) Hospice (concept_id = 8546)','Visit','CMS Place of Service','Visit','S','34');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','IP','Other  Acute  Inpatient  Hospital',0,'GAP','-','-','-','-','-');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','NH','Nursing  Home  (Includes  ICF)',8676,'(visit) Nursing Facility (concept_id = 8676)','Visit','CMS Place of Service','Visit','S','32');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','NI','No  information',45877986,'(other_ni_unk) Unknown (concept_id = 45877986)','Meas Value','LOINC','Answer','S','LA4489-6');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','OT','Other',45878142,'(other_ni_unk) Other (concept_id = 45878142)','Meas Value','LOINC','Answer','S','LA46-8');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','RH','Rehabilitation  Facility',38004526,'(visit) Rehabilitation Agency (concept_id = 38004526)','Visit','Medicare Specialty','Visit','S','B4');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','RS','Residential  Facility',8957,'(visit) Residential Substance Abuse Treatment Facility (concept_id = 8957)','Visit','CMS Place of Service','Visit','S','55');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','SH','Still  In  Hospital',38004515,'(visit) Hospital (concept_id = 38004515)','Visit','Medicare Specialty','Visit','S','A0');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','SN','Skilled  Nursing  Facility',8863,'(visit) Skilled Nursing Facility (concept_id = 8863)','Visit','CMS Place of Service','Visit','S','31');
Insert into CDMH_STAGING.P2O_DISCHARGE_STATUS_XWALK (CDM_SOURCE,CDM_TBL,SRC_DISCHARGE_STATUS,SRC_DISCHARGE_STATUS_DISCRP,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','UN','Unknown',45877986,'(other_ni_unk) Unknown (concept_id = 45877986)','Meas Value','LOINC','Answer','S','LA4489-6');