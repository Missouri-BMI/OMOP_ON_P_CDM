--alter index all on TRACS_CDM.OMOP.XSTG_DRUG_EXPOSURE DISABLE;
truncate table TRACS_CDM.OMOP.XSTG_DRUG_EXPOSURE;

with
cohort_omop_no_enc as
(
	select distinct patid, person_id from TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
),
drug_med_admin as 
(
    SELECT
    	XSTG_COHORT_OMOP.person_id,
        coalesce(target_concept.concept_id,0) as drug_concept_id,
        CAST(med_admin.medadmin_start_date as date) as drug_exposure_start_date, 
        CAST(coalesce(med_admin.medadmin_stop_date,med_admin.medadmin_start_date) as date) as drug_exposure_end_date,
        CAST(med_admin.medadmin_stop_date as date) as verbatim_end_date,
        -- 581373 as drug_type_concept_id, --m medication administered to patient 
		-- 32818 - EHR Admin Record
        32818 as drug_type_concept_id,
        NULL AS stop_reason,
        CAST(null as numeric(18,0)) AS refills,
        CAST(null as float) AS quantity,
        CAST(null AS numeric(18,0)) AS days_supply,
        CAST(NULL as varchar(50)) as sig,
        CAST(coalesce(XWALK_ROUTE.TARGET_CONCEPT_ID,0) as int) as route_concept_id,
        NULL AS lot_number,
		NULL as provider_id,
		XSTG_COHORT_OMOP.visit_occurrence_id,
        XSTG_COHORT_OMOP.VISIT_DETAIL_ID AS visit_detail_id,
        CAST(med_admin.medadmin_code as varchar(50)) as drug_source_value,
        cast(coalesce(source_concept.concept_id,0) as numeric(18,0)) as drug_source_concept_id,
        CAST(med_admin.medadmin_route as varchar(50)) as route_source_value,
        CAST(med_admin.medadmin_dose_admin_unit as varchar(50)) as dose_unit_source_value
    FROM
    	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.MED_ADMIN med_admin on XSTG_COHORT_OMOP.patid = med_admin.patid and XSTG_COHORT_OMOP.encounterid = med_admin.encounterid
        left outer join TRACS_CDM.OMOP.CONCEPT source_concept on med_admin.medadmin_code = source_concept.concept_code
        	and
        	(
        		(med_admin.medadmin_type = 'RX' and source_concept.vocabulary_id='RxNorm')
        		OR
        		(med_admin.medadmin_type = 'ND' and source_concept.vocabulary_id='NDC')
        	)
        left outer join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1  and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        left outer join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id and target_concept.standard_concept='S' and target_concept.DOMAIN_ID='Drug'
        --left outer join n3c_p2o_valueset_mapping_table r ON med_admin.medadmin_route = r.SRC_CODE and r.CDM_TBL_COLUMN_NAME = 'RX_ROUTE'
		LEFT OUTER JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP XWALK_ROUTE ON (med_admin.medadmin_route=XWALK_ROUTE.SOURCE_VALUE AND XWALK_ROUTE.SOURCE_COLUMN='RX_ROUTE' AND XWALK_ROUTE.TARGET_TABLE='DRUG_EXPOSURE')
	WHERE
		(
			source_concept.DOMAIN_ID <> 'Device' --remove device records that should go to different table.
			OR 
			source_concept.DOMAIN_ID IS NULL 
		)
),

drug_prescribing as 
(
    SELECT
    	XSTG_COHORT_OMOP.person_id,
        CAST(coalesce(target_concept.concept_id,0) as numeric(18,0)) drug_concept_id,
        CAST(COALESCE(rx_start_date, rx_order_date) as date) AS drug_exposure_start_date,
        CASE
            WHEN rx_end_date IS NULL 
            THEN
                CASE
                    WHEN COALESCE(rx_days_supply, 0) = 0 
                        THEN CAST(COALESCE(rx_start_date, rx_order_date) as date)
                    ELSE COALESCE(rx_start_date, rx_order_date) + rx_days_supply
                END
            ELSE rx_end_date
        END AS drug_exposure_end_date,
        CAST(prescribing.rx_end_date as date) AS verbatim_end_date,
        32817 AS drug_type_concept_id,
        NULL AS stop_reason,
        prescribing.rx_refills AS refills,
        prescribing.rx_quantity AS quantity,
        CAST(rx_days_supply as numeric(18,0)) AS days_supply,
        CAST(rx_frequency as varchar(50) ) AS sig,
        CAST(coalesce(XWALK_ROUTE.TARGET_CONCEPT_ID,0) as numeric(18,0)) AS route_concept_id,
        NULL AS lot_number,
        NULL AS provider_id,
        XSTG_COHORT_OMOP.VISIT_OCCURRENCE_ID,
        XSTG_COHORT_OMOP.VISIT_DETAIL_ID AS visit_detail_id,
        CAST(rxnorm_cui as varchar(50) ) AS drug_source_value,
        CAST(coalesce(source_concept.concept_id,0) as numeric(18,0)) AS drug_source_concept_id, --- drug source concept id if it is prescribing
        CAST(rx_route as varchar(50)) AS route_source_value,
        CAST(rx_dose_ordered_unit as varchar(50)) AS dose_unit_source_value
    FROM 
	TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
    	join TRACS_CDM.PCDM.PRESCRIBING prescribing on XSTG_COHORT_OMOP.patid = prescribing.patid and XSTG_COHORT_OMOP.encounterid = prescribing.encounterid
        left outer join TRACS_CDM.OMOP.CONCEPT source_concept on prescribing.rxnorm_cui = source_concept.concept_code and source_concept.vocabulary_id='RxNorm'
    	left outer join TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP on source_concept.concept_id = concept_relationship.concept_id_1  and concept_relationship.RELATIONSHIP_ID = 'Maps to'
        left outer join TRACS_CDM.OMOP.CONCEPT target_concept on concept_relationship.concept_id_2 = target_concept.concept_id and target_concept.standard_concept='S' and target_concept.DOMAIN_ID='Drug'
	LEFT OUTER JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP XWALK_ROUTE ON (PRESCRIBING.RX_ROUTE=XWALK_ROUTE.SOURCE_VALUE AND XWALK_ROUTE.SOURCE_COLUMN='RX_ROUTE' AND XWALK_ROUTE.TARGET_TABLE='DRUG_EXPOSURE')
)
,

drug_immunization as (
	SELECT
		  XSTG_COHORT_OMOP.PERSON_ID
		, CAST(COALESCE(TARGET_CONCEPT.CONCEPT_ID,0) AS INT) DRUG_CONCEPT_ID
		, CAST(VX_ADMIN_DATE AS DATE) DRUG_EXPOSURE_START_DATE
		, CAST(VX_ADMIN_DATE AS DATE) DRUG_EXPOSURE_END_DATE
		, CAST(VX_ADMIN_DATE AS DATE) VERBATIM_END_DATE
		, CASE WHEN IMMUNIZATION.VX_SOURCE='OD' THEN 32818 ELSE 32817 END DRUG_TYPE_CONCEPT_ID
		, NULL AS STOP_REASON
		, CAST(NULL AS INT) AS REFILLS
		, CAST(NULL AS FLOAT) AS QUANTITY
		, CAST(NULL AS INT) AS DAYS_SUPPLY
		, CAST(NULL AS varchar(50)) AS SIG
		, CAST(COALESCE(XWALK_ROUTE.TARGET_CONCEPT_ID,0) AS INT) ROUTE_CONCEPT_ID
		, IMMUNIZATION.VX_LOT_NUM AS LOT_NUMBER
		, NULL AS PROVIDER_ID
		, XSTG_COHORT_OMOP.VISIT_OCCURRENCE_ID
		, XSTG_COHORT_OMOP.VISIT_DETAIL_ID AS VISIT_DETAIL_ID
		, CAST(IMMUNIZATION.VX_CODE AS varchar(50)) AS DRUG_SOURCE_VALUE 
		, CAST(COALESCE(SOURCE_CONCEPT.CONCEPT_ID,0) AS INT) AS DRUG_SOURCE_CONCEPT_ID
		, CAST(VX_ROUTE AS varchar(50)) AS ROUTE_SOURCE_VALUE
		, CAST(VX_DOSE_UNIT AS varchar(50)) AS DOSE_UNIT_SOURCE_VALUE
	FROM 
		TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
		INNER JOIN TRACS_CDM.PCDM.IMMUNIZATION IMMUNIZATION ON XSTG_COHORT_OMOP.PATID=IMMUNIZATION.PATID and XSTG_COHORT_OMOP.encounterid = immunization.encounterid
		LEFT OUTER JOIN TRACS_CDM.OMOP.CONCEPT SOURCE_CONCEPT 
			ON IMMUNIZATION.VX_CODE=SOURCE_CONCEPT.CONCEPT_CODE 
			AND ((SOURCE_CONCEPT.VOCABULARY_ID='CVX' AND IMMUNIZATION.VX_CODE_TYPE='CX') OR (SOURCE_CONCEPT.VOCABULARY_ID='NDC' AND IMMUNIZATION.VX_CODE_TYPE='ND'))
		LEFT OUTER JOIN TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP ON SOURCE_CONCEPT.CONCEPT_ID = CONCEPT_RELATIONSHIP.CONCEPT_ID_1  AND CONCEPT_RELATIONSHIP.RELATIONSHIP_ID = 'Maps to'
		LEFT OUTER JOIN TRACS_CDM.OMOP.CONCEPT TARGET_CONCEPT ON CONCEPT_RELATIONSHIP.CONCEPT_ID_2 = TARGET_CONCEPT.CONCEPT_ID AND TARGET_CONCEPT.STANDARD_CONCEPT='S' AND TARGET_CONCEPT.DOMAIN_ID='Drug'
		LEFT OUTER JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP XWALK_ROUTE ON (IMMUNIZATION.VX_ROUTE=XWALK_ROUTE.SOURCE_VALUE AND XWALK_ROUTE.SOURCE_COLUMN='RX_ROUTE' AND XWALK_ROUTE.TARGET_TABLE='DRUG_EXPOSURE')
),
drug_immunization_no_enc as (
	SELECT
		  cohort_omop_no_enc.PERSON_ID
		, CAST(COALESCE(TARGET_CONCEPT.CONCEPT_ID,0) AS INT) DRUG_CONCEPT_ID
		, CAST(VX_ADMIN_DATE AS DATE) DRUG_EXPOSURE_START_DATE
		, CAST(VX_ADMIN_DATE AS DATE) DRUG_EXPOSURE_END_DATE
		, CAST(VX_ADMIN_DATE AS DATE) VERBATIM_END_DATE
		, CASE WHEN IMMUNIZATION.VX_SOURCE='OD' THEN 32818 ELSE 32817 END DRUG_TYPE_CONCEPT_ID
		, NULL AS STOP_REASON
		, CAST(NULL AS INT) AS REFILLS
		, CAST(NULL AS FLOAT) AS QUANTITY
		, CAST(NULL AS INT) AS DAYS_SUPPLY
		, CAST(NULL AS varchar(50)) AS SIG
		, CAST(COALESCE(XWALK_ROUTE.TARGET_CONCEPT_ID,0) AS INT) ROUTE_CONCEPT_ID
		, IMMUNIZATION.VX_LOT_NUM AS LOT_NUMBER
		, NULL AS PROVIDER_ID
		, null as VISIT_OCCURRENCE_ID
		, NULL AS VISIT_DETAIL_ID
		, CAST(IMMUNIZATION.VX_CODE AS varchar(50)) AS DRUG_SOURCE_VALUE 
		, CAST(COALESCE(SOURCE_CONCEPT.CONCEPT_ID,0) AS INT) AS DRUG_SOURCE_CONCEPT_ID
		, CAST(VX_ROUTE AS varchar(50)) AS ROUTE_SOURCE_VALUE
		, CAST(VX_DOSE_UNIT AS varchar(50)) AS DOSE_UNIT_SOURCE_VALUE
	FROM 
		cohort_omop_no_enc
		INNER JOIN TRACS_CDM.PCDM.IMMUNIZATION IMMUNIZATION ON cohort_omop_no_enc.PATID=IMMUNIZATION.PATID and immunization.encounterid is null
		LEFT OUTER JOIN TRACS_CDM.OMOP.CONCEPT SOURCE_CONCEPT 
			ON IMMUNIZATION.VX_CODE=SOURCE_CONCEPT.CONCEPT_CODE 
			AND ((SOURCE_CONCEPT.VOCABULARY_ID='CVX' AND IMMUNIZATION.VX_CODE_TYPE='CX') OR (SOURCE_CONCEPT.VOCABULARY_ID='NDC' AND IMMUNIZATION.VX_CODE_TYPE='ND'))
		LEFT OUTER JOIN TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP ON SOURCE_CONCEPT.CONCEPT_ID = CONCEPT_RELATIONSHIP.CONCEPT_ID_1  AND CONCEPT_RELATIONSHIP.RELATIONSHIP_ID = 'Maps to'
		LEFT OUTER JOIN TRACS_CDM.OMOP.CONCEPT TARGET_CONCEPT ON CONCEPT_RELATIONSHIP.CONCEPT_ID_2 = TARGET_CONCEPT.CONCEPT_ID AND TARGET_CONCEPT.STANDARD_CONCEPT='S' AND TARGET_CONCEPT.DOMAIN_ID='Drug'
		LEFT OUTER JOIN TRACS_CDM.XOMOP.PCDM_TO_OMOP_MAP XWALK_ROUTE ON (IMMUNIZATION.VX_ROUTE=XWALK_ROUTE.SOURCE_VALUE AND XWALK_ROUTE.SOURCE_COLUMN='RX_ROUTE' AND XWALK_ROUTE.TARGET_TABLE='DRUG_EXPOSURE')
),

drug_procedures as (
	SELECT
		  XSTG_COHORT_OMOP.PERSON_ID
		, CAST(TARGET_CONCEPT.CONCEPT_ID AS INT) DRUG_CONCEPT_ID
		, CAST(PX_DATE AS DATE) DRUG_EXPOSURE_START_DATE
		, CAST(PX_DATE AS DATE) DRUG_EXPOSURE_END_DATE
		, CAST(PX_DATE AS DATE) VERBATIM_END_DATE
		, CASE WHEN PROCEDURES.PX_SOURCE='OD' THEN 32818 ELSE 32817 END DRUG_TYPE_CONCEPT_ID
		, NULL AS STOP_REASON
		, CAST(NULL AS INT) AS REFILLS
		, CAST(NULL AS FLOAT) AS QUANTITY
		, CAST(NULL AS INT) AS DAYS_SUPPLY
		, CAST(NULL AS varchar(50)) AS SIG
		, CAST(NULL AS INT) ROUTE_CONCEPT_ID -- should this be 0 or NULL?
		, NULL AS LOT_NUMBER
		, NULL AS PROVIDER_ID
		, XSTG_COHORT_OMOP.VISIT_OCCURRENCE_ID
		, XSTG_COHORT_OMOP.VISIT_DETAIL_ID AS VISIT_DETAIL_ID
		, CAST(PROCEDURES.PX AS varchar(50)) AS DRUG_SOURCE_VALUE
		, CAST(COALESCE(SOURCE_CONCEPT.CONCEPT_ID,0) AS INT) AS DRUG_SOURCE_CONCEPT_ID
		, NULL AS ROUTE_SOURCE_VALUE
		, NULL AS DOSE_UNIT_SOURCE_VALUE		
	FROM
		TRACS_CDM.XOMOP.XSTG_COHORT_OMOP
		INNER JOIN TRACS_CDM.PCDM.PROCEDURES PROCEDURES ON XSTG_COHORT_OMOP.PATID=PROCEDURES.PATID AND XSTG_COHORT_OMOP.ENCOUNTERID=PROCEDURES.ENCOUNTERID
		INNER JOIN TRACS_CDM.OMOP.CONCEPT SOURCE_CONCEPT ON PROCEDURES.PX=SOURCE_CONCEPT.CONCEPT_CODE AND 
			(		(SOURCE_CONCEPT.VOCABULARY_ID='ICD9Proc' AND PROCEDURES.PX_TYPE='09') 
				OR  (SOURCE_CONCEPT.VOCABULARY_ID='ICD10PCS' AND PROCEDURES.PX_TYPE='10')
				OR  (SOURCE_CONCEPT.VOCABULARY_ID IN ('CPT4','HCPCS')	 AND PROCEDURES.PX_TYPE='CH'))
		INNER JOIN TRACS_CDM.OMOP.CONCEPT_RELATIONSHIP ON SOURCE_CONCEPT.CONCEPT_ID = CONCEPT_RELATIONSHIP.CONCEPT_ID_1  AND CONCEPT_RELATIONSHIP.RELATIONSHIP_ID = 'Maps to'
		INNER JOIN TRACS_CDM.OMOP.CONCEPT TARGET_CONCEPT ON CONCEPT_RELATIONSHIP.CONCEPT_ID_2 = TARGET_CONCEPT.CONCEPT_ID AND TARGET_CONCEPT.STANDARD_CONCEPT='S' AND TARGET_CONCEPT.DOMAIN_ID='Drug'
)
insert into TRACS_CDM.OMOP.XSTG_DRUG_EXPOSURE WITH (TABLOCK)
(
	DRUG_EXPOSURE_ID,
	PERSON_ID,
	DRUG_CONCEPT_ID,
	DRUG_EXPOSURE_START_DATE,
	DRUG_EXPOSURE_START_DATETIME,
	DRUG_EXPOSURE_END_DATE,
	DRUG_EXPOSURE_END_DATETIME,
	VERBATIM_END_DATE,
	DRUG_TYPE_CONCEPT_ID,
	STOP_REASON,
	REFILLS,
	QUANTITY,
	DAYS_SUPPLY,
	SIG,
	ROUTE_CONCEPT_ID,
	LOT_NUMBER,
	PROVIDER_ID,
	VISIT_OCCURRENCE_ID,
	VISIT_DETAIL_ID,
	DRUG_SOURCE_VALUE,
	DRUG_SOURCE_CONCEPT_ID,
	ROUTE_SOURCE_VALUE,
	DOSE_UNIT_SOURCE_VALUE
)
select
	row_number() over(order by visit_occurrence_id) as drug_exposure_id,
	cast(PERSON_ID as numeric(18,0)) as PERSON_ID,
	cast(coalesce(DRUG_CONCEPT_ID,0) as numeric(18,0)) as DRUG_CONCEPT_ID,
	cast(DRUG_EXPOSURE_START_DATE as date) as DRUG_EXPOSURE_START_DATE,
	cast(DRUG_EXPOSURE_START_DATE as date) DRUG_EXPOSURE_START_DATETIME,
	cast(DRUG_EXPOSURE_END_DATE as date) as DRUG_EXPOSURE_END_DATE,
	cast(DRUG_EXPOSURE_END_DATE as date) as DRUG_EXPOSURE_END_DATETIME,
	cast(VERBATIM_END_DATE as date) VERBATIM_END_DATE,
	cast(DRUG_TYPE_CONCEPT_ID as numeric(18,0)) DRUG_TYPE_CONCEPT_ID,
	cast(STOP_REASON as varchar(20)) as STOP_REASON,
	try_cast(REFILLS as INT) as REFILLS,
	cast(QUANTITY as float) as QUANTITY,
	try_cast(DAYS_SUPPLY as INT) as DAYS_SUPPLY,
	cast(SIG as varchar(50)) as SIG,
	cast(ROUTE_CONCEPT_ID as numeric(18,0)) ROUTE_CONCEPT_ID,
	cast(LOT_NUMBER as varchar(50)) as LOT_NUMBER,
	cast(PROVIDER_ID as numeric(18,0)) as PROVIDER_ID,
	cast(VISIT_OCCURRENCE_ID as numeric(18,0)) as VISIT_OCCURRENCE_ID,
	cast(VISIT_DETAIL_ID as numeric(18,0)) as VISIT_DETAIL_ID,
	cast(DRUG_SOURCE_VALUE as varchar(50)) as DRUG_SOURCE_VALUE,
	cast(DRUG_SOURCE_CONCEPT_ID as numeric(18,0)) as DRUG_SOURCE_CONCEPT_ID,
	cast(ROUTE_SOURCE_VALUE as varchar(50)) as ROUTE_SOURCE_VALUE,
	cast(DOSE_UNIT_SOURCE_VALUE as varchar(50)) as DOSE_UNIT_SOURCE_VALUE
from
(
	select DISTINCT * from drug_prescribing
	UNION
	select DISTINCT * from drug_med_admin
	UNION
	SELECT DISTINCT * FROM drug_immunization
	UNION
	select DISTINCT * from drug_immunization_no_enc
	UNION
	SELECT DISTINCT * FROM drug_procedures
) subq
where
	drug_exposure_start_date is not null
;
--ALTER INDEX ALL ON TRACS_CDM.OMOP.XSTG_DRUG_EXPOSURE REBUILD with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
