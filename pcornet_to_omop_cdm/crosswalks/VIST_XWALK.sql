CREATE TABLE OMOP_CDM.VOCABULARY.VISIT_XWALK 
(
  CDM_NAME VARCHAR2(100 BYTE) 
, CDM_TBL VARCHAR2(100 BYTE) 
, SRC_VISIT_TYPE VARCHAR2(100 BYTE) 
, FHIR_CD VARCHAR2(100 BYTE) 
, TARGET_CONCEPT_ID NUMBER(32, 0) NOT NULL 
, TARGET_CONCEPT_NAME VARCHAR2(255 BYTE) NOT NULL 
, TARGET_DOMAIN_ID VARCHAR2(20 BYTE) NOT NULL 
, TARGET_VOCABULARY_ID VARCHAR2(20 BYTE) NOT NULL 
, TARGET_CONCEPT_CLASS_ID VARCHAR2(20 BYTE) NOT NULL 
, TARGET_STANDARD_CONCEPT VARCHAR2(1 BYTE) 
, TARGET_CONCEPT_CODE VARCHAR2(50 BYTE) NOT NULL 
);

Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','AV','AMB',9202,'Outpatient Visit','Visit','Visit','Visit Type','S','19700101');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','ED','EMER',9203,'Emergency Room Visit','Visit','Visit','Visit Type','S','19700101');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','EI','ACUTE',262,'Emergency Room Visit','Visit','Visit','Visit Type','S','19700101');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','IC',null,42898160,'Institutional  Professional  Consult','Visit','Visit','Visit Type','S','19700101');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','IP','IMP',9201,'Inpatient Hospital Stay','Visit','Visit','Visit Type','S','19700101');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','NI',null,0,'No information','Visit','Visit','Visit Type','S','25569');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','IS','NONAC',42898160,'Non-Acute Institutional Stay','Visit','Visit','Visit Type','S','19700101');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','OA','AMB',9202,'Outpatient Visit','Visit','Visit','Visit Type','S','19700101');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','OS','X',581385,'Observation Stay','Visit','Visit','Visit Type','S','19700101');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','OT',null,0,'Other','Visit','Visit','Visit Type','S','25569');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('PCORnet','ENCOUNTER','UN',null,0,'Unknown','Visit','Visit','Visit Type','S','25569');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('I2B2ACT','VISIT_DIMENSION','EI','ACUTE',262,'Emergency Department Visit','Visit','Visit','Visit Type','S','ERIP');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('I2B2ACT','VISIT_DIMENSION','E','EMER',9203,'Emergency Department Visit','Visit','Visit','Visit Type','S','ER');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('I2B2ACT','VISIT_DIMENSION','I','ACUTE',9201,'Inpatient Hospital Stay','Visit','CMS Place of Service','Visit Type','S','21');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('I2B2ACT','VISIT_DIMENSION','N',null,0,'No Information','Visit','CMS Place of Service','Visit Type','S','46237210');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('I2B2ACT','VISIT_DIMENSION','NA','NONAC',9201,'Non-Acute Hospital Stay','Visit','CMS Place of Service','Visit Type','S','A0');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('I2B2ACT','VISIT_DIMENSION','X',null,9202,'X Other Ambulatory Visit','Visit','Visit','Visit','S','OP');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('I2B2ACT','VISIT_DIMENSION','O','AMB',9202,'O Ambulatory Visit','Visit','Visit','Visit','S','OP');
Insert into OMOP_CDM.VOCABULARY.VISIT_XWALK (CDM_NAME,CDM_TBL,SRC_VISIT_TYPE,FHIR_CD,TARGET_CONCEPT_ID,TARGET_CONCEPT_NAME,TARGET_DOMAIN_ID,TARGET_VOCABULARY_ID,TARGET_CONCEPT_CLASS_ID,TARGET_STANDARD_CONCEPT,TARGET_CONCEPT_CODE) values ('I2B2ACT','VISIT_DIMENSION','OP','IC',9202,'OP Outpatient  Visit','Visit','Visit','Visit','S','OP');