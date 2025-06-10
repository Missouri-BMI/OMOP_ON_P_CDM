/********************************  G_7  **********************************

	1. Number of  Veterans seen nationwide outpatient or inpatient or in
	non-VA community care  in period of time

	*All queries completed using OMOP data

*************************************************************************/

--	1.1		Identify Patients with Visit to VA in the last 5 Years

DROP TABLE IF EXISTS Visits;

--VistA
create temporary table visits as
SELECT
	PERSON_ID,
	VISIT_END_DATE  AS VISIT_DATE
FROM ATLAS_MU_PROD.CDM.VISIT_OCCURRENCE
WHERE
	(VISIT_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date) OR VISIT_END_DATE IS NULL) -- Start Date
	AND VISIT_START_DATE < CAST(GETDATE() AS date) -- End Date
	AND VISIT_START_DATE >= CAST('10/01/1999' AS date); -- Start of EHR


--	1.2		Exclude Non-Veterans and Get Demographics

DROP TABLE IF EXISTS G7;


create temporary table G7 as
WITH Visit AS (
SELECT PERSON_ID, MIN(VISIT_DATE) AS First_Vis
FROM Visits
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
	ATLAS_MU_PROD.CDM.PERSON AS P
	ON V.PERSON_ID = P.PERSON_ID
)
SELECT DISTINCT
	PERSON_ID,
	First_Vis,
	BirthDateTime,
	Age_1st_Vis,
	G.CONCEPT_NAME AS Gender,
	R.CONCEPT_NAME AS Race,
	E.CONCEPT_NAME AS Ethnicity
FROM Demo AS D
	INNER JOIN ATLAS_MU_PROD.CDM.CONCEPT AS G
	ON D.Gender = G.CONCEPT_ID
	INNER JOIN ATLAS_MU_PROD.CDM.CONCEPT AS R
	ON D.Race = R.CONCEPT_ID
	INNER JOIN ATLAS_MU_PROD.CDM.CONCEPT AS E
	ON D.Ethnicity = E.CONCEPT_ID
	;



--	1.3		Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS feas1;

create temporary table FEAS1 AS
SELECT DISTINCT
	PERSON_ID
FROM G7;

SELECT COUNT(DISTINCT PERSON_ID) FROM feas1;



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
	G7
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
	G7
GROUP BY Gender
ORDER BY Gender
;

--	Race
SELECT
	Race, COUNT(DISTINCT PERSON_ID)
FROM
	G7
GROUP BY Race
ORDER BY Race
;

--	Ethnicity
SELECT
	Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
	G7
GROUP BY Ethnicity
ORDER BY Ethnicity;



/********************************  G_8  **********************************

	2. Number of patients from row 7 seen with  Chronic kidney disease
	(CKD) diagnosis  (ICD codes)

	*All queries completed using OMOP data

*************************************************************************/


--	2.1		Look Up ICD Codes


DROP TABLE IF EXISTS kidney_codes;
CREATE TEMPORARY TABLE kidney_codes as
SELECT concept_id, concept_name, concept_code, from ATLAS_MU_PROD.CDM.CONCEPT
WHERE vocabulary_id='ICD10CM' and (CONCEPT_CODE  LIKE 'N18.2%' OR CONCEPT_CODE LIKE 'N18.3%' OR CONCEPT_CODE LIKE 'N18.30%'
	OR CONCEPT_CODE LIKE 'N18.31%' OR CONCEPT_CODE LIKE 'N18.32%' OR CONCEPT_CODE LIKE 'N18.4%'
	OR CONCEPT_CODE LIKE 'N18.5%' OR CONCEPT_CODE LIKE 'N18.6%' OR CONCEPT_CODE LIKE 'N18.9%');
select * from kidney_codes order by CONCEPT_CODE;

--todo can it be optimized
drop table if exists kidney_diagnoses;
create temporary table kidney_diagnoses as
select c.person_id,CONDITION_END_DATE,CONDITION_START_DATE from kidney_codes as k
inner join ATLAS_MU_PROD.CDM.CONDITION_OCCURRENCE as c
ON C.CONDITION_SOURCE_CONCEPT_ID = k.CONCEPT_ID;
select * from kidney_diagnoses;

--	2.3		Identify Patients With Diagnosis


--	VistA
DROP TABLE IF EXISTS G8;
create temporary table G8 as
SELECT DISTINCT
	G7.PERSON_ID
FROM
	G7
	INNER JOIN
    kidney_diagnoses AS k
		ON k.PERSON_ID = G7.PERSON_ID
WHERE
	(CONDITION_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date) OR CONDITION_END_DATE IS NULL) -- Start Date
	AND CONDITION_START_DATE < CAST(GETDATE() AS date) -- End Date
	AND CONDITION_START_DATE >= CAST('10/01/1999' AS date); -- Start of EHR
select * from g8;
--	1225236 Rows;	00m:09s



--	2.4		Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS feas2;

create temporary table feas2 as
SELECT DISTINCT PERSON_ID FROM G8;

SELECT COUNT(DISTINCT PERSON_ID) FROM feas2;

--	1225236 DISTINCT patients;		00m:02s


--	2.5		Breakdowns

DROP TABLE IF EXISTS G8BD;

create temporary table G8BD as
SELECT DISTINCT
	G7.PERSON_ID,
	Age_1st_Vis,
	Gender,
	Race,
	Ethnicity
FROM G7
INNER JOIN G8
ON G7.PERSON_ID = G8.PERSON_ID;
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
	G8BD
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
	G8BD
GROUP BY Gender
ORDER BY Gender
;

--	Race
SELECT
	Race, COUNT(DISTINCT PERSON_ID)
FROM
	G8BD
GROUP BY Race
ORDER BY Race
;

--	Ethnicity
SELECT
	Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM G8BD
GROUP BY Ethnicity
ORDER BY Ethnicity
;


/********************************  G_9  **********************************

	3. Number of patients from row 8 had eGFR <30 (the most recent)

	*All queries completed using OMOP data

*************************************************************************/
--	3.1		Create Lab SID DIM Table

DROP TABLE IF EXISTS LabConceptDim_Creatinine;
create temporary table LabConceptDim_Creatinine as
SELECT DISTINCT C.*
FROM ATLAS_MU_PROD.CDM.concept as C
	WHERE
			lower(C.CONCEPT_NAME) LIKE '%creatinine%'
		AND (lower(C.CONCEPT_NAME) LIKE '%serum%'
				OR lower(C.CONCEPT_NAME) LIKE '%blood%'
				OR lower(C.CONCEPT_NAME) LIKE '%plasma%')
		AND lower(C.CONCEPT_NAME) NOT LIKE '%ratio%'
		AND lower(C.CONCEPT_NAME) NOT LIKE '%urine%'
        and C.DOMAIN_ID='Measurement';
--		AND m.concept_code LIKE '%mg%dl%';


--	3.2		Get Patients who had the specified lab(s)

DROP TABLE IF EXISTS CohortMeasurement;

create temporary table CohortMeasurement as
SELECT DISTINCT
	G8.PERSON_ID
		,M.VALUE_AS_CONCEPT_ID
		,M.VALUE_AS_NUMBER
		,M.UNIT_CONCEPT_ID
		,M.MEASUREMENT_DATETIME
FROM
		G8
		INNER JOIN
		ATLAS_MU_PROD.CDM.measurement AS M
		ON G8.PERSON_ID = M.PERSON_ID
		INNER JOIN
		LabConceptDim_Creatinine AS Dim
		ON M.MEASUREMENT_CONCEPT_ID = Dim.CONCEPT_ID;


--	59197688 rows;	5m:27s


--	3.3		Get Gender, DateofBirth.

DROP TABLE IF EXISTS eGFR_Demo;
create temporary table eGFR_DEMO as
WITH CTE AS(
	SELECT
			COH.Person_ID
			--,COH.LabChemResultValue
			,COH.VALUE_AS_NUMBER
			,COH.MEASUREMENT_DATETIME
			--,COH.LabChemCompleteDateTime
			,BirthDateTime
			,Gender
		FROM
			CohortMeasurement as COH
		INNER JOIN
			G7 AS P
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
	FROM
		CTE
	WHERE	-- This WHERE statement removes possiblity of divide by zero errors.
			VALUE_AS_NUMBER > 0
		AND BirthDateTime < MEASUREMENT_DATETIME
		AND CAST(DATEDIFF(DAY, BirthDateTime,Cast(GetDate() AS DATE))/365.25 AS INT) > 17; -- Removes date of birth errors.
select * from egfr_demo;


--	3.4		eGFR Calculation Using the CKD-EPI Equation (uses creatinine units of mg/dL)

DROP TABLE IF EXISTS eGFR_Values;
create temporary table eGFR_Values as
SELECT DISTINCT
		eGFR_Demo.PERSON_ID
		,142
			* POWER(LEAST((VALUE_AS_NUMBER/(CASE WHEN Gender <> 'FEMALE' THEN 0.9 ELSE .7 END)), 1 ),(CASE WHEN Gender <> 'FEMALE' THEN  -0.302 ELSE -0.241 END))
			* POWER(GREATEST((VALUE_AS_NUMBER/(CASE WHEN Gender <> 'FEMALE' THEN 0.9 ELSE .7 END)), 1 ),-1.200)
			* POWER(0.9938, Age)
			* (CASE WHEN Gender <> 'FEMALE' THEN 1 ELSE 1.012 END) AS eGFR
		--,LabChemSpecimenDateTime
		--,'mL/min/1.73m2' as [Calculated eGFR Units] -- Uncomment if providing eGFR values
		,ROW_NUMBER() OVER(PARTITION BY eGFR_Demo.Person_ID ORDER BY MEASUREMENT_DATETIME DESC) AS RN  --add row number if you wish to get most recent eGFR
        FROM eGFR_Demo;


--	59059829 Rows;		01m:09s



--	3.5		Distinct Patients with specified eGFR score

DROP TABLE IF EXISTS G9;
create temporary table G9 as
SELECT DISTINCT PERSON_ID
	FROM eGFR_Values
	WHERE eGFR < 30
	AND RN = 1;		-- Use RN if looking for most recent eGFR.
--	171303 Rows;		00m:07s


--	3.6		Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS feas3;

create temporary table feas3 as
SELECT DISTINCT
	PERSON_ID
FROM G9;

SELECT COUNT(DISTINCT PERSON_ID) FROM feas3;

--	171303 DISTINCT patients;		00m:02s


--	3.5		Breakdowns

DROP TABLE IF EXISTS G9BD;

create temp table g9bd as
SELECT DISTINCT
	COH.PERSON_ID,
	Age_1st_Vis,
	Gender,
	Race,
	Ethnicity
FROM
	G7 AS COH
	INNER JOIN
	G9 AS G
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
	G9BD
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
	G9BD
GROUP BY Gender
ORDER BY Gender
;

--	Race
SELECT
	Race, COUNT(DISTINCT PERSON_ID)
FROM
	G9BD
GROUP BY Race
ORDER BY Race
;

--	Ethnicity
SELECT
	Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
	G9BD
GROUP BY Ethnicity
ORDER BY Ethnicity
;


/********************************  G_10  **********************************

	4.  Number of patients from row 9 had dialysis (ICD or CPT codes)

	*All queries completed using OMOP data

*************************************************************************/

--	4.1		Look Up ICD Codes




-- SELECT DISTINCT
-- 	ICD10Code,
-- 	ICD10Description,
-- 	DOMAIN_ID
-- FROM
-- 	CDWWork.OMOPV5Dim.ICD10_CONCEPT
-- WHERE
-- 	ICD10Code LIKE 'Z99.2%'
-- 	;

--	1 Rows;	00m:02s


--	4.2		Create ICD Dim Table

drop table if exists DIM_ICD_DIA;
create temporary table Dim_ICD_Dia as
select * from ATLAS_MU_PROD.CDM.concept
where  concept_code LIKE 'Z99.2%'
and vocabulary_id like 'ICD10%';
select * from dim_icd_dia;
--	1 Rows;	00m:01s


--	4.3		Identify Patients With Diagnosis

DROP TABLE IF EXISTS ICD_Dia;

--	VistA
create temp table ICD_Dia as
SELECT DISTINCT
	COH.PERSON_ID
FROM
	G9 AS COH
	INNER JOIN
	ATLAS_MU_PROD.CDM.CONDITION_OCCURRENCE AS C
		ON C.PERSON_ID = COH.PERSON_ID
	INNER JOIN
	Dim_ICD_Dia AS D
		ON C.CONDITION_CONCEPT_ID = D.CONCEPT_ID
WHERE
	(CONDITION_END_DATE >= CAST(DATEADD(YEAR, -1, GETDATE()) AS date) OR CONDITION_END_DATE IS NULL) -- Start Date
	AND CONDITION_START_DATE < CAST(GETDATE() AS date) -- End Date
	AND CONDITION_START_DATE >= CAST('10/01/1999' AS date);-- Start of EHR

select * from ICD_Dia;
--	0 Rows;	00m:09s


--	4.4		Look Up CPT Codes
-- select distinct concept_class_id from ATLAS_MU_PROD.CDM.concept where lower(concept_class_id) like '%cpt%';

SELECT DISTINCT
	*
FROM
	 ATLAS_MU_PROD.CDM.concept
WHERE
    vocabulary_id like 'CPT4%'
    and
	concept_code IN ('90935' , '90936', '90937');

--	2 Rows;	00m:02s


--	4.5		Create ICD Dim Table

DROP TABLE IF EXISTS Dim_CPT;

create temp table Dim_CPT as
SELECT DISTINCT
	*
FROM
	 ATLAS_MU_PROD.CDM.concept
WHERE
    vocabulary_id like 'CPT4%'
    and
	concept_code IN ('90935' , '90936', '90937');

--	2 Rows;	00m:01s


--	4.6		Identify Patients With Procedure

DROP TABLE IF EXISTS CPT_Dia;

--	VistA
create temp table cpt_dia as
SELECT DISTINCT
	COH.PERSON_ID
FROM
	G9 AS COH
	INNER JOIN
	ATLAS_MU_PROD.CDM.PROCEDURE_OCCURRENCE AS P
		ON P.PERSON_ID = COH.PERSON_ID
	INNER JOIN
	Dim_CPT AS D
		ON P.PROCEDURE_CONCEPT_ID = D.CONCEPT_ID
WHERE
	PROCEDURE_DATETIME >= CAST(DATEADD(YEAR, -1, GETDATE()) AS date) -- Start Date
	AND PROCEDURE_DATETIME < CAST(GETDATE() AS date) -- End Date
	AND PROCEDURE_DATETIME >= CAST('10/01/1999' AS date); -- Start of EHR

select * from cpt_dia;
--	7795 Rows;	00m:01s


--	4.7		Combine ICD and CPT
-- No Results from ICD
DROP TABLE IF EXISTS G10;

create temp table g10 as
SELECT DISTINCT PERSON_ID
FROM CPT_Dia
union
select distinct person_id
from icd_dia;



--	4.8		Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts

DROP TABLE IF EXISTS feas4;

create temp table feas4 as
SELECT DISTINCT
	PERSON_ID
FROM G10
;

SELECT COUNT(DISTINCT PERSON_ID) FROM feas4;

--	171303 DISTINCT patients;		00m:02s


--	4.9		Breakdowns

DROP TABLE IF EXISTS G10BD;

create temp table g10bd as
SELECT DISTINCT
	COH.PERSON_ID,
	Age_1st_Vis,
	Gender,
	Race,
	Ethnicity
FROM
	G7 AS COH
	INNER JOIN
	G10 AS G
		ON COH.PERSON_ID = G.PERSON_ID;
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
	G10BD
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
	G10BD
GROUP BY Gender
ORDER BY Gender
;

--	Race
SELECT
	Race, COUNT(DISTINCT PERSON_ID)
FROM
	G10BD
GROUP BY Race
ORDER BY Race
;

--	Ethnicity
SELECT
	Ethnicity, COUNT(DISTINCT PERSON_ID)
FROM
	G10BD
GROUP BY Ethnicity
ORDER BY Ethnicity
;
/****************************************************************/