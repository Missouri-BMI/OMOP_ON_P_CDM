create or replace view {cdm_db}.{cdm_schema}.measurement
(
	MEASUREMENT_ID,
	PERSON_ID,
	MEASUREMENT_CONCEPT_ID,
	MEASUREMENT_DATE,
	MEASUREMENT_DATETIME,
	MEASUREMENT_TIME,
	MEASUREMENT_TYPE_CONCEPT_ID,
	OPERATOR_CONCEPT_ID,
	VALUE_AS_NUMBER,
	VALUE_AS_CONCEPT_ID,
	UNIT_CONCEPT_ID,
	RANGE_LOW,
	RANGE_HIGH,
	PROVIDER_ID,
	VISIT_OCCURRENCE_ID,
	VISIT_DETAIL_ID,
	MEASUREMENT_SOURCE_VALUE,
	MEASUREMENT_SOURCE_CONCEPT_ID,
	UNIT_SOURCE_VALUE,
	UNIT_SOURCE_CONCEPT_ID,
	VALUE_SOURCE_VALUE,
	MEASUREMENT_EVENT_ID,
	MEAS_EVENT_FIELD_CONCEPT_ID
) as 

SELECT distinct
            lab.lab_result_cm_id::INTEGER   AS measurement_id,
            lab.patid::INTEGER    AS person_id,
            c.concept_id::INTEGER     AS measurement_concept_id, --concept id for lab - measurement
            lab.result_date::DATE          AS measurement_date,
            lab.result_date::TIMESTAMP          AS measurement_datetime,
            lab.result_time::VARCHAR(10)          AS measurement_time, 
            nvl(c_result.concept_id, 0)::INTEGER AS measurement_type_concept_id,
            NULL::INTEGER AS operator_concept_id,
            lab.result_num::NUMERIC           AS value_as_number, --result_num
            CASE
                WHEN lower(TRIM(result_qual)) = 'positive'             THEN
                    45884084
                WHEN lower(TRIM(result_qual)) = 'negative'             THEN
                    45878583
                WHEN lower(TRIM(result_qual)) = 'pos'                  THEN
                    45884084
                WHEN lower(TRIM(result_qual)) = 'neg'                  THEN
                    45878583
                WHEN lower(TRIM(result_qual)) = 'presumptive positive' THEN
                    45884084
                WHEN lower(TRIM(result_qual)) = 'presumptive negative' THEN
                    45878583
                WHEN lower(TRIM(result_qual)) = 'detected'             THEN
                    45884084
                WHEN lower(TRIM(result_qual)) = 'not detected'         THEN
                    45878583
                WHEN lower(TRIM(result_qual)) = 'inconclusive'         THEN
                    45877990
                WHEN lower(TRIM(result_qual)) = 'normal'               THEN
                    45884153
                WHEN lower(TRIM(result_qual)) = 'abnormal'             THEN
                    45878745
                WHEN lower(TRIM(result_qual)) = 'low'                  THEN
                    45881666
                WHEN lower(TRIM(result_qual)) = 'high'                 THEN
                    45876384
                WHEN lower(TRIM(result_qual)) = 'borderline'           THEN
                    45880922
                WHEN lower(TRIM(result_qual)) = 'elevated'             THEN
                    4328749  --ssh add issue number 55 - 6/26/2020 
                WHEN lower(TRIM(result_qual)) = 'undetermined'         THEN
                    45880649
                WHEN lower(TRIM(result_qual)) = 'undetectable'         THEN
                    45878583 
                WHEN lower(TRIM(result_qual)) IN (
                    'ni',
                    'ot',
                    'un',
                    'no information',
                    'unknown',
                    'other'
                ) THEN
                    NULL::INTEGER
                WHEN result_qual IS NULL THEN
                    NULL::INTEGER
                ELSE
                    45877393::INTEGER
            END AS value_as_concept_id,
            u.concept_id::INTEGER     AS unit_concept_id,
            TRY_CAST(lab.NORM_RANGE_LOW AS FLOAT)::NUMERIC as RANGE_LOW, 
            TRY_CAST(lab.NORM_RANGE_HIGH AS FLOAT)::NUMERIC as RANGE_HIGH, -- non-numeric data will error on a insert
            NULL::INTEGER AS provider_id,
            lab.encounterid::INTEGER    AS visit_occurrence_id,
            NULL::INTEGER AS visit_detail_id,
            lab.lab_loinc::VARCHAR(50)            AS measurement_source_value,
            0::INTEGER AS measurement_source_concept_id,
            lab.result_unit::VARCHAR(50)          AS unit_source_value,
            NULL::INTEGER AS unit_source_concept_id,
            nvl(left(lab.raw_result,100), decode(lab.result_num, 0, lab.result_qual))::VARCHAR(100) AS value_source_value,
            NULL::INTEGER AS measurement_event_id, NULL::INTEGER AS meas_event_field_concept_id
        FROM
            {pcornet_db}.{pcornet_schema}.lab_result_cm     lab
            JOIN {cdm_db}.{cdm_schema}.concept c ON lab.lab_loinc = c.concept_code
                                                            AND c.domain_id = 'Measurement'
            LEFT JOIN {cdm_db}.{cdm_schema}.concept u ON lab.result_unit = u.concept_code
                                                              --  AND u.src_cdm_column = 'RX_DOSE_ORDERED_UNIT'
            LEFT JOIN {cdm_db}.{cdm_schema}.concept c_result ON lab.lab_result_source = c_result.concept_code;
;