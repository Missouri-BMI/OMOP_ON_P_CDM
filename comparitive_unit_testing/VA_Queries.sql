
/******************************** G_7 **********************************
            1. Number of  patients seen in outpatient or inpatient
            in period of time (last 5 years)

            *All queries completed using PCOREnet data
PCORNET_CDM.CDM.
*************************************************************************/
-- 1.1 Identify Patients with Visit in the last 5 Years
DROP TABLE IF EXISTS Visits;
CREATE TEMPORARY TABLE Visits as
SELECT PERSON_ID, VISIT_END_DATE AS VISIT_DATE --This is just VINCI Services way to grab Visit_Date, could also use VISIT_START_DATE
FROM OMOP_CDM.CDM.VISIT_OCCURRENCE
WHERE (VISIT_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date)
OR VISIT_END_DATE IS NULL) -- Start Date
AND VISIT_START_DATE < CAST(GETDATE() AS date) -- End Date
AND VISIT_START_DATE >= CAST('10/01/1999' AS date); -- Start of EHR TODO: is this needed?

-- 1.2 Get Demographics
DROP TABLE IF EXISTS G7;
CREATE TEMPORARY TABLE G7 as
WITH Visit AS (SELECT PERSON_ID, MIN(VISIT_DATE) AS First_Vis
FROM Visits GROUP BY PERSON_ID),
Demo AS (SELECT DISTINCT V.PERSON_ID,First_Vis,BIRTH_DATETIME AS BirthDateTime,
GENDER_CONCEPT_ID as Gender,RACE_CONCEPT_ID AS Race,ETHNICITY_CONCEPT_ID AS Ethnicity
FROM Visit AS V
INNER JOIN OMOP_CDM.CDM.PERSON ON V.PERSON_ID = OMOP_CDM.CDM.PERSON.PERSON_ID)
SELECT DISTINCT PERSON_ID, First_Vis, BirthDateTime, G.CONCEPT_NAME as Gender, R.CONCEPT_NAME as Race, E.CONCEPT_NAME as Ethnicity
FROM Demo
INNER JOIN OMOP_CDM.CDM.CONCEPT as G on Demo.Gender = G.CONCEPT_ID
INNER JOIN OMOP_CDM.CDM.CONCEPT as R on Demo.Race = R.CONCEPT_ID
INNER JOIN OMOP_CDM.CDM.CONCEPT as E on Demo.Ethnicity = E.CONCEPT_ID;

-- 1.3 Save Row Cohort in FEAS and Get Distinct Patient Counts
DROP TABLE IF EXISTS FEAS;
CREATE TEMPORARY TABLE FEAS as
SELECT DISTINCT PERSON_ID FROM G7;
SELECT COUNT(DISTINCT PERSON_ID) FROM FEAS;
-- 1.4 Breakdowns
-- Gender
SELECT Gender, COUNT(DISTINCT PERSON_ID) FROM G7 GROUP BY Gender ORDER BY Gender;
SELECT Race, COUNT(DISTINCT PERSON_ID) FROM G7 GROUP BY Race ORDER BY Race;
SELECT Ethnicity, COUNT(DISTINCT PERSON_ID) FROM G7 GROUP BY Ethnicity ORDER BY Ethnicity;
/******************************** G_8 *********************************
            2. Number of patients from row 7 seen with type 2 diabetes diagnosis
            (ICD codes)


*************************************************************************/
-- 2.2 Create ICD Dim Table

DROP TABLE IF EXISTS Dim_ICD;
CREATE TEMPORARY TABLE Dim_ICD as
SELECT DISTINCT
PERSON_ID,
CONDITION_START_DATE,
CONDITION_END_DATE,
CONDITION_CONCEPT_ID,
CONDITION_SOURCE_VALUE
FROM
OMOP_CDM.CDM.CONDITION_OCCURRENCE
WHERE
(CONDITION_SOURCE_VALUE LIKE 'dx_icd_type:10|E11.%')
AND (CONDITION_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date) OR CONDITION_END_DATE IS NULL) -- Start Date
AND CONDITION_START_DATE < CAST(GETDATE() AS date) -- End Date kind of pointless
AND CONDITION_START_DATE >= CAST('10/01/1999' AS date);--TODO: icd type 9?


-- 2.3 Identify Patients With Diagnosis
DROP TABLE IF EXISTS G8;
CREATE TEMPORARY TABLE G8 as
SELECT DISTINCT G7.PERSON_ID, Race, Gender, Ethnicity,First_Vis,BIRTHDATETIME  from G7
INNER JOIN DIM_ICD as C
ON C.PERSON_ID = G7.PERSON_ID;

--TODO: SHOULD first diagnosis date be used as substitute for CONDITION START DATE?
-- AND CONDITION_START_DATE >= CAST('10/01/1999' AS date) -- Start of EHR

-- 2.4 Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts
DROP TABLE IF EXISTS FEAS1;
CREATE TEMPORARY TABLE FEAS1 as
SELECT DISTINCT PERSON_ID FROM G8;
SELECT COUNT(DISTINCT PERSON_ID) FROM FEAS1;

-- 2.5 Breakdowns
DROP TABLE IF EXISTS G8BD;
--Calculate age for all rows and add it as a column
CREATE TEMPORARY TABLE G8BD as
SELECT DISTINCT G8.PERSON_ID, G8.BIRTHDATETIME, G8.First_Vis, CAST(DATEDIFF(DAY,G8.BirthDateTime, g8.First_Vis)/365.25 AS INT)
AS Age_1st_Vis, G8.GEnder, g8.Race, G8.Ethnicity FROM G8;
-- null in age first vis? what to do

-- Age
WITH Age AS (SELECT DISTINCT PERSON_ID,
CASE
WHEN Age_1st_Vis is null THEN 'Other'
WHEN Age_1st_Vis >= 18 AND Age_1st_Vis <40 THEN '18-39'
WHEN Age_1st_Vis >= 40 AND Age_1st_Vis <50 THEN '40-49'
WHEN Age_1st_Vis >= 50 AND Age_1st_Vis <60 THEN '50-59'
WHEN Age_1st_Vis >= 60 AND Age_1st_Vis <70 THEN '60-69'
WHEN Age_1st_Vis >= 70 AND Age_1st_Vis <80 THEN '70-79'
WHEN Age_1st_Vis >= 80 THEN '80+' ELSE 'Other'
END
AS Age_Cat FROM G8BD)
SELECT Age_Cat, COUNT(DISTINCT PERSON_ID)
FROM Age GROUP BY Age_Cat ORDER BY Age_Cat;

SELECT Gender, COUNT(DISTINCT PERSON_ID) FROM G8 GROUP BY Gender ORDER BY Gender;
SELECT Race, COUNT(DISTINCT PERSON_ID) FROM G8 GROUP BY Race ORDER BY Race;
SELECT Ethnicity, COUNT(DISTINCT PERSON_ID) FROM G8 GROUP BY Ethnicity ORDER BY Ethnicity;
/******************************** G_9 **********************************
            3. Number of patients from row 8 had prescription for metformin


*************************************************************************/
-- 3.1 Look Up Drugs/-- 3.2 Create Drug Dim Table for users over past 5 years
DROP TABLE if exists metforminCodes;
CREATE TEMPORARY TABLE metforminCodes as SELECT CONCEPT_ID, CONCEPT_NAME, DOMAIN_ID from OMOP_CDM.CDM.CONCEPT
where CONCEPT_NAME like '%metformin%' or CONCEPT_NAME like '%Metformin%';
select * from metforminCodes where domain_id != 'Drug';


-- 3.3 Identify Patients with diabetes on metformin
DROP TABLE IF EXISTS G9;
CREATE TEMPORARY TABLE G9 as
SELECT DISTINCT
G8.PERSON_ID, Gender, Race,Ethnicity, BIRTHDATETIME, First_Vis, M.CONCEPT_NAME  FROM G8
INNER JOIN
OMOP_CDM.CDM.DRUG_EXPOSURE
ON G8.PERSON_ID = OMOP_CDM.CDM.DRUG_EXPOSURE.PERSON_ID
INNER JOIN metforminCodes AS M
ON OMOP_CDM.CDM.DRUG_EXPOSURE.DRUG_CONCEPT_ID = M.CONCEPT_ID
WHERE
(OMOP_CDM.CDM.DRUG_EXPOSURE.DRUG_EXPOSURE_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date) OR OMOP_CDM.CDM.DRUG_EXPOSURE.DRUG_EXPOSURE_END_DATE IS NULL) -- Start Date
AND OMOP_CDM.CDM.DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE < CAST(GETDATE() AS date) -- End Date
AND OMOP_CDM.CDM.DRUG_EXPOSURE.DRUG_EXPOSURE_START_DATE >= CAST('10/01/1999' AS date); -- Start of EHR
select * from G9 order by First_Vis asc;

-- 3.4 Save Row Cohort in FEAS2 and Get Distinct Patient Counts
DROP TABLE IF EXISTS FEAS2;
CREATE TEMPORARY TABLE FEAS2 as
SELECT DISTINCT PERSON_ID FROM G9;
SELECT COUNT(DISTINCT PERSON_ID) FROM FEAS2;

-- 3.5 Breakdowns
-- this table exists for holding age
DROP TABLE IF EXISTS G9BD;
--Calculate age for all rows and add it as a column
CREATE TEMPORARY TABLE G9BD as
SELECT DISTINCT G9.PERSON_ID, G9.BIRTHDATETIME, G9.First_Vis, CAST(DATEDIFF(DAY,G9.BirthDateTime, g9.First_Vis)/365.25 AS INT)
AS Age_1st_Vis, G9.GENDER, g9.Race, G9.Ethnicity FROM G9;
-- null in age first vis? what to do

-- Age
WITH Age AS (SELECT DISTINCT PERSON_ID,
CASE
WHEN Age_1st_Vis is null THEN 'Other'
WHEN Age_1st_Vis >= 18 AND Age_1st_Vis <40 THEN '18-39'
WHEN Age_1st_Vis >= 40 AND Age_1st_Vis <50 THEN '40-49'
WHEN Age_1st_Vis >= 50 AND Age_1st_Vis <60 THEN '50-59'
WHEN Age_1st_Vis >= 60 AND Age_1st_Vis <70 THEN '60-69'
WHEN Age_1st_Vis >= 70 AND Age_1st_Vis <80 THEN '70-79'
WHEN Age_1st_Vis >= 80 THEN '80+' ELSE 'Other'
END
AS Age_Cat FROM G9BD)
SELECT Age_Cat, COUNT(DISTINCT PERSON_ID)
FROM Age GROUP BY Age_Cat ORDER BY Age_Cat;

SELECT Gender, COUNT(DISTINCT PERSON_ID) FROM G9 GROUP BY Gender ORDER BY Gender;
SELECT Race, COUNT(DISTINCT PERSON_ID) FROM G9 GROUP BY Race ORDER BY Race;
SELECT Ethnicity, COUNT(DISTINCT PERSON_ID) FROM G9 GROUP BY Ethnicity ORDER BY Ethnicity;
/****************************************************************/
