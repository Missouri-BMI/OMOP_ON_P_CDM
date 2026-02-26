------------------------------------------------------------
--Please use those Src.OMOPV5_XXXXX views provisioned to your ORD space for research projects!!!!
------------------------------------------------------------


------------------------------------------------------------
-- Precheck
------------------------------------------------------------
---Tables that need:

-----Check Station number]


/*
SELECT *
FROM CDWWork.Dim.Sta3n
WHERE Sta3nName LIKE '%Iowa%';

SELECT *
FROM CDWWork.Dim.Sta3n
WHERE sta3n = 636;

SELECT InstitutionSID, InstitutionIEN, sta3n, InstitutionName, BillingInstitution
,VATypeCode, StreetAddress1, StreetAddress2, City, Zip, InstitutionCode, InactiveFlag, stapa, StaPaName,StaPc, StaPcName
FROM CDWWork.dim.Institution
where sta3n = 636
and StaPa like '636%'
AND InactiveFlag IS NULL
order by StaPa, StaPc, InstitutionCode;*/


--636A8
--VAMC: A4-A9
--OOS: QA-QZ; Q1-Q9   (Other outpatient Service Site)
--CBOC: GA-GZ; G1-G9; JA-JZ; J1-J9

/**	VistA Consolidated Sites
SELECT
		Sta3n
		,Sta3nName
		,Active
		,NextSta3n
	FROM
		CDWWork.Dim.Sta3n AS ST3
	WHERE
			(ST3.nextsta3n IS NOT NULL
		OR Sta3n IN (SELECT NextSta3n FROM CDWWork.Dim.Sta3n))
		and sta3n > 0
	ORDER BY
		NextSta3n;
**/

------------------------------------------------------------
-- Number of alive Veterans seen outpatient, inpatient in Iowa VA MC from 2020-01-01 to 2024-06-30
------------------------------------------------------------

create or replace  temp table OMOPVisit as
SELECT DISTINCT Person_ID
FROM atlas_mu_dev.cdm.VISIT_OCCURRENCE as a
--only need this join when need limit institution code
inner join atlas_mu_dev.cdm.CARE_SITE as b on a.CARE_SITE_ID = b.CARE_SITE_ID
--only need this join when need limit VISIT type
INNER JOIN atlas_mu_dev.cdm.CONCEPT AS C ON A.VISIT_CONCEPT_ID = C.CONCEPT_ID
WHERE
(
(VISIT_END_DATE >= CAST('2020-01-01'AS DATE) OR VISIT_END_DATE IS NULL) -- Patients can be currently inpatient
			AND VISIT_START_DATE >= CAST('10/01/1999' AS Date) -- Only get records after the start of EHR Records
			AND VISIT_START_DATE < CAST('2024-07-01'AS DATE) --Enter Study Window End Date Here
)
--and x_InstitutionCode = '636A8' ---limit station here,
--1. use visit_concept_id (need add a join to concept c table!)
/*and (
(c.CONCEPT_NAME like '%outpat%' or c.CONCEPT_NAME in ('Emergency Room Visit'
, 'Telehealth'  --you can decide to include or exclude ER AND/OR Telehealth for your project
))--outpat visit
or (c.CONCEPT_NAME like '%inpat%' or c.CONCEPT_NAME in ('Non-hospital institution Visit'
, 'Observation Room' --you can decide to include or exclude observation room visit for your project
)) --inpat visit
) */
--and x_Source_Table <> 'Fee_Inpatient_Merged' --since I don't need community care data
--and x_WorkloadLogicFlag = 'Y';
--78514
;
select * from omopvisit;

create or replace temp table Row7 as
SELECT A.PERSON_ID, B.BIRTH_DATETIME
from OMOPVisit AS A
INNER JOIN atlas_mu_dev.cdm.PERSON AS B ON A.PERSON_ID = B.PERSON_ID --AND B.x_VeteranFlag = 'Y'
LEFT JOIN atlas_mu_dev.cdm.DEATH AS C ON B.PERSON_ID = C.PERSON_ID
WHERE C.PERSON_ID IS NULL;
---

SELECT COUNT(DISTINCT PERSON_ID)
from Row7;
--4466618
------------------------------------------------------------
-- Age 18-85 (included)
------------------------------------------------------------
create or replace temp table Row8 as
WITH CTE AS (
SELECT A.*, CAST(DATEDIFF(DAY, BIRTH_DATETIME, CAST(GETDATE() AS DATE))/365.25 AS INT) AS Age
from Row7 as a
)
SELECT *
FROM CTE
WHERE Age >=18 and Age <= 85;

---
SELECT COUNT(DISTINCT PERSON_ID)
from Row8;
--2227089

------------------------------------------------------------
-- The most recent BMI <=35
------------------------------------------------------------
---OMOP sourced from CDW, since BMI does not exits in source data directly, OMOP doesn't have BMI either, need fetch weight and height and then do calculation


create or replace temp table Dim_BMI as
select CONCEPT_ID, CONCEPT_NAME, DOMAIN_ID, VOCABULARY_ID, CONCEPT_CLASS_ID, STANDARD_CONCEPT
from atlas_mu_dev.cdm.Concept
where CONCEPT_ID IN ( 3036277, 3025315, 1029031, 1029318); --HEIGHT, WEIGHT
--2
select * from dim_bmi;


create or replace temp table Dim_BMI as
select CONCEPT_ID, CONCEPT_NAME, DOMAIN_ID, VOCABULARY_ID, CONCEPT_CLASS_ID, STANDARD_CONCEPT
from concept where concept_id IN ( 3036277, 3025315)
or ((lower(concept_name) like 'body weight'
or lower(concept_name) like 'body height')
and domain_id = 'Measurement');



select * from atlas_mu_dev.cdm.Concept limit 10;


create or replace temp table OMOPWeightHeight as
SELECT DISTINCT A.Person_ID
,MEASUREMENT_DATE
,VALUE_AS_NUMBER
,VALUE_SOURCE_VALUE
,MEASUREMENT_SOURCE_VALUE
--,c.CONCEPT_ID
,UNIT_SOURCE_VALUE
FROM atlas_mu_dev.cdm.MEASUREMENT as a
INNER join Row8 AS b ON A.PERSON_ID =b.PERSON_ID
--INNER join Dim_BMI AS C ON A.MEASUREMENT_CONCEPT_ID = C.CONCEPT_ID
--commented out if don't need station info
--INNER join atlas_mu_dev.cdm.CARE_SITE as b on a.x_CARE_SITE_ID = b.CARE_SITE_ID
WHERE
(MEASUREMENT_DATE >=  CAST('2020-01-01' AS Date)  AND MEASUREMENT_DATE < CAST('2024-07-01' AS Date));
--and x_InstitutionCode = '636A8' ---if request, limit station here
--848358
select * from omopweightheight;

select distinct c.* from measurement m
join concept c
on m.measurement_concept_id=c.concept_id
where lower(c.concept_name) like '%inches%';limit 10;


---Get Median heigh and most recent weight
create or replace temp table Height as
SELECT DISTINCT PERSON_ID, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY VALUE_AS_NUMBER)OVER (PARTITION BY PERSON_ID) AS MedianHeight
from OMOPWeightHeight
WHERE CONCEPT_ID = 3036277;  --Height



--46840
create or replace temp table Weight as
WITH CTE AS (
SELECT PERSON_ID, VALUE_AS_NUMBER AS Weight, ROW_NUMBER() OVER (PARTITION BY PERSON_ID ORDER BY  MEASUREMENT_DATE DESC) AS WeightRowNumber
from OMOPWeightHeight
WHERE CONCEPT_ID = 3025315  --Weight
)
SELECT * FROM CTE WHERE WeightRowNumber = 1;
--54689


create or replace temp table BMI as
SELECT
	H.PERSON_ID
	,CAST((W.Weight * 703)/POWER(H.MedianHeight, 2) AS DEC(5,1)) AS BMI
from Height AS H
INNER join Weight AS W ON H.PERSON_ID = W.PERSON_ID;
--46825

create or replace temp table Row9 as
SELECT *
from BMI
WHERE BMI <= 35;

--36491


SELECT COUNT(DISTINCT PERSON_ID)
from Row9;
--36491


------------------------------------------------------------
-- Latest eGFR less than <=60 ml/min OR with established diagnosis of CKD stage 4 and 5 as identified by the criteria N18.4 and N18.5 ICD 10 code  from 2020-01-01 to 2024-06-30
------------------------------------------------------------
--eGFR Lab
--Clinical Knowledge:
--Estimated Glomerular Filtration Rate (eGFR). This test allows the clinician to estimate how well your kidneys are functioning.
--The glomerulus is a group of blood vessels (capillaries) that filter your blood in your kidneys. You have about 1 million glomeruli in each kidney.
--The kidneys should filter a certain amount of blood in a given time. The labs check the amount of creatinine in your blood.
--The body produces a constant amount of creatinine, which is then in turn filtered out of your kidneys.
--If the level of creatinine is high, then the clinician can tell the kidneys are not functioning as well as they should.
--Since not every body is the same, the eGFR uses different factors to calculate your kidney function.
--As you age, your kidneys slow down, men s vs woman s kidneys function at different speeds, and there is some evidence different races  kidneys function at different speeds.
--The eGFR takes each factor into account to calculate your kidneys function.
--Normal kidney function is a score above 90, a score of 60-89 is reduced kidney function, 30-59 is moderately reduced kidney function, 15-29 is severe kidney function,
--and below 15 is very severe or end-stage renal failure -- usually the patient is on dialysis at this point.
create or replace temp table LabChemTest_CONCEPT as
select concept_name LabChemTestName, CONCEPT_ID,concept_name CONCEPT_NAME, concept_code SOURCE_CONCEPT_ID, domain_id   from concept where
	concept_class_id='Lab Test';
select * from LabChemTest_CONCEPT;

---check lab
SELECT DISTINCT
/*    LOINC_Source,
	LOINC_Automated,
	LOINC_Mapped,
--	Automation_Method,
	Mapping_Method,*/
	LabChemTestName,
/*	Topography,
	Topography_Mapped,*/
	Unit_Original,
	Unit_Mapped,
	CONCEPT_ID,
	CONCEPT_NAME,
	SOURCE_CONCEPT_ID,
--	SOURCE_CONCEPT_NAME,
	DOMAIN_ID

FROM
	LabChemTest_CONCEPT

WHERE --Keep in mind, There are labs that not mapped in OMOP yet.
      --If you have a list of LOINC, you can also search LOINC_Mapped instead
	concept_name like '%CREATININE%' --if it is abbreviated need extra careful might bring some extra stuff suggest search full name since most of the time concept name has the full name
	AND concept_name not like '%ratio%'
	--limit on topography
	AND ( (CONCEPT_NAME LIKE '%body fluid%' and (Topography_Mapped LIKE '%BLOOD%' OR Topography_Mapped LIKE '%SERUM%' OR Topography_Mapped LIKE '%PLASMA%'))
	OR CONCEPT_NAME LIKE '%BLOOD%' OR CONCEPT_NAME LIKE '%SERUM%' OR CONCEPT_NAME LIKE '%PLASMA%')
    and concept_name not like '%urine%'
	AND concept_name not like '%UR %'
	and DOMAIN_ID = 'Measurement';
---2453

---Check how many unmapped
SELECT DISTINCT
	LabChemTestSID,
	TopographySID,
        LOINC_Source,
	LOINC_Automated,
	LOINC_Mapped,
	Automation_Method,
	Mapping_Method,
	LabChemTestName,
	Topography,
	Topography_Mapped,
	Unit_Original,
	Unit_Mapped,
	CONCEPT_ID,
	CONCEPT_NAME,
	SOURCE_CONCEPT_ID,
	SOURCE_CONCEPT_NAME,
	DOMAIN_ID,
	sta3n,
	InstanceCount,
	PatientCount


FROM
	CDWWork.OMOPV5Dim.LabChemTest_CONCEPT

WHERE
	LabChemTestName like '%CREAT%'
	and LabChemTestName not like '%urine%'
	AND LabChemTestName not like '%UR %'
	and LabChemTestName not like '%ratio%'
	AND ( Topography_Mapped LIKE '%BLOOD%' OR Topography_Mapped LIKE '%SERUM%' OR Topography_Mapped LIKE '%PLASMA%'
         )
	and DOMAIN_ID = 'Measurement'
	order by CONCEPT_ID, InstanceCount desc;
--2790
---First check how many rows/percentage unmapped (where concept_id =0)
---Then check instanceCount and PatientCount
---Then check the labchemtestname if this is the true lab you are looking for
---If Only few labs not mapped and the instance and patient count is so low, you should be good to just search concept name!
---If you encounter a lab that lots labchemtest not mapped and instance and patient count are high, please reach out to VINCI@VA.GOV with OMOP in the subject line and we will help communicate with OMOP mapping team to get those labs mapped! And meantime, just search those in Measurement table using x_labchemtestSID AND X_topographSID

---I only have 115 row not mapped and all of the rows are very low instance and patient counts and looking at the labchemtestname doesn't look like related labs
---so I am good to just use concept name search.


--create dim table:
create or replace temp table dim_Lab as
SELECT DISTINCT
	CONCEPT_ID,
	SOURCE_CONCEPT_ID,
	DOMAIN_ID,
	labchemtestSID,
	TopographySID,
	Unit_Original,
	CONCEPT_NAME,
	Topography,
	Topography_Mapped

FROM
	CDWWork.OMOPV5Dim.LabChemTest_CONCEPT

WHERE
	concept_name like '%CREATININE%'
	AND concept_name not like '%ratio%'
	AND (
	(CONCEPT_NAME LIKE '%body fluid%' and (Topography_Mapped LIKE '%BLOOD%' OR Topography_Mapped LIKE '%SERUM%' OR Topography_Mapped LIKE '%PLASMA%'))
	OR CONCEPT_NAME LIKE '%BLOOD%' OR CONCEPT_NAME LIKE '%SERUM%' OR CONCEPT_NAME LIKE '%PLASMA%'
	)
    and concept_name not like '%urine%'
	AND concept_name not like '%UR %'
	and DOMAIN_ID = 'Measurement';
---2594

create or replace temp table OMOPlab_Measurement as
SELECT DISTINCT  A.Person_ID
,MEASUREMENT_DATE
,VALUE_AS_NUMBER
,UNIT_SOURCE_VALUE
,MEASUREMENT_SOURCE_VALUE
,x_LabChemTestSID, x_TopographySID, x_Source_Table, x_Source_ID_Primary
FROM atlas_mu_dev.cdm.MEASUREMENT as a
INNER join Row9 AS B ON A.PERSON_ID = B.PERSON_ID
INNER join dim_Lab AS C ON A.MEASUREMENT_CONCEPT_ID = C.CONCEPT_ID
--commented out if don't need station info
--INNER join atlas_mu_dev.cdm.CARE_SITE as D on a.x_CARE_SITE_ID = D.CARE_SITE_ID
WHERE
(MEASUREMENT_DATE >=  CAST('2020-01-01' AS Date)  AND MEASUREMENT_DATE < CAST('2024-07-01' AS Date))
AND VALUE_AS_NUMBER IS NOT NULL;
--and x_InstitutionCode = '636A8' ---if request, limit station here
--343589


create or replace temp table OMOPlab as
SELECT Person_ID
,MEASUREMENT_DATE
,VALUE_AS_NUMBER
,UNIT_SOURCE_VALUE
from OMOPlab_Measurement;


---Check lab unit, it should all be 'mg/dl', if not, check the value to see if the unite makes sense or it's some mapping issue. If you think there is mapping issues please reach out to VINCI@VA.GOV with OMOP in the subject line
SELECT COUNT(*), UNIT_SOURCE_VALUE
from OMOPlab
GROUP BY UNIT_SOURCE_VALUE;

SELECT * from OMOPlab WHERE UNIT_SOURCE_VALUE = '';
--2409, checking those values some are way high (like in hundreds which should not be for unit mg/dl, I will remove those from my result set)

---In order to get eGFR, need to get age (at labtestdate), gender, race
create or replace temp table RaceEthnicity as
SELECT DISTINCT A.PERSON_ID, VALUE_AS_NUMBER, MEASUREMENT_DATE, B.BIRTH_DATETIME, CAST(DATEDIFF(DAY, BIRTH_DATETIME, MEASUREMENT_DATE)/365.25 AS INT) AS Age_Lab,
B.GENDER_SOURCE_VALUE AS Gender, B.RACE_SOURCE_VALUE AS Race , B.ETHNICITY_SOURCE_VALUE as Ethnicity
from OMOPlab AS A
INNER JOIN atlas_mu_dev.cdm.PERSON AS B ON A.PERSON_ID = B.PERSON_ID
where A.UNIT_SOURCE_VALUE <> '';
---339651

---
create or replace temp table eGFR as
SELECT DISTINCT
		Person_ID
		,175.0
			* POWER(VALUE_AS_NUMBER, -1.154)
			* POWER(1.000 * Age_Lab, -0.203)
			* (CASE WHEN Gender <> 'F' THEN 1 ELSE .742 END)
			* (CASE WHEN Race <> 'Black or African American' THEN 1 ELSE 1.212 END)
		  AS eGFR
		--,LabChemSpecimenDateTime
		--,'mL/min/1.73m2' as [Calculated eGFR Units] -- Uncomment if providing eGFR values
		,ROW_NUMBER() OVER(PARTITION BY Person_ID ORDER BY MEASUREMENT_DATE DESC) AS RN  --add row number if you wish to get most recent eGFR
	FROM
		RaceEthnicity;
--339651
create or replace temp table eGFR_Qualified as
SELECT *
from eGFR
WHERE RN =1 AND eGFR <= 60;

--6307

--diagnosis of CKD stage 4 and 5

create or replace temp table ICD10_CONCEPT as
select concept_name ICD10DESCRIPTION, concept_id, domain_id,concept_code ICD10CODE, concept_code SOURCE_CONCEPT_ID  from atlas_mu_dev.cdm.concept
where vocabulary_id = 'ICD10CM';
and domain_id = 'ICD10CM';

-- Check ICD10 Codes
SELECT DISTINCT
	ICD10CODE,
	ICD10DESCRIPTION,
	CONCEPT_ID,
	SOURCE_CONCEPT_ID
	,DOMAIN_ID
FROM
    ICD10_CONCEPT
WHERE
	ICD10CODE IN ('N18.4', 'N18.5');--Put ICD10 code here



-- CREATE Dim Tables
create or replace temp table dim_condition_Row10 as
SELECT DISTINCT
	CONCEPT_ID
	,SOURCE_CONCEPT_ID
	,DOMAIN_ID
FROM
	ICD10_CONCEPT
WHERE
	ICD10CODE IN ('N18.4', 'N18.5') ;

create or replace temp table ICD_patient_ROW10 as
SELECT DISTINCT
A.PERSON_ID
FROM atlas_mu_dev.cdm.CONDITION_OCCURRENCE AS A
INNER join Row9 AS B ON A.PERSON_ID = B.PERSON_ID
INNER join dim_condition_Row10 AS C ON C.CONCEPT_ID = A.CONDITION_CONCEPT_ID
--If need limit on station, then uncommented out those 2 joins below
--INNER JOIN atlas_mu_dev.cdm.VISIT_OCCURRENCE as V  ON A.VISIT_OCCURRENCE_ID = v.VISIT_OCCURRENCE_ID
--INNER join atlas_mu_dev.cdm.CARE_SITE as care on care.CARE_SITE_ID = v.CARE_SITE_ID

WHERE

(CONDITION_End_date >= CAST('2020-01-01' AS Date)  -- Enter Study Window Start Date Here
					OR CONDITION_End_date IS NULL) -- Patients can be currently inpatient
			AND CONDITION_START_DATE >= CAST('10/01/1999' AS Date) -- Only get records after the start of EHR Records
			AND CONDITION_START_DATE < CAST('2024-07-01' AS Date)
--If need limit on station, then uncommented out this line
--AND x_InstitutionCode = '636A8' ---if request, limit station here
-----AND A.x_Source_Table NOT LIKE 'Fee%'; --Exclude fee source since I only need inpat and outpat
---930
;


create or replace temp table ROW10 as
SELECT PERSON_ID
from ICD_patient_ROW10
UNION
SELECT PERSON_ID
from eGFR_Qualified;

--6405

SELECT COUNT(DISTINCT Person_ID) from ROW10;
--6405

------------------------------------------------------------
-- EXCLUSION: End Stage Renal Disease (ICD-10 Codes) or dialysis based on CPT codes
------------------------------------------------------------

-- Check ICD10 Codes
SELECT DISTINCT
	ICD10CODE,
	ICD10DESCRIPTION,
	CONCEPT_ID,
	SOURCE_CONCEPT_ID
	,DOMAIN_ID
	--,InstanceCount
	--,PatientCount
FROM
	ICD10_CONCEPT
WHERE
	ICD10CODE IN ('N18.6', 'Z49.31', 'Z99.2')--Put ICD10 code here
order by ICD10Code;
---Those codes exists in Condition, procedure and Observation domains

-- CREATE Dim Tables
create or replace temp table dim_condition_Row12 as
SELECT DISTINCT
	CONCEPT_ID
	,SOURCE_CONCEPT_ID
	,DOMAIN_ID
FROM
	ICD10_CONCEPT
WHERE
	ICD10CODE IN ('N18.6', 'Z49.31', 'Z99.2');


create or replace temp table ICD_patient_ROW12 as
SELECT DISTINCT
A.PERSON_ID
FROM atlas_mu_dev.cdm.CONDITION_OCCURRENCE AS A
INNER join Row10 AS B ON A.PERSON_ID = B.PERSON_ID
INNER join dim_condition_Row12 AS C ON C.CONCEPT_ID = A.CONDITION_CONCEPT_ID
--If need limit on station, then uncommented out those 2 joins below
--INNER JOIN atlas_mu_dev.cdm.VISIT_OCCURRENCE as V  ON A.VISIT_OCCURRENCE_ID = v.VISIT_OCCURRENCE_ID
--INNER join atlas_mu_dev.cdm.CARE_SITE as care on care.CARE_SITE_ID = v.CARE_SITE_ID

WHERE

(CONDITION_End_date >= CAST('2020-01-01' AS Date)  -- Enter Study Window Start Date Here
					OR CONDITION_End_date IS NULL) -- Patients can be currently inpatient
			AND CONDITION_START_DATE >= CAST('10/01/1999' AS Date) -- Only get records after the start of EHR Records
			AND CONDITION_START_DATE < CAST('2024-07-01' AS Date);
--If need limit on station, then uncommented out this line
--AND x_InstitutionCode = '636A8' ---if request, limit station here

---618



create or replace temp table ICD_patient_observ as
SELECT DISTINCT
A.PERSON_ID
FROM atlas_mu_dev.cdm.OBSERVATION AS A
INNER join Row10 AS B ON A.PERSON_ID = B.PERSON_ID
INNER join dim_condition_Row12 AS C ON C.SOURCE_CONCEPT_ID = A.OBSERVATION_SOURCE_CONCEPT_ID
--If need limit on station, then uncommented out those 2 joins below
--INNER JOIN atlas_mu_dev.cdm.VISIT_OCCURRENCE as V  ON A.VISIT_OCCURRENCE_ID = v.VISIT_OCCURRENCE_ID
--INNER join atlas_mu_dev.cdm.CARE_SITE as care on care.CARE_SITE_ID = v.CARE_SITE_ID

WHERE

(OBSERVATION_DATE >= CAST('2020-01-01' AS Date)
			AND OBSERVATION_DATE < CAST('2024-07-01' AS Date))
--If need limit on station, then uncommented out this line
--and x_InstitutionCode = '636A8' ---if request, limit station here

---477

create or replace temp table ICDProc_patient as
SELECT DISTINCT
A.PERSON_ID
FROM atlas_mu_dev.cdm.PROCEDURE_OCCURRENCE AS A
INNER join Row10 AS B ON A.PERSON_ID = B.PERSON_ID
INNER join dim_condition_Row12 AS sids ON sids.SOURCE_CONCEPT_ID =A.PROCEDURE_SOURCE_CONCEPT_ID
--If need limit on station, then uncommented out those 2 joins below
--INNER JOIN atlas_mu_dev.cdm.VISIT_OCCURRENCE as V  ON A.VISIT_OCCURRENCE_ID = v.VISIT_OCCURRENCE_ID
--INNER join atlas_mu_dev.cdm.CARE_SITE as care on care.CARE_SITE_ID = v.CARE_SITE_ID

WHERE
	(PROCEDURE_DATE >= CAST('2020-01-01' AS Date)    AND PROCEDURE_DATE < CAST('2024-07-01' AS Date))
--If need limit on station, then uncommented out this line
--and x_InstitutionCode = '636A8' ---if request, limit station here
--92



----dialysis based on CPT codes

-- Check CPT Codes
SELECT DISTINCT
	CPTCODE,
	CPTDESCRIPTION,
	CONCEPT_ID,
	SOURCE_CONCEPT_ID,
	DOMAIN_ID
	,InstanceCount
	,PatientCount

FROM
	CDWWork.OMOPV5Dim.CPT_CONCEPT

WHERE
	CPTCode like '9094[1-7]'
	or CPTCode like '9099[7,9]'
ORDER BY CONCEPT_ID





-- CREATE Dim Tables
create or replace temp table dim_proc as
SELECT distinct
	CONCEPT_ID,
	SOURCE_CONCEPT_ID,
	DOMAIN_ID,
	CPTCode
INTO
	#dim_proc
FROM
	CDWWork.OMOPV5Dim.CPT_CONCEPT
WHERE
	CPTCode like '9094[1-7]'
	or CPTCode like '9099[7,9]'



DROP TABLE IF EXISTS #CPTProc_patient
SELECT DISTINCT
A.PERSON_ID
INTO
	#CPTProc_patient
FROM atlas_mu_dev.cdm.PROCEDURE_OCCURRENCE AS A
INNER join Row10 AS B ON A.PERSON_ID = B.PERSON_ID
INNER join dim_proc AS sids ON sids.SOURCE_CONCEPT_ID =A.PROCEDURE_SOURCE_CONCEPT_ID   and sids.SOURCE_CONCEPT_ID <> 0
--If need limit on station, then uncommented out those 2 joins below
--INNER JOIN atlas_mu_dev.cdm.VISIT_OCCURRENCE as V  ON A.VISIT_OCCURRENCE_ID = v.VISIT_OCCURRENCE_ID
--INNER join atlas_mu_dev.cdm.CARE_SITE as care on care.CARE_SITE_ID = v.CARE_SITE_ID

WHERE
	(PROCEDURE_DATE >= CAST('2020-01-01' AS Date)    AND PROCEDURE_DATE < CAST('2024-07-01' AS Date))
--If need limit on station, then uncommented out this line
--and x_InstitutionCode = '636A8' ---if request, limit station here
--402




create or replace temp table ROW12_EXC as
SELECT PERSON_ID
from ICD_patient_ROW12
UNION
SELECT PERSON_ID
from ICD_patient_observ
UNION
SELECT PERSON_ID
from ICDProc_patient
UNION
SELECT PERSON_ID
from CPTProc_patient




--633
create or replace temp table ROW12 as
SELECT A.*
from ROW10 AS A
LEFT join ROW12_EXC AS B ON A.PERSON_ID = B.PERSON_ID
WHERE B.PERSON_ID IS NULL

--5772

SELECT COUNT(DISTINCT PERSON_ID ) from ROW12
--5772
------------------------------------------------------------
-- EXCLUSION: On sunitinib (Sutent), pazopanib (Votrient), tivozanib (Fotivda), cabozantinib (Cabometyx), axitinib (Inlyta), and lenvatinib (Kisplyx)
------------------------------------------------------------

SELECT DISTINCT CONCEPT_ID
, CONCEPT_NAME
, SOURCE_CONCEPT_ID
, SOURCE_CONCEPT_NAME
, LocalDrugNameWithDose
, DrugUnit
, StrengthNumeric
, MedicationRoute
, DrugClass
, Drug_Type_Concept_ID
, DOMAIN_ID
FROM CDWWORK.OMOPV5Dim.LocalDrug_CONCEPT
where (
CONCEPT_NAME like '%sunitinib%'
or CONCEPT_NAME like '%Sutent%'
or CONCEPT_NAME like '%pazopanib%'
or CONCEPT_NAME like '%Votrient%'  or CONCEPT_NAME like '%tivozanib%'
or CONCEPT_NAME like '%Fotivda%'
or CONCEPT_NAME like '%Zoloft%'
or CONCEPT_NAME like '%cabozantinib%'
or CONCEPT_NAME like '%Cabometyx%'
or CONCEPT_NAME like '%axitinib%'
or CONCEPT_NAME like '%Inlyta%'
or CONCEPT_NAME like '%lenvatinib%'
or CONCEPT_NAME like '%Kisplyx%'
)
and Drug_Type_Concept_ID is null ----to exclude study drugs
--458

--check unmapped drugs
SELECT DISTINCT CONCEPT_ID
, CONCEPT_NAME
, SOURCE_CONCEPT_ID
, SOURCE_CONCEPT_NAME
, LocalDrugNameWithDose
, DrugUnit
, StrengthNumeric
, MedicationRoute
, DrugClass
, Drug_Type_Concept_ID
,InstanceCount
,PatientCount
, DOMAIN_ID
FROM CDWWORK.OMOPV5Dim.LocalDrug_CONCEPT
where (LocalDrugNameWithDose like '%sunitinib%'
or LocalDrugNameWithDose like '%Sutent%'
or LocalDrugNameWithDose like '%pazopanib%'
or LocalDrugNameWithDose like '%Votrient%'  or LocalDrugNameWithDose like '%tivozanib%'
or LocalDrugNameWithDose like '%Fotivda%'
or LocalDrugNameWithDose like '%Zoloft%'
or LocalDrugNameWithDose like '%cabozantinib%'
or LocalDrugNameWithDose like '%Cabometyx%'
or LocalDrugNameWithDose like '%axitinib%'
or LocalDrugNameWithDose like '%Inlyta%'
or LocalDrugNameWithDose like '%lenvatinib%'
or LocalDrugNameWithDose like '%Kisplyx%'
)
and Drug_Type_Concept_ID is null ----if need exclude study drugs
ORDER BY CONCEPT_ID, InstanceCount DESC;
--2173

---If many are not mapped and with high instance /patient count, email VINCI@VA.GOV with OMOP in the subject line, we will communicate with OMOP mapping team to get those mapped, meantime can do a dim table like below:

--create dim table:

create or replace temp table dim_DRGU as
SELECT DISTINCT
	CONCEPT_ID,
	concept_code SOURCE_CONCEPT_ID
FROM atlas_mu_dev.cdm.concept
where (
lower(CONCEPT_NAME) like '%sunitinib%'
or lower(CONCEPT_NAME) like '%sutent%'
or lower(CONCEPT_NAME) like '%pazopanib%'
or lower(CONCEPT_NAME) like '%votrient%'
or lower(CONCEPT_NAME) like '%tivozanib%'
or lower(CONCEPT_NAME) like '%fotivda%'
or lower(CONCEPT_NAME) like '%zoloft%'
or lower(CONCEPT_NAME) like '%cabozantinib%'
or lower(CONCEPT_NAME) like '%cabometyx%'
or lower(CONCEPT_NAME) like '%axitinib%'
or lower(CONCEPT_NAME) like '%inlyta%'
or lower(CONCEPT_NAME) like '%lenvatinib%'
or lower(CONCEPT_NAME) like '%kisplyx%'
) and domain_id='Drug';/*
AND SOURCE_CONCEPT_ID = 0)  --only look for localdrugnamewithdose when not mapped
)
and Drug_Type_Concept_ID is null; ----to exclude study drugs*/

--2453

create or replace temp table OMOPMed as
SELECT a.PERSON_ID
FROM atlas_mu_dev.cdm.DRUG_EXPOSURE as a
INNER join Row12 as b on a.PERSON_ID = b.PERSON_ID
INNER join dim_DRGU AS D ON A.DRUG_SOURCE_CONCEPT_ID = D.SOURCE_CONCEPT_ID and d.SOURCE_CONCEPT_ID<> 0
--commented out if don't need station info
--INNER join atlas_mu_dev.cdm.CARE_SITE as b on a.x_CARE_SITE_ID = b.CARE_SITE_ID

WHERE
(DRUG_EXPOSURE_START_DATE >=  CAST('2024-01-01' AS Date)    AND DRUG_EXPOSURE_START_DATE < CAST('2024-07-01' AS Date))
--and x_InstitutionCode = '636A8' ---if request, limit station here
UNION
SELECT a.PERSON_ID
FROM atlas_mu_dev.cdm.DRUG_EXPOSURE as a
INNER join Row12 as b on a.PERSON_ID = b.PERSON_ID
INNER join dim_DRGU AS D ON A.x_LocalDrugSID = D.LocalDrugSID AND  D.SOURCE_CONCEPT_ID = 0
--commented out if don't need station info
--INNER join atlas_mu_dev.cdm.CARE_SITE as b on a.x_CARE_SITE_ID = b.CARE_SITE_ID
WHERE
(DRUG_EXPOSURE_START_DATE >=  CAST('2020-01-01' AS Date)    AND DRUG_EXPOSURE_START_DATE < CAST('2024-07-01' AS Date))
--and x_InstitutionCode = '636A8' ---if request, limit station here
---5


create or replace temp table ROW13 as
SELECT A.*
from ROW12 AS A
LEFT join OMOPMed AS B ON A.PERSON_ID = B.PERSON_ID
WHERE B.PERSON_ID IS NULL

--5767

SELECT COUNT(DISTINCT PERSON_ID ) from ROW13
--5767
