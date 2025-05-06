-- BEGIN WRITE --
-- DROP INDEXES AND CONSTRAINTS ON ZBU TABLES
/*******************
--- GENERATE drop omop prod constraint COMMANDS
USE TRACS_CDM;
DECLARE @sql NVARCHAR(MAX);
----------------------  constraints -------------------

SET @sql = N'';

SELECT 
	@sql = @sql + N'
	ALTER TABLE ' + QUOTENAME(sys_schemas.name) + N'.'
	+ QUOTENAME(sys_tables.name) + N' DROP CONSTRAINT '
	+ QUOTENAME(sys_objects.name) + ';'
FROM 
	sys.objects AS sys_objects
	INNER JOIN sys.tables AS sys_tables ON sys_objects.parent_object_id = sys_tables.object_id
	INNER JOIN sys.schemas AS sys_schemas ON sys_tables.schema_id = sys_schemas.schema_id
WHERE 
	sys_objects.type IN ('D','C','F','PK','UQ')
	and 
	sys_schemas.name in ('OMOP')
	and sys_tables.name in (

		'ZBU_PERSON',
		'ZBU_OBSERVATION_PERIOD',
		'ZBU_SPECIMEN',
		'ZBU_DEATH',
		'ZBU_VISIT_OCCURRENCE',
		'ZBU_VISIT_DETAIL',
		'ZBU_PROCEDURE_OCCURRENCE',
		'ZBU_DRUG_EXPOSURE',
		'ZBU_DEVICE_EXPOSURE',
		'ZBU_CONDITION_OCCURRENCE',
		'ZBU_MEASUREMENT',
		'ZBU_NOTE',
		'ZBU_NOTE_NLP',
		'ZBU_OBSERVATION',
		'ZBU_FACT_RELATIONSHIP',

		'ZBU_LOCATION',
		'ZBU_CARE_SITE',
		'ZBU_PROVIDER',
		
		'ZBU_DRUG_ERA',
		'ZBU_DOSE_ERA',
		'ZBU_CONDITION_ERA',
		'ZBU_COHORT',
		'ZBU_COHORT_ATTRIBUTE'
	)
ORDER BY 
	sys_objects.type;

PRINT @sql;
--EXEC sys.sp_executesql @sql;
******************/
/****************
--- GENERATE drop INDEXES COMMANDS
USE TRACS_CDM;
DECLARE @sql NVARCHAR(MAX);

---------------------  indexes ------------------------
SET @sql = N'';

SELECT  
	@sql = @sql + N'
	DROP INDEX IF EXISTS ' + quotename(sys_indexes.name) + ' ON ' + quotename(sys_schemas.name) + '.' + quotename(sys_tables.name) + '; '
FROM  
	sys.indexes sys_indexes
	INNER JOIN sys.tables AS sys_tables ON sys_indexes.object_id = sys_tables.object_id
	INNER JOIN sys.schemas AS sys_schemas ON sys_tables.schema_id = sys_schemas.schema_id
WHERE 
	sys_indexes.name is not null
	and sys_schemas.name in ('OMOP')
	and sys_tables.name in (

		'ZBU_PERSON',
		'ZBU_OBSERVATION_PERIOD',
		'ZBU_SPECIMEN',
		'ZBU_DEATH',
		'ZBU_VISIT_OCCURRENCE',
		'ZBU_VISIT_DETAIL',
		'ZBU_PROCEDURE_OCCURRENCE',
		'ZBU_DRUG_EXPOSURE',
		'ZBU_DEVICE_EXPOSURE',
		'ZBU_CONDITION_OCCURRENCE',
		'ZBU_MEASUREMENT',
		'ZBU_NOTE',
		'ZBU_NOTE_NLP',
		'ZBU_OBSERVATION',
		'ZBU_FACT_RELATIONSHIP',

		'ZBU_LOCATION',
		'ZBU_CARE_SITE',
		'ZBU_PROVIDER',
		
		'ZBU_DRUG_ERA',
		'ZBU_DOSE_ERA',
		'ZBU_CONDITION_ERA',
		'ZBU_COHORT',
		'ZBU_COHORT_ATTRIBUTE'
	)
;
print @sql;
--EXEC sys.sp_executesql @sql;
***************/

USE TRACS_CDM;
	
	ALTER TABLE [OMOP].[ZBU_PERSON] DROP CONSTRAINT [ZBU_xpk_person];
	ALTER TABLE [OMOP].[ZBU_OBSERVATION_PERIOD] DROP CONSTRAINT [ZBU_xpk_observation_period];
	ALTER TABLE [OMOP].[ZBU_SPECIMEN] DROP CONSTRAINT [ZBU_xpk_specimen];
	ALTER TABLE [OMOP].[ZBU_DEATH] DROP CONSTRAINT [ZBU_xpk_death];
	ALTER TABLE [OMOP].[ZBU_VISIT_OCCURRENCE] DROP CONSTRAINT [ZBU_xpk_visit_occurrence];
	ALTER TABLE [OMOP].[ZBU_VISIT_DETAIL] DROP CONSTRAINT [ZBU_xpk_visit_detail];
	ALTER TABLE [OMOP].[ZBU_PROCEDURE_OCCURRENCE] DROP CONSTRAINT [ZBU_xpk_procedure_occurrence];
	ALTER TABLE [OMOP].[ZBU_DRUG_EXPOSURE] DROP CONSTRAINT [ZBU_xpk_drug_exposure];
	ALTER TABLE [OMOP].[ZBU_DEVICE_EXPOSURE] DROP CONSTRAINT [ZBU_xpk_device_exposure];
	ALTER TABLE [OMOP].[ZBU_CONDITION_OCCURRENCE] DROP CONSTRAINT [ZBU_xpk_condition_occurrence];
-- END WRITE --
-- BEGIN WRITE --
USE TRACS_CDM;	
	
	ALTER TABLE [OMOP].[ZBU_MEASUREMENT] DROP CONSTRAINT [ZBU_xpk_measurement];
	ALTER TABLE [OMOP].[ZBU_NOTE] DROP CONSTRAINT [ZBU_xpk_note];
	ALTER TABLE [OMOP].[ZBU_NOTE_NLP] DROP CONSTRAINT [ZBU_xpk_note_nlp];
	ALTER TABLE [OMOP].[ZBU_OBSERVATION] DROP CONSTRAINT [ZBU_xpk_observation];
	ALTER TABLE [OMOP].[ZBU_LOCATION] DROP CONSTRAINT [ZBU_xpk_location];
	ALTER TABLE [OMOP].[ZBU_CARE_SITE] DROP CONSTRAINT [ZBU_xpk_care_site];
	ALTER TABLE [OMOP].[ZBU_PROVIDER] DROP CONSTRAINT [ZBU_xpk_provider];
	ALTER TABLE [OMOP].[ZBU_COHORT] DROP CONSTRAINT [xpk_cohort];
	ALTER TABLE [OMOP].[ZBU_COHORT_ATTRIBUTE] DROP CONSTRAINT [xpk_cohort_attribute];
	ALTER TABLE [OMOP].[ZBU_CONDITION_ERA] DROP CONSTRAINT [xpk_condition_era];
-- END WRITE --
-- BEGIN WRITE --
USE TRACS_CDM;		
	
	DROP INDEX IF EXISTS [ZBU_xpk_care_site] ON [OMOP].[ZBU_CARE_SITE]; 
	DROP INDEX IF EXISTS [omop_care_site_src_idx] ON [OMOP].[ZBU_CARE_SITE]; 
	DROP INDEX IF EXISTS [xpk_cohort] ON [OMOP].[ZBU_COHORT]; 
	DROP INDEX IF EXISTS [idx_cohort_subject_id] ON [OMOP].[ZBU_COHORT]; 
	DROP INDEX IF EXISTS [idx_cohort_c_definition_id] ON [OMOP].[ZBU_COHORT]; 
	DROP INDEX IF EXISTS [xpk_cohort_attribute] ON [OMOP].[ZBU_COHORT_ATTRIBUTE]; 
	DROP INDEX IF EXISTS [idx_ca_subject_id] ON [OMOP].[ZBU_COHORT_ATTRIBUTE]; 
	DROP INDEX IF EXISTS [idx_ca_definition_id] ON [OMOP].[ZBU_COHORT_ATTRIBUTE]; 
	DROP INDEX IF EXISTS [idx_condition_era_person_id] ON [OMOP].[ZBU_CONDITION_ERA]; 
	DROP INDEX IF EXISTS [xpk_condition_era] ON [OMOP].[ZBU_CONDITION_ERA]; 
-- END WRITE --
-- BEGIN WRITE --
USE TRACS_CDM;		
	DROP INDEX IF EXISTS [idx_condition_era_concept_id] ON [OMOP].[ZBU_CONDITION_ERA]; 
	DROP INDEX IF EXISTS [idx_condition_person_id] ON [OMOP].[ZBU_CONDITION_OCCURRENCE]; 
	DROP INDEX IF EXISTS [ZBU_xpk_condition_occurrence] ON [OMOP].[ZBU_CONDITION_OCCURRENCE]; 
	DROP INDEX IF EXISTS [idx_condition_concept_id] ON [OMOP].[ZBU_CONDITION_OCCURRENCE]; 
	DROP INDEX IF EXISTS [idx_condition_visit_id] ON [OMOP].[ZBU_CONDITION_OCCURRENCE]; 
	DROP INDEX IF EXISTS [idx_death_person_id] ON [OMOP].[ZBU_DEATH]; 
	DROP INDEX IF EXISTS [ZBU_xpk_death] ON [OMOP].[ZBU_DEATH]; 
	DROP INDEX IF EXISTS [idx_device_person_id] ON [OMOP].[ZBU_DEVICE_EXPOSURE]; 
	DROP INDEX IF EXISTS [ZBU_xpk_device_exposure] ON [OMOP].[ZBU_DEVICE_EXPOSURE]; 
	DROP INDEX IF EXISTS [idx_device_concept_id] ON [OMOP].[ZBU_DEVICE_EXPOSURE]; 
-- END WRITE --
-- BEGIN WRITE --
USE TRACS_CDM;		
	DROP INDEX IF EXISTS [idx_device_visit_id] ON [OMOP].[ZBU_DEVICE_EXPOSURE]; 
	DROP INDEX IF EXISTS [idx_drug_person_id] ON [OMOP].[ZBU_DRUG_EXPOSURE]; 
	DROP INDEX IF EXISTS [ZBU_xpk_drug_exposure] ON [OMOP].[ZBU_DRUG_EXPOSURE]; 
	DROP INDEX IF EXISTS [idx_drug_concept_id] ON [OMOP].[ZBU_DRUG_EXPOSURE]; 
	DROP INDEX IF EXISTS [idx_drug_visit_id] ON [OMOP].[ZBU_DRUG_EXPOSURE]; 
	DROP INDEX IF EXISTS [idx_fact_relationship_id_1] ON [OMOP].[ZBU_FACT_RELATIONSHIP]; 
	DROP INDEX IF EXISTS [idx_fact_relationship_id_2] ON [OMOP].[ZBU_FACT_RELATIONSHIP]; 
	DROP INDEX IF EXISTS [idx_fact_relationship_id_3] ON [OMOP].[ZBU_FACT_RELATIONSHIP]; 
	DROP INDEX IF EXISTS [ZBU_xpk_location] ON [OMOP].[ZBU_LOCATION]; 
	DROP INDEX IF EXISTS [idx_measurement_person_id] ON [OMOP].[ZBU_MEASUREMENT]; 
-- END WRITE --
-- BEGIN WRITE --
USE TRACS_CDM;		
	DROP INDEX IF EXISTS [ZBU_xpk_measurement] ON [OMOP].[ZBU_MEASUREMENT]; 
	DROP INDEX IF EXISTS [idx_measurement_concept_id] ON [OMOP].[ZBU_MEASUREMENT]; 
	DROP INDEX IF EXISTS [idx_measurement_visit_id] ON [OMOP].[ZBU_MEASUREMENT]; 
	DROP INDEX IF EXISTS [idx_note_person_id] ON [OMOP].[ZBU_NOTE]; 
	DROP INDEX IF EXISTS [ZBU_xpk_note] ON [OMOP].[ZBU_NOTE]; 
	DROP INDEX IF EXISTS [idx_note_concept_id] ON [OMOP].[ZBU_NOTE]; 
	DROP INDEX IF EXISTS [idx_note_visit_id] ON [OMOP].[ZBU_NOTE]; 
	DROP INDEX IF EXISTS [idx_note_nlp_note_id] ON [OMOP].[ZBU_NOTE_NLP]; 
	DROP INDEX IF EXISTS [ZBU_xpk_note_nlp] ON [OMOP].[ZBU_NOTE_NLP]; 
	DROP INDEX IF EXISTS [idx_note_nlp_concept_id] ON [OMOP].[ZBU_NOTE_NLP]; 
-- END WRITE --
-- BEGIN WRITE --
USE TRACS_CDM;		
	DROP INDEX IF EXISTS [idx_observation_person_id] ON [OMOP].[ZBU_OBSERVATION]; 
	DROP INDEX IF EXISTS [ZBU_xpk_observation] ON [OMOP].[ZBU_OBSERVATION]; 
	DROP INDEX IF EXISTS [idx_observation_concept_id] ON [OMOP].[ZBU_OBSERVATION]; 
	DROP INDEX IF EXISTS [idx_observation_visit_id] ON [OMOP].[ZBU_OBSERVATION]; 
	DROP INDEX IF EXISTS [idx_observation_period_id] ON [OMOP].[ZBU_OBSERVATION_PERIOD]; 
	DROP INDEX IF EXISTS [ZBU_xpk_observation_period] ON [OMOP].[ZBU_OBSERVATION_PERIOD]; 
	DROP INDEX IF EXISTS [idx_person_id] ON [OMOP].[ZBU_PERSON]; 
	DROP INDEX IF EXISTS [ZBU_xpk_person] ON [OMOP].[ZBU_PERSON]; 
	DROP INDEX IF EXISTS [idx_procedure_person_id] ON [OMOP].[ZBU_PROCEDURE_OCCURRENCE]; 
	DROP INDEX IF EXISTS [ZBU_xpk_procedure_occurrence] ON [OMOP].[ZBU_PROCEDURE_OCCURRENCE]; 
-- END WRITE --
-- BEGIN WRITE --
USE TRACS_CDM;		
	DROP INDEX IF EXISTS [idx_procedure_concept_id] ON [OMOP].[ZBU_PROCEDURE_OCCURRENCE]; 
	DROP INDEX IF EXISTS [idx_procedure_visit_id] ON [OMOP].[ZBU_PROCEDURE_OCCURRENCE]; 
	DROP INDEX IF EXISTS [ZBU_xpk_provider] ON [OMOP].[ZBU_PROVIDER]; 
	DROP INDEX IF EXISTS [idx_specimen_person_id] ON [OMOP].[ZBU_SPECIMEN]; 
	DROP INDEX IF EXISTS [ZBU_xpk_specimen] ON [OMOP].[ZBU_SPECIMEN]; 
	DROP INDEX IF EXISTS [idx_specimen_concept_id] ON [OMOP].[ZBU_SPECIMEN]; 
	DROP INDEX IF EXISTS [idx_visit_detail_person_id] ON [OMOP].[ZBU_VISIT_DETAIL]; 
-- END WRITE --	
-- BEGIN WRITE --
USE TRACS_CDM;
	DROP INDEX IF EXISTS [omop_provider_src_idx] ON [OMOP].[ZBU_PROVIDER]; 
	DROP INDEX IF EXISTS [idx_visit_detail_concept_id] ON [OMOP].[ZBU_VISIT_DETAIL]; 
	DROP INDEX IF EXISTS [idx_visit_person_id] ON [OMOP].[ZBU_VISIT_OCCURRENCE]; 
	DROP INDEX IF EXISTS [idx_visit_concept_id] ON [OMOP].[ZBU_VISIT_OCCURRENCE]; 
-- END WRITE --
