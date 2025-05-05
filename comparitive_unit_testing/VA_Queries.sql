/************************************************************************
Projects2 (\vhacdwfpcfs02.vha.med.va.gov):\VINCI_Feasibility\1:/VINCI_Feasibility/1). Feasibility Projects

VINCI_Feasibility.CurrentMonth.PIname_DateYYMMDD_G_XXX_Description
VINCI_Feasibility.CurrentMonth.PIname_DateYYMMDD

Project : OMOP_250331
Type : [Feasibility]
PI : OMOP
Author : Nai-Chung Chang
Date : 03/31/2025
Server : RB03
Data Source : OMOP CDW
QA Reviewer : Zhenyu Lu

Requests from Attrition Table:
Inclusion Criteria
1. G_7 Number of Veterans seen in outpatient or inpatient or in non-VA community care in period of time
2. G_8 Number of patients from row 7 seen with type 2 diabetes diagnosis (ICD codes)
3. G_9 Number of patients from row 8 had prescription for metformin

*************************************************************************/

/******************************** G_7 **********************************

            1. Number of  Veterans seen in outpatient or inpatient or in non-VA
            community care  in period of time (last 5 years)

            *All queries completed using OMOP data
*************************************************************************/

-- 1.1 Identify Patients with Visit to VA in the last 5 Years

DROP TABLE IF EXISTS #Visits;

SELECT
PERSON_ID,
VISIT_END_DATE AS VISIT_DATE --This is just VINCI Services way to grab Visit_Date, could also use VISIT_START_DATE
INTO #Visits
FROM CDWWork.OMOPV5.VISIT_OCCURRENCE
WHERE
(VISIT_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date) OR VISIT_END_DATE IS NULL) -- Start Date
AND VISIT_START_DATE < CAST(GETDATE() AS date) -- End Date
AND VISIT_START_DATE >= CAST('10/01/1999' AS date) -- Start of EHR

-- 1426289980 rows; 03m:35s

-- 1.2 Exclude Non-Veterans and Get Demographics

DROP TABLE IF EXISTS #G7;

WITH Visit AS (
SELECT PERSON_ID, MIN(VISIT_DATE) AS First_Vis
FROM #Visits
GROUP BY PERSON_ID
),
Demo AS (
SELECT DISTINCT
V.PERSON_ID
,First_Vis
,BIRTH_DATETIME AS BirthDateTime
,GENDER_CONCEPT_ID AS Gender
,RACE_CONCEPT_ID AS Race
,ETHNICITY_CONCEPT_ID AS Ethnicity
FROM Visit AS V
INNER JOIN
CDWWork.OMOPV5.PERSON AS P
ON V.PERSON_ID = P.PERSON_ID
WHERE x_VeteranFlag = 'Y'
)
SELECT DISTINCT
PERSON_ID,
First_Vis,
BirthDateTime,
G.CONCEPT_NAME AS Gender,
R.CONCEPT_NAME AS Race,
E.CONCEPT_NAME AS Ethnicity
INTO #G7
FROM Demo AS D
INNER JOIN CDWWork.OMOPV5.CONCEPT AS G
ON D.Gender = G.CONCEPT_ID
INNER JOIN CDWWork.OMOPV5.CONCEPT AS R
ON D.Race = R.CONCEPT_ID
INNER JOIN CDWWork.OMOPV5.CONCEPT AS E
ON D.Ethnicity = E.CONCEPT_ID
;

-- 8969724 rows; 01m:20s

-- 1.3 Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS VINCI_Feasibility.MAR.OMOP_250331_G7;

SELECT DISTINCT
PERSON_ID
INTO VINCI_Feasibility.MAR.OMOP_250331_G7
FROM #G7
;

SELECT COUNT(DISTINCT PERSON_ID) FROM VINCI_Feasibility.MAR.OMOP_250331_G7;

-- 8969724 DISTINCT patients; 00m:XXs

CREATE CLUSTERED COLUMNSTORE INDEX CCI
ON VINCI_Feasibility.MAR.OMOP_250331_G7
;
-- 00m:00s

-- 1.4 Breakdowns

-- Gender
SELECT
GENDER, COUNT(DISTINCT PERSON_ID)
FROM
#G7
GROUP BY Gender
ORDER BY Gender
;

-- Race
SELECT
Race, COUNT(DISTINCT PERSON_ID)
FROM
#G7
GROUP BY Race
ORDER BY Race
;

-- Ethnicity
SELECT
Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
#G7
GROUP BY Ethnicity
ORDER BY Ethnicity
;

/******************************** G_8 **********************************

            2. Number of patients from row 7 seen with type 2 diabetes diagnosis
            (ICD codes)

            *All queries completed using OMOP data
*************************************************************************/

-- 2.1 Look Up ICD Codes

SELECT DISTINCT
ICD10Code,
ICD10Description,
DOMAIN_ID
FROM
CDWWork.OMOPV5Dim.ICD10_CONCEPT
WHERE
ICD10Code LIKE 'E11.%'
;

-- 94 Rows; 00m:01s

-- 2.2 Create ICD Dim Table

DROP TABLE IF EXISTS #Dim_ICD;

SELECT DISTINCT
ICD10Code,
ICD10Description,
CONCEPT_ID,
Source_Concept_ID,
DOMAIN_ID
INTO
#Dim_ICD
FROM
CDWWork.OMOPV5Dim.ICD10_CONCEPT
WHERE
ICD10Code LIKE 'E11.%'
;

-- 150 Rows; 00m:01s
--Since the only domain_id returned for interested ICD codes is Condition, so below only check CONDITION_OCCURRENCE Table

-- 2.3 Identify Patients With Diagnosis

DROP TABLE IF EXISTS #G8;

-- VistA
SELECT DISTINCT
COH.PERSON_ID
INTO
#G8
FROM
#G7 AS COH
INNER JOIN
CDWWork.OMOPV5.CONDITION_OCCURRENCE AS C
ON C.PERSON_ID = COH.PERSON_ID
INNER JOIN
#Dim_ICD AS D
ON C.CONDITION_CONCEPT_ID = D.CONCEPT_ID
WHERE
(CONDITION_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date) OR CONDITION_END_DATE IS NULL) -- Start Date
AND CONDITION_START_DATE < CAST(GETDATE() AS date) -- End Date
AND CONDITION_START_DATE >= CAST('10/01/1999' AS date) -- Start of EHR

-- 2137457 Rows; 00m:09s

-- 2.4 Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS VINCI_Feasibility.MAR.OMOP_250331_G8;

SELECT DISTINCT
PERSON_ID
INTO VINCI_Feasibility.MAR.OMOP_250331_G8
FROM #G8
;

SELECT COUNT(DISTINCT PERSON_ID) FROM VINCI_Feasibility.MAR.OMOP_250331_G8;

-- 2137457 DISTINCT patients; 00m:02s

-- 2.5 Breakdowns

DROP TABLE IF EXISTS #G8BD;

SELECT DISTINCT
COH.PERSON_ID,
CAST(DATEDIFF(DAY,COH.BirthDateTime, COH.First_Vis)/365.25 AS INT) AS Age_1st_Vis,
Gender,
Race,
Ethnicity
INTO
#G8BD
FROM
#G7 AS COH
INNER JOIN
#G8 AS G
ON COH.PERSON_ID = G.PERSON_ID
;
-- 2147771 rows; 00m:04s

-- Age
WITH Age AS (
SELECT DISTINCT
PERSON_ID,
CASE
WHEN Age_1st_Vis >= 18 AND Age_1st_Vis <40 THEN '18-39'
WHEN Age_1st_Vis >= 40 AND Age_1st_Vis <50 THEN '40-49'
WHEN Age_1st_Vis >= 50 AND Age_1st_Vis <60 THEN '50-59'
WHEN Age_1st_Vis >= 60 AND Age_1st_Vis <70 THEN '60-69'
WHEN Age_1st_Vis >= 70 AND Age_1st_Vis <80 THEN '70-79'
WHEN Age_1st_Vis >= 80 THEN '80+'
ELSE 'Other'
END AS Age_Cat
FROM
#G8BD
)
SELECT
Age_Cat, COUNT(DISTINCT PERSON_ID)
FROM
Age
GROUP BY Age_Cat
ORDER BY Age_Cat
;

-- Gender
SELECT
GENDER, COUNT(DISTINCT PERSON_ID)
FROM
#G8BD
GROUP BY Gender
ORDER BY Gender
;

-- Race
SELECT
Race, COUNT(DISTINCT PERSON_ID)
FROM
#G8BD
GROUP BY Race
ORDER BY Race
;

-- Ethnicity
SELECT
Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
#G8BD
GROUP BY Ethnicity
ORDER BY Ethnicity
;

/******************************** G_9 **********************************

            3. Number of patients from row 8 had prescription for metformin

            *All queries completed using OMOP data
*************************************************************************/

-- 3.1 Look Up Drugs

SELECT DISTINCT
CONCEPT_ID
,CONCEPT_NAME
,Domain_ID
FROM
CDWWork.OMOPV5Dim.LocalDrug_CONCEPT
WHERE
Drug_Type_Concept_ID IS NULL
AND CONCEPT_ID > 0
AND (CONCEPT_NAME LIKE '%Metformin%'
OR LocalDrugNameWithDose LIKE '%Metformin%')
;

-- 85 rows; 00m:00s;

-- 3.2 Create Drug Dim Table

DROP TABLE IF EXISTS #Dim_Rx;

SELECT DISTINCT
CONCEPT_ID
, SOURCE_CONCEPT_ID
,DOMAIN_ID
INTO
#Dim_Rx
FROM
CDWWork.OMOPV5Dim.LocalDrug_CONCEPT
WHERE
Drug_Type_Concept_ID IS NULL
AND CONCEPT_ID > 0
AND (CONCEPT_NAME LIKE '%Metformin%'
OR LocalDrugNameWithDose LIKE '%Metformin%')
;

-- 116 rows; 00m:00s;

-- 3.3 Identify Patients with Drugs

DROP TABLE IF EXISTS #G9

-- VistA
SELECT DISTINCT
COH.PERSON_ID
INTO
#G9
FROM
#G8 AS COH
INNER JOIN
CDWWork.OMOPV5.DRUG_EXPOSURE AS D
ON COH.PERSON_ID = D.PERSON_ID
INNER JOIN
#Dim_Rx AS R
ON D.DRUG_CONCEPT_ID = R.CONCEPT_ID
WHERE
(DRUG_EXPOSURE_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date) OR DRUG_EXPOSURE_END_DATE IS NULL) -- Start Date
AND DRUG_EXPOSURE_START_DATE < CAST(GETDATE() AS date) -- End Date
AND DRUG_EXPOSURE_START_DATE >= CAST('10/01/1999' AS date) -- Start of EHR

-- 1165392 rows; :41s

-- 3.4 Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS VINCI_Feasibility.MAR.OMOP_250331_G9;

SELECT DISTINCT
PERSON_ID
INTO VINCI_Feasibility.MAR.OMOP_250331_G9
FROM #G9
;

SELECT COUNT(DISTINCT PERSON_ID) FROM VINCI_Feasibility.MAR.OMOP_250331_G9;

-- 1165392 DISTINCT patients; 00m:02s

-- 2.5 Breakdowns

DROP TABLE IF EXISTS #G9BD;

SELECT DISTINCT
COH.PERSON_ID,
CAST(DATEDIFF(DAY,COH.BirthDateTime, COH.First_Vis)/365.25 AS INT) AS Age_1st_Vis,
Gender,
Race,
Ethnicity
INTO
#G9BD
FROM
#G7 AS COH
INNER JOIN
#G9 AS G
ON COH.PERSON_ID = G.PERSON_ID
;
-- 1140564 rows; 00m:04s

-- Age
WITH Age AS (
SELECT DISTINCT
PERSON_ID,
CASE
WHEN Age_1st_Vis >= 18 AND Age_1st_Vis <40 THEN '18-39'
WHEN Age_1st_Vis >= 40 AND Age_1st_Vis <50 THEN '40-49'
WHEN Age_1st_Vis >= 50 AND Age_1st_Vis <60 THEN '50-59'
WHEN Age_1st_Vis >= 60 AND Age_1st_Vis <70 THEN '60-69'
WHEN Age_1st_Vis >= 70 AND Age_1st_Vis <80 THEN '70-79'
WHEN Age_1st_Vis >= 80 THEN '80+'
ELSE 'Other'
END AS Age_Cat
FROM
#G9BD
)
SELECT
Age_Cat, COUNT(DISTINCT PERSON_ID)
FROM
Age
GROUP BY Age_Cat
ORDER BY Age_Cat
;

-- Gender
SELECT
GENDER, COUNT(DISTINCT PERSON_ID)
FROM
#G9BD
GROUP BY Gender
ORDER BY Gender
;

-- Race
SELECT
Race, COUNT(DISTINCT PERSON_ID)
FROM
#G9BD
GROUP BY Race
ORDER BY Race
;

-- Ethnicity
SELECT
Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
#G9BD
GROUP BY Ethnicity
ORDER BY Ethnicity
;
/****************************************************************/

