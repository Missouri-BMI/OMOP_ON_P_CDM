-- BEGIN WRITE --
-- NEED TO HAVE TWO WRITE BLOCKS, PYODBC  CONNECTION ONLY RUNS 15 EXECS THEN STOPS
--- USE SCRIPT BELOW TO GENERATE EXEC SP_RENAME STATEMENTS
--MOVE omop prod constraints and indexes
--USE TRACS_CDM;
--DECLARE @sql NVARCHAR(MAX);
------------------------  constraints -------------------

--SET @sql = N'';

--SELECT 
--	--@sql = @sql + N'
--	--ALTER TABLE ' + QUOTENAME(sys_schemas.name) + N'.'
--	--+ QUOTENAME(sys_tables.name) + N' DROP CONSTRAINT '
--	--+ QUOTENAME(sys_objects.name) + ';'
--	@sql = @sql + N'
--	EXEC SP_RENAME ' + '''' + sys_schemas.name + '.' + sys_objects.name + '''' + ',''ZBU_' + sys_objects.name + ''';'
--FROM 
--	sys.objects AS sys_objects
--	INNER JOIN sys.tables AS sys_tables ON sys_objects.parent_object_id = sys_tables.object_id
--	INNER JOIN sys.schemas AS sys_schemas ON sys_tables.schema_id = sys_schemas.schema_id
--WHERE 
--	sys_objects.type IN ('D','C','F','PK','UQ')
--	and 
--	sys_schemas.name in ('OMOP')
--	and sys_tables.name in (

--		'PERSON',
--		'OBSERVATION_PERIOD',
--		'SPECIMEN',
--		'DEATH',
--		'VISIT_OCCURRENCE',
--		'VISIT_DETAIL',
--		'PROCEDURE_OCCURRENCE',
--		'DRUG_EXPOSURE',
--		'DEVICE_EXPOSURE',
--		'CONDITION_OCCURRENCE',
--		'MEASUREMENT',
--		'NOTE',
--		'NOTE_NLP',
--		'OBSERVATION',
--		'FACT_RELATIONSHIP',

--		'LOCATION',
--		'CARE_SITE',
--		'PROVIDER'
--	)
--	and sys_objects.name like 'xpk%'
--ORDER BY 
--	sys_objects.type;

--PRINT @sql;
----EXEC sys.sp_executesql @sql;

	EXEC SP_RENAME 'OMOP.xpk_care_site','ZBU_xpk_care_site';
	EXEC SP_RENAME 'OMOP.xpk_condition_occurrence','ZBU_xpk_condition_occurrence';
	EXEC SP_RENAME 'OMOP.xpk_death','ZBU_xpk_death';
	EXEC SP_RENAME 'OMOP.xpk_device_exposure','ZBU_xpk_device_exposure';
	EXEC SP_RENAME 'OMOP.xpk_drug_exposure','ZBU_xpk_drug_exposure';
	EXEC SP_RENAME 'OMOP.xpk_location','ZBU_xpk_location';
	EXEC SP_RENAME 'OMOP.xpk_measurement','ZBU_xpk_measurement';
	EXEC SP_RENAME 'OMOP.xpk_note','ZBU_xpk_note';
	EXEC SP_RENAME 'OMOP.xpk_note_nlp','ZBU_xpk_note_nlp';
	EXEC SP_RENAME 'OMOP.xpk_observation','ZBU_xpk_observation';
-- END WRITE --
-- BEGIN WRITE --
	EXEC SP_RENAME 'OMOP.xpk_observation_period','ZBU_xpk_observation_period';
	EXEC SP_RENAME 'OMOP.xpk_person','ZBU_xpk_person';
	EXEC SP_RENAME 'OMOP.xpk_procedure_occurrence','ZBU_xpk_procedure_occurrence';
	EXEC SP_RENAME 'OMOP.xpk_provider','ZBU_xpk_provider';
	EXEC SP_RENAME 'OMOP.xpk_specimen','ZBU_xpk_specimen';
	EXEC SP_RENAME 'OMOP.xpk_visit_detail','ZBU_xpk_visit_detail';
	EXEC SP_RENAME 'OMOP.xpk_visit_occurrence','ZBU_xpk_visit_occurrence';

-- END WRITE --
