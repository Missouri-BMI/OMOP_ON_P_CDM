-- BEGIN WRITE --
USE TRACS_CDM;

exec SP_RENAME 'XOMOP.COHORT_OMOP', 'ZBU_COHORT_OMOP';
exec SP_RENAME 'XOMOP.OMOP_HARVEST', 'ZBU_OMOP_HARVEST';

exec SP_RENAME 'OMOP.PERSON', 'ZBU_PERSON';
exec SP_RENAME 'OMOP.OBSERVATION_PERIOD', 'ZBU_OBSERVATION_PERIOD';
exec SP_RENAME 'OMOP.SPECIMEN', 'ZBU_SPECIMEN' ;
exec SP_RENAME 'OMOP.DEATH', 'ZBU_DEATH' ;
exec SP_RENAME 'OMOP.VISIT_OCCURRENCE', 'ZBU_VISIT_OCCURRENCE' ;
exec SP_RENAME 'OMOP.VISIT_DETAIL', 'ZBU_VISIT_DETAIL' ;
exec SP_RENAME 'OMOP.PROCEDURE_OCCURRENCE', 'ZBU_PROCEDURE_OCCURRENCE' ;
exec SP_RENAME 'OMOP.DRUG_EXPOSURE', 'ZBU_DRUG_EXPOSURE' ;
exec SP_RENAME 'OMOP.DEVICE_EXPOSURE', 'ZBU_DEVICE_EXPOSURE' ;
exec SP_RENAME 'OMOP.CONDITION_OCCURRENCE', 'ZBU_CONDITION_OCCURRENCE' ;
exec SP_RENAME 'OMOP.MEASUREMENT', 'ZBU_MEASUREMENT' ;
-- END WRITE --
-- BEGIN WRITE --
USE TRACS_CDM;
exec SP_RENAME 'OMOP.NOTE', 'ZBU_NOTE' ;
exec SP_RENAME 'OMOP.NOTE_NLP', 'ZBU_NOTE_NLP' ;
exec SP_RENAME 'OMOP.OBSERVATION', 'ZBU_OBSERVATION' ;
exec SP_RENAME 'OMOP.FACT_RELATIONSHIP', 'ZBU_FACT_RELATIONSHIP' ;

exec SP_RENAME 'OMOP.LOCATION', 'ZBU_LOCATION' ;
exec SP_RENAME 'OMOP.CARE_SITE', 'ZBU_CARE_SITE' ;
exec SP_RENAME 'OMOP.PROVIDER', 'ZBU_PROVIDER' ;

exec SP_RENAME 'OMOP.DRUG_ERA', 'ZBU_DRUG_ERA' ;
exec SP_RENAME 'OMOP.DOSE_ERA', 'ZBU_DOSE_ERA' ;
exec SP_RENAME 'OMOP.CONDITION_ERA', 'ZBU_CONDITION_ERA' ;

exec SP_RENAME 'OMOP.COHORT', 'ZBU_COHORT' ;
exec SP_RENAME 'OMOP.COHORT_ATTRIBUTE', 'ZBU_COHORT_ATTRIBUTE' ;

-- END WRITE --