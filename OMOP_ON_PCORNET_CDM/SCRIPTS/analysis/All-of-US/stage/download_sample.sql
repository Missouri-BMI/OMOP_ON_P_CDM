--- CREATE FILE FORMAT
CREATE OR REPLACE FILE FORMAT {{ FILE_FORMAT }}
TYPE = CSV
FIELD_DELIMITER = ','
EMPTY_FIELD_AS_NULL = true 
TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
NULL_IF = ('NULL')
COMPRESSION=NONE
FIELD_OPTIONALLY_ENCLOSED_BY='"';

--- CREATE STAGE AREA
CREATE OR REPLACE STAGE {{ SNOWFLAKE_STAGE }} FILE_FORMAT = {{ FILE_FORMAT }};
--- COPY  TABLES IN THE STAGE
COPY INTO @{{ SNOWFLAKE_STAGE }}/person.csv FROM (SELECT person_id, gender_concept_id, year_of_birth, month_of_birth, day_of_birth, birth_datetime, race_concept_id, ethnicity_concept_id, location_id, provider_id, care_site_id, person_source_value, gender_source_value, gender_source_concept_id, race_source_value, race_source_concept_id, ethnicity_source_value, ethnicity_source_concept_id FROM person {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/death.csv FROM (SELECT * FROM death {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/provider.csv FROM (SELECT * FROM provider {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/location.csv FROM (SELECT location_id, address_1, address_2, city, state, zip, county, location_source_value FROM location {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/care_site.csv FROM (SELECT * FROM care_site {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/visit_occurrence.csv FROM (SELECT visit_occurrence_id, person_id, visit_concept_id, visit_start_date, visit_start_datetime, visit_end_date, visit_end_datetime, visit_type_concept_id, provider_id, care_site_id, visit_source_value, visit_source_concept_id, ADMITTED_FROM_CONCEPT_ID as admitting_source_concept_id, ADMITTED_FROM_SOURCE_VALUE as admitting_source_value, DISCHARGED_TO_CONCEPT_ID as discharge_to_concept_id, DISCHARGED_TO_SOURCE_VALUE as discharge_to_source_value, preceding_visit_occurrence_id FROM visit_occurrence {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/visit_detail.csv FROM (SELECT * FROM visit_detail {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/procedure_occurrence.csv FROM (SELECT procedure_occurrence_id, person_id, procedure_concept_id, procedure_date, procedure_datetime, procedure_type_concept_id, modifier_concept_id, quantity, provider_id, visit_occurrence_id, visit_detail_id, procedure_source_value, procedure_source_concept_id, modifier_source_value FROM procedure_occurrence {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/condition_occurrence.csv FROM (SELECT * FROM condition_occurrence {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/condition_era.csv FROM (SELECT * FROM condition_era {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/observation.csv FROM (SELECT * FROM observation {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/observation_period.csv FROM (SELECT * FROM observation_period {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/measurement.csv FROM (SELECT measurement_id, person_id, measurement_concept_id, measurement_date, measurement_datetime, measurement_time, measurement_type_concept_id, operator_concept_id, value_as_number, value_as_concept_id, unit_concept_id, range_low, range_high, provider_id, visit_occurrence_id, visit_detail_id, measurement_source_value, measurement_source_concept_id, unit_source_value, value_source_value FROM measurement {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/drug_exposure.csv FROM (SELECT * FROM drug_exposure {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/device_exposure.csv FROM (SELECT * FROM device_exposure {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};
COPY INTO @{{ SNOWFLAKE_STAGE }}/cdm_source.csv FROM (SELECT cdm_source_name, cdm_source_abbreviation, cdm_holder, source_description, source_documentation_reference, cdm_etl_reference, source_release_date, cdm_release_date, cdm_version, vocabulary_version FROM cdm_source {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};

--- DOWNLOAD TABLES FROM THE STAGE
GET @{{ SNOWFLAKE_STAGE }}/person.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/death.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/provider.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/location.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/care_site.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/visit_occurrence.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/visit_detail.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/procedure_occurrence.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/condition_occurrence.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/condition_era.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/observation.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/observation_period.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/measurement.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/drug_exposure.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/device_exposure.csv {{ LOCAL_STAGE }};
GET @{{ SNOWFLAKE_STAGE }}/cdm_source.csv {{ LOCAL_STAGE }};
