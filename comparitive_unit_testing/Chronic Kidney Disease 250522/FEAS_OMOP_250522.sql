/************************************************************************ 
Projects2 (\\vhacdwfpcfs02.vha.med.va.gov):\VINCI_Feasibility\1. Feasibility Projects

VINCI_Feasibility.CurrentMonth.PIname_DateYYMMDD_G_XXX_Description
VINCI_Feasibility.CurrentMonth.PIname_DateYYMMDD

Project		: [OMOP_250522]
Type		: [Feasibility]
PI			: [OMOP]
Author		: Nai-Chung Chang
Date		: 05/22/2025
Server		: RB03
Data Source	: CDWWork (/Millennium?)
QA Reviewer	: XXX

--------------------------------------------------------------------------

Requests from Attrition Table:
Inclusion Criteria
	1. G_7  Number of  Veterans seen nationwide  outpatient or inpatient or in non-VA community care  in period of time 
	2. G_8  Number of patients from row 7 seen with  Chronic kidney disease (CKD) diagnosis  (ICD codes)
	3. G_9  Number of patients from row 8 had eGFR <30 (the most recent)
	4. G_10 Number of patients from row 9 had dialysis (ICD or CPT codes)


--------------------------------------------------------------------------
Change Log:
Date:			By Whom:				Description of Change:	
XX/XX/XXXX		XXXXXX					XXXXX
QA Reviewer:
XXXX

*************************************************************************/
/*FEASIBILITY NOTES - Please see most recent work instructions, this is only a supplemental reminder guide

--Feasibilities do not require a DART

--Millennium Data should be provided unless researchers specifically state they do not want Millennium

--Check for consolidated sites (Active = Y, NextSta3n is null/blank)
------or NextSta3n = StationOfInterest, if neccesary use StaPa
-----If it is a consolidated site, need to confirm with researcher if they want ALL stations encaspulated in the Station number or else you need search Institution DIM to get Instution SID and StaPa 

--Placebos, allergy tests, double blind medications are excluded by default 

--Ensure any numbers on query results or deliverables less than 10 are denoted as <10

*/


/********************************  G_7  **********************************
	
	1. Number of  Veterans seen nationwide outpatient or inpatient or in 
	non-VA community care  in period of time 

	*All queries completed using OMOP data

*************************************************************************/

--	1.1		Identify Patients with Visit to VA in the last 5 Years

DROP TABLE IF EXISTS #Visits;

--VistA
SELECT 
	PERSON_ID,
	VISIT_END_DATE  AS VISIT_DATE 
INTO #Visits
FROM CDWWork.OMOPV5.VISIT_OCCURRENCE
WHERE 
	(VISIT_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date) OR VISIT_END_DATE IS NULL) -- Start Date
	AND VISIT_START_DATE < CAST(GETDATE() AS date) -- End Date
	AND VISIT_START_DATE >= CAST('10/01/1999' AS date) -- Start of EHR

--	1425398032 rows;		03m:35s

--	1.2		Exclude Non-Veterans and Get Demographics

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
	,CAST(DATEDIFF(DAY,BIRTH_DATETIME, First_Vis)/365.25 AS INT) AS Age_1st_Vis
	,GENDER_CONCEPT_ID AS Gender
	,RACE_CONCEPT_ID AS Race
	,ETHNICITY_CONCEPT_ID AS Ethnicity
FROM Visit AS V
	LEFT JOIN
	CDWWork.OMOPV5.PERSON AS P
	ON V.PERSON_ID = P.PERSON_ID
WHERE x_VeteranFlag = 'Y' 
)
SELECT DISTINCT
	PERSON_ID,
	First_Vis,
	BirthDateTime,
	Age_1st_Vis,
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

--	8967840 rows;	01m:20s


--	1.3		Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS VINCI_Feasibility.MAY.OMOP_250522_G7;

SELECT DISTINCT
	PERSON_ID
INTO VINCI_Feasibility.MAY.OMOP_250522_G7
FROM #G7
;

SELECT COUNT(DISTINCT PERSON_ID) FROM VINCI_Feasibility.MAY.OMOP_250522_G7;

--	8967840 DISTINCT patients;		00m:XXs



CREATE CLUSTERED COLUMNSTORE INDEX CCI
    ON VINCI_Feasibility.MAY.OMOP_250522_G7
;
--	00m:00s


--	1.4		Breakdowns

--	Age
WITH Age AS (
SELECT DISTINCT
	PERSON_ID,
	CASE 
		WHEN Age_1st_Vis >= 18 AND Age_1st_Vis <40 THEN '18-39'
		WHEN Age_1st_Vis >= 40 AND Age_1st_Vis <50 THEN '40-49'
		WHEN Age_1st_Vis >= 50 AND Age_1st_Vis <60 THEN '50-59'
		WHEN Age_1st_Vis >= 60 AND Age_1st_Vis <70 THEN '60-69'
		WHEN Age_1st_Vis >= 70 AND Age_1st_Vis <80 THEN '70-79'
		WHEN Age_1st_Vis >= 80  THEN '80+'
		ELSE 'Other'
	END AS Age_Cat
FROM
	#G7
)
SELECT 
	Age_Cat, COUNT(DISTINCT PERSON_ID)
FROM 
	Age
GROUP BY Age_Cat
ORDER BY Age_Cat
;

--	Gender
SELECT 
	GENDER, COUNT(DISTINCT PERSON_ID)
FROM
	#G7
GROUP BY Gender
ORDER BY Gender
;

--	Race
SELECT 
	Race, COUNT(DISTINCT PERSON_ID)
FROM
	#G7
GROUP BY Race
ORDER BY Race
;

--	Ethnicity
SELECT 
	Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
	#G7
GROUP BY Ethnicity
ORDER BY Ethnicity
;



/********************************  G_8  **********************************
	
	2. Number of patients from row 7 seen with  Chronic kidney disease 
	(CKD) diagnosis  (ICD codes)

	*All queries completed using OMOP data

*************************************************************************/


--	2.1		Look Up ICD Codes

SELECT DISTINCT
	ICD10Code,
	ICD10Description,
	DOMAIN_ID
FROM 
	CDWWork.OMOPV5Dim.ICD10_CONCEPT
WHERE
	ICD10Code LIKE 'N18.2%' OR ICD10Code LIKE 'N18.3%' OR ICD10Code LIKE 'N18.30%' 
	OR ICD10Code LIKE 'N18.31%' OR ICD10Code LIKE 'N18.32%' OR ICD10Code LIKE 'N18.4%' 
	OR ICD10Code LIKE 'N18.5%' OR ICD10Code LIKE 'N18.6%' OR ICD10Code LIKE 'N18.9%'
	;

--	9 Rows;	00m:02s


--	2.2		Create ICD Dim Table

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
	ICD10Code LIKE 'N18.2%' OR ICD10Code LIKE 'N18.3%' OR ICD10Code LIKE 'N18.30%' 
	OR ICD10Code LIKE 'N18.31%' OR ICD10Code LIKE 'N18.32%' OR ICD10Code LIKE 'N18.4%' 
	OR ICD10Code LIKE 'N18.5%' OR ICD10Code LIKE 'N18.6%' OR ICD10Code LIKE 'N18.9%'
	;

--	9 Rows;	00m:01s
	

--	2.3		Identify Patients With Diagnosis

DROP TABLE IF EXISTS #G8;

--	VistA
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
	
--	1225236 Rows;	00m:09s



--	2.4		Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS VINCI_Feasibility.MAY.OMOP_250522_G8;

SELECT DISTINCT
	PERSON_ID
INTO VINCI_Feasibility.MAY.OMOP_250522_G8
FROM #G8
;

SELECT COUNT(DISTINCT PERSON_ID) FROM VINCI_Feasibility.MAY.OMOP_250522_G8;

--	1225236 DISTINCT patients;		00m:02s


--	2.5		Breakdowns

DROP TABLE IF EXISTS #G8BD;

SELECT DISTINCT
	COH.PERSON_ID,
	Age_1st_Vis,
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
--	2147771 rows;	00m:04s

--	Age
WITH Age AS (
SELECT DISTINCT
	PERSON_ID,
	CASE 
		WHEN Age_1st_Vis >= 18 AND Age_1st_Vis <40 THEN '18-39'
		WHEN Age_1st_Vis >= 40 AND Age_1st_Vis <50 THEN '40-49'
		WHEN Age_1st_Vis >= 50 AND Age_1st_Vis <60 THEN '50-59'
		WHEN Age_1st_Vis >= 60 AND Age_1st_Vis <70 THEN '60-69'
		WHEN Age_1st_Vis >= 70 AND Age_1st_Vis <80 THEN '70-79'
		WHEN Age_1st_Vis >= 80  THEN '80+'
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

--	Gender
SELECT 
	GENDER, COUNT(DISTINCT PERSON_ID)
FROM
	#G8BD
GROUP BY Gender
ORDER BY Gender
;

--	Race
SELECT 
	Race, COUNT(DISTINCT PERSON_ID)
FROM
	#G8BD
GROUP BY Race
ORDER BY Race
;

--	Ethnicity
SELECT 
	Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
	#G8BD
GROUP BY Ethnicity
ORDER BY Ethnicity
;


/********************************  G_9  **********************************
	
	3. Number of patients from row 8 had eGFR <30 (the most recent)

	*All queries completed using OMOP data

*************************************************************************/

--	3.1		Create Lab SID DIM Table

DROP TABLE IF EXISTS #LabConceptDim_Creatinine; 

SELECT DISTINCT
		CONCEPT_ID, CONCEPT_NAME
	INTO 
		#LabConceptDim_Creatinine
	FROM 
		CDWWork.OMOPV5Dim.LabChemTest_CONCEPT
	WHERE 
			CONCEPT_NAME LIKE '%creatinine%'
		AND (CONCEPT_NAME LIKE '%Serum%'
				OR CONCEPT_NAME LIKE '%Blood%'
				OR CONCEPT_NAME LIKE '%Plasma%')
		AND CONCEPT_NAME NOT LIKE '%Ratio%'
		AND CONCEPT_NAME NOT LIKE '%URINE%'
		AND Unit_Mapped LIKE '%mg%dl%'
;

--	7 rows;		m:01s


SELECT * FROM #LabConceptDim_Creatinine


--	3.2		Get Patients who had the specified lab(s) 

DROP TABLE IF EXISTS #CohortMeasurement

SELECT DISTINCT
	COH.PERSON_ID
		,M.VALUE_AS_CONCEPT_ID
		,M.VALUE_AS_NUMBER
		,M.UNIT_CONCEPT_ID
		,M.MEASUREMENT_DATETIME
	INTO
		#CohortMeasurement
	FROM
		#G8 AS COH
		INNER JOIN
		CDWWork.OMOPV5.MEASUREMENT AS M
		ON COH.PERSON_ID = M.PERSON_ID
		INNER JOIN
		#LabConceptDim_Creatinine AS Dim
		ON M.MEASUREMENT_CONCEPT_ID = Dim.CONCEPT_ID
	;

--	59197688 rows;	5m:27s


--	3.3		Get Gender, DateofBirth.

DROP TABLE IF EXISTS #eGFR_Demo;

;WITH CTE AS(
	SELECT	    
			COH.Person_ID
			--,COH.LabChemResultValue
			,COH.VALUE_AS_NUMBER
			,COH.MEASUREMENT_DATETIME
			--,COH.LabChemCompleteDateTime
			,BirthDateTime
			,Gender
		FROM 
			#CohortMeasurement as COH
		INNER JOIN
			#G7 AS P
			ON	COH.PERSON_ID = P.PERSON_ID
)
SELECT DISTINCT
		Person_ID
		--,LabChemResultValue
		,VALUE_AS_NUMBER
		,MEASUREMENT_DATETIME
		--,LabChemCompleteDateTime
		,CAST(DATEDIFF(DAY, BirthDateTime, MEASUREMENT_DATETIME)/365.25 AS INT) AS Age
		--,DateofBirth
		,Gender
	INTO
		#eGFR_Demo
	FROM
		CTE
	WHERE	-- This WHERE statement removes possiblity of divide by zero errors.
			VALUE_AS_NUMBER > 0
		AND BirthDateTime < MEASUREMENT_DATETIME
		AND CAST(DATEDIFF(DAY, BirthDateTime,Cast(GetDate() AS DATE))/365.25 AS INT) > 17; -- Removes date of birth errors.

--	59059829 rows;	0m:47s


--	3.4		eGFR Calculation Using the CKD-EPI Equation (uses creatinine units of mg/dL)

DROP TABLE IF EXISTS #eGFR_Values;

SELECT DISTINCT
		COH.PERSON_ID
		,142
			* POWER(LEAST((VALUE_AS_NUMBER/(CASE WHEN Gender <> 'FEMALE' THEN 0.9 ELSE .7 END)), 1 ),(CASE WHEN Gender <> 'FEMALE' THEN  -0.302 ELSE -0.241 END)) 
			* POWER(GREATEST((VALUE_AS_NUMBER/(CASE WHEN Gender <> 'FEMALE' THEN 0.9 ELSE .7 END)), 1 ),-1.200)
			* POWER(0.9938, Age)
			* (CASE WHEN Gender <> 'FEMALE' THEN 1 ELSE 1.012 END) AS eGFR
		--,LabChemSpecimenDateTime
		--,'mL/min/1.73m2' as [Calculated eGFR Units] -- Uncomment if providing eGFR values
		,ROW_NUMBER() OVER(PARTITION BY COH.Person_ID ORDER BY MEASUREMENT_DATETIME DESC) AS RN  --add row number if you wish to get most recent eGFR	 
	INTO 
		#eGFR_Values
	FROM 
		#eGFR_Demo AS COH;

--	59059829 Rows;		01m:09s



--	3.5		Distinct Patients with specified eGFR score

DROP TABLE IF EXISTS #G9;

SELECT DISTINCT
		PERSON_ID
	INTO
		#G9
	FROM
		#eGFR_Values
	WHERE
			eGFR < 30
		AND RN = 1;		-- Use RN if looking for most recent eGFR.

--	171303 Rows;		00m:07s


--	3.6		Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS VINCI_Feasibility.MAY.OMOP_250522_G9;

SELECT DISTINCT
	PERSON_ID
INTO VINCI_Feasibility.MAY.OMOP_250522_G9
FROM #G9
;

SELECT COUNT(DISTINCT PERSON_ID) FROM VINCI_Feasibility.MAY.OMOP_250522_G9;

--	171303 DISTINCT patients;		00m:02s


--	3.5		Breakdowns

DROP TABLE IF EXISTS #G9BD;

SELECT DISTINCT
	COH.PERSON_ID,
	Age_1st_Vis,
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
--	2147771 rows;	00m:04s

--	Age
WITH Age AS (
SELECT DISTINCT
	PERSON_ID,
	CASE 
		WHEN Age_1st_Vis >= 18 AND Age_1st_Vis <40 THEN '18-39'
		WHEN Age_1st_Vis >= 40 AND Age_1st_Vis <50 THEN '40-49'
		WHEN Age_1st_Vis >= 50 AND Age_1st_Vis <60 THEN '50-59'
		WHEN Age_1st_Vis >= 60 AND Age_1st_Vis <70 THEN '60-69'
		WHEN Age_1st_Vis >= 70 AND Age_1st_Vis <80 THEN '70-79'
		WHEN Age_1st_Vis >= 80  THEN '80+'
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

--	Gender
SELECT 
	GENDER, COUNT(DISTINCT PERSON_ID)
FROM
	#G9BD
GROUP BY Gender
ORDER BY Gender
;

--	Race
SELECT 
	Race, COUNT(DISTINCT PERSON_ID)
FROM
	#G9BD
GROUP BY Race
ORDER BY Race
;

--	Ethnicity
SELECT 
	Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
	#G9BD
GROUP BY Ethnicity
ORDER BY Ethnicity
;


/********************************  G_10  **********************************
	
	4.  Number of patients from row 9 had dialysis (ICD or CPT codes)

	*All queries completed using OMOP data

*************************************************************************/

--	4.1		Look Up ICD Codes

SELECT DISTINCT
	ICD10Code,
	ICD10Description,
	DOMAIN_ID
FROM 
	CDWWork.OMOPV5Dim.ICD10_CONCEPT
WHERE
	ICD10Code LIKE 'Z99.2%'
	;

--	1 Rows;	00m:02s


--	4.2		Create ICD Dim Table

DROP TABLE IF EXISTS #Dim_ICD_Dia;

SELECT DISTINCT
	ICD10Code,
	ICD10Description,
	CONCEPT_ID,
	Source_Concept_ID,
	DOMAIN_ID
INTO
	#Dim_ICD_Dia
FROM 
	CDWWork.OMOPV5Dim.ICD10_CONCEPT
WHERE
	ICD10Code LIKE 'Z99.2%'
	;

--	1 Rows;	00m:01s


--	4.3		Identify Patients With Diagnosis

DROP TABLE IF EXISTS #ICD_Dia;

--	VistA
SELECT DISTINCT
	COH.PERSON_ID
INTO 
	#ICD_Dia
FROM
	#G9 AS COH
	INNER JOIN
	CDWWork.OMOPV5.CONDITION_OCCURRENCE AS C
		ON C.PERSON_ID = COH.PERSON_ID
	INNER JOIN
	#Dim_ICD_Dia AS D
		ON C.CONDITION_CONCEPT_ID = D.CONCEPT_ID
WHERE
	(CONDITION_END_DATE >= CAST(DATEADD(YEAR, -1, GETDATE()) AS date) OR CONDITION_END_DATE IS NULL) -- Start Date
	AND CONDITION_START_DATE < CAST(GETDATE() AS date) -- End Date
	AND CONDITION_START_DATE >= CAST('10/01/1999' AS date) -- Start of EHR
	
--	0 Rows;	00m:09s


--	4.4		Look Up CPT Codes

SELECT DISTINCT
	CPTCode,
	CPTDescription,
	DOMAIN_ID
FROM 
	CDWWork.OMOPV5Dim.CPT_CONCEPT
WHERE
	CPTCode IN ('90935', '90936', '90937')
	;

--	2 Rows;	00m:02s


--	4.5		Create ICD Dim Table

DROP TABLE IF EXISTS #Dim_CPT;

SELECT DISTINCT
	CPTCode,
	CPTDescription,
	CONCEPT_ID,
	Source_Concept_ID,
	DOMAIN_ID
INTO
	#Dim_CPT
FROM 
	CDWWork.OMOPV5Dim.CPT_CONCEPT
WHERE
	CPTCode IN ('90935', '90936', '90937')
	;

--	2 Rows;	00m:01s


--	4.6		Identify Patients With Procedure

DROP TABLE IF EXISTS #CPT_Dia;

--	VistA
SELECT DISTINCT
	COH.PERSON_ID
INTO 
	#CPT_Dia
FROM
	#G9 AS COH
	INNER JOIN
	CDWWork.OMOPV5.PROCEDURE_OCCURRENCE AS P
		ON P.PERSON_ID = COH.PERSON_ID
	INNER JOIN
	#Dim_CPT AS D
		ON P.PROCEDURE_CONCEPT_ID = D.CONCEPT_ID
WHERE
	PROCEDURE_DATETIME >= CAST(DATEADD(YEAR, -1, GETDATE()) AS date) -- Start Date
	AND PROCEDURE_DATETIME < CAST(GETDATE() AS date) -- End Date
	AND PROCEDURE_DATETIME >= CAST('10/01/1999' AS date) -- Start of EHR
	
--	7795 Rows;	00m:01s


--	4.7		Combine ICD and CPT
-- No Results from ICD
DROP TABLE IF EXISTS #G10

SELECT DISTINCT
		PERSON_ID
	INTO
		#G10
	FROM
		#CPT_Dia


--	4.8		Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS VINCI_Feasibility.MAY.OMOP_250522_G10;

SELECT DISTINCT
	PERSON_ID
INTO VINCI_Feasibility.MAY.OMOP_250522_G10
FROM #G10
;

SELECT COUNT(DISTINCT PERSON_ID) FROM VINCI_Feasibility.MAY.OMOP_250522_G10;

--	171303 DISTINCT patients;		00m:02s


--	4.9		Breakdowns

DROP TABLE IF EXISTS #G10BD;

SELECT DISTINCT
	COH.PERSON_ID,
	Age_1st_Vis,
	Gender,
	Race,
	Ethnicity
INTO
	#G10BD
FROM
	#G7 AS COH
	INNER JOIN
	#G10 AS G
		ON COH.PERSON_ID = G.PERSON_ID
;
--	2147771 rows;	00m:04s

--	Age
WITH Age AS (
SELECT DISTINCT
	PERSON_ID,
	CASE 
		WHEN Age_1st_Vis >= 18 AND Age_1st_Vis <40 THEN '18-39'
		WHEN Age_1st_Vis >= 40 AND Age_1st_Vis <50 THEN '40-49'
		WHEN Age_1st_Vis >= 50 AND Age_1st_Vis <60 THEN '50-59'
		WHEN Age_1st_Vis >= 60 AND Age_1st_Vis <70 THEN '60-69'
		WHEN Age_1st_Vis >= 70 AND Age_1st_Vis <80 THEN '70-79'
		WHEN Age_1st_Vis >= 80  THEN '80+'
		ELSE 'Other'
	END AS Age_Cat
FROM
	#G10BD
)
SELECT 
	Age_Cat, COUNT(DISTINCT PERSON_ID)
FROM 
	Age
GROUP BY Age_Cat
ORDER BY Age_Cat
;

--	Gender
SELECT 
	GENDER, COUNT(DISTINCT PERSON_ID)
FROM
	#G10BD
GROUP BY Gender
ORDER BY Gender
;

--	Race
SELECT 
	Race, COUNT(DISTINCT PERSON_ID)
FROM
	#G10BD
GROUP BY Race
ORDER BY Race
;

--	Ethnicity
SELECT 
	Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
	#G10BD
GROUP BY Ethnicity
ORDER BY Ethnicity
;
/****************************************************************/