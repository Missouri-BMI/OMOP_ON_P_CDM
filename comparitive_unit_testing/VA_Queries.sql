
/******************************** G_7 **********************************
            1. Number of  patients seen in outpatient or inpatient
            in period of time (last 5 years)

            *All queries completed using PCOREnet data
PCORNET_CDM.CDM.
*************************************************************************/
-- 1.1 Identify Patients with Visit in the last 5 Years
DROP TABLE IF EXISTS Visits;
CREATE TEMPORARY TABLE Visits as
SELECT PATID, DISCHARGE_DATE AS VISIT_DATE --This is just VINCI Services way to grab Visit_Date, could also use VISIT_START_DATE
FROM PCORNET_CDM.CDM.ENCOUNTER
WHERE (DISCHARGE_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date)
OR DISCHARGE_DATE IS NULL) -- Start Date
AND ADMIT_DATE < CAST(GETDATE() AS date) -- End Date
AND ADMIT_DATE >= CAST('10/01/1999' AS date); -- Start of EHR TODO: is this needed?

-- 1.2 Get Demographics
DROP TABLE IF EXISTS G7;
CREATE TEMPORARY TABLE G7 as
WITH Visit AS (SELECT PATID, MIN(VISIT_DATE) AS First_Vis
FROM Visits GROUP BY PATID),
Demo AS (SELECT DISTINCT V.PATID,First_Vis,BIRTH_DATE AS BirthDateTime,
SEX,RACE AS Race,Hispanic AS Ethnicity
FROM Visit AS V
INNER JOIN PCORNET_CDM.CDM.DEMOGRAPHIC ON V.PATID = PCORNET_CDM.CDM.DEMOGRAPHIC.PATID)
SELECT DISTINCT PATID, First_Vis, BirthDateTime, SEX, Race, Ethnicity
FROM Demo;
-- 1.3 Save Row Cohort in FEAS and Get Distinct Patient Counts
DROP TABLE IF EXISTS FEAS;
CREATE TEMPORARY TABLE FEAS as
SELECT DISTINCT PATID FROM G7;
SELECT COUNT(DISTINCT PATID) FROM FEAS;
-- 1.4 Breakdowns
-- Gender
SELECT SEX, COUNT(DISTINCT PATID) FROM G7 GROUP BY SEX ORDER BY SEX;
SELECT Race, COUNT(DISTINCT PATID) FROM G7 GROUP BY Race ORDER BY Race;
SELECT Ethnicity, COUNT(DISTINCT PATID) FROM G7 GROUP BY Ethnicity ORDER BY Ethnicity;
/******************************** G_8 *********************************
            2. Number of patients from row 7 seen with type 2 diabetes diagnosis
            (ICD codes)


*************************************************************************/
-- 2.2 Create ICD Dim Table
DROP TABLE IF EXISTS Dim_ICD;
CREATE TEMPORARY TABLE Dim_ICD as
SELECT DISTINCT PATID, DX, ADMIT_DATE FROM PCORNET_CDM.CDM.DIAGNOSIS WHERE DX LIKE 'E11.%';

DROP TABLE IF EXISTS TYPETWOPATIENTS;
CREATE TEMPORARY TABLE TYPETWOPATIENTS as
SELECT DISTINCT PATID FROM DIM_ICD;

-- 2.3 Identify Patients With Diagnosis
DROP TABLE IF EXISTS G8;
CREATE TEMPORARY TABLE G8 as
SELECT DISTINCT G7.PATID, RACE, SEX, Ethnicity, BIRTHDATETIME, FIRST_VIS FROM G7
INNER JOIN TYPETWOPATIENTS AS C ON C.PATID = G7.PATID;
--TODO: SHOULD first diagnosis date be used as substitute for CONDITION START DATE?
-- AND CONDITION_START_DATE >= CAST('10/01/1999' AS date) -- Start of EHR
--Note that our date has no end or start date of a diagnosis, just an admit date. so we dont follow 1:1 the
-- process used by VA

-- 2.4 Save Row Cohort in VINCI_Feasibility and Get Distinct Patient Counts
DROP TABLE IF EXISTS FEAS1;
CREATE TEMPORARY TABLE FEAS1 as
SELECT DISTINCT PATID FROM G8;
SELECT COUNT(DISTINCT PATID) FROM FEAS1;

-- 2.5 Breakdowns
DROP TABLE IF EXISTS G8BD;
--Calculate age for all rows and add it as a column
CREATE TEMPORARY TABLE G8BD as
SELECT DISTINCT G8.PATID, G8.BIRTHDATETIME, G8.First_Vis, CAST(DATEDIFF(DAY,G8.BirthDateTime, g8.First_Vis)/365.25 AS INT)
AS Age_1st_Vis, G8.SEX, g8.Race, G8.Ethnicity FROM G8;
-- null in age first vis? what to do

-- Age
WITH Age AS (SELECT DISTINCT PATID,
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
SELECT Age_Cat, COUNT(DISTINCT PATID)
FROM Age GROUP BY Age_Cat ORDER BY Age_Cat;

SELECT SEX, COUNT(DISTINCT PATID) FROM G8 GROUP BY SEX ORDER BY SEX;
SELECT Race, COUNT(DISTINCT PATID) FROM G8 GROUP BY Race ORDER BY Race;
SELECT Ethnicity, COUNT(DISTINCT PATID) FROM G8 GROUP BY Ethnicity ORDER BY Ethnicity;
/******************************** G_9 **********************************
            3. Number of patients from row 8 had prescription for metformin


*************************************************************************/
-- 3.1 Look Up Drugs/-- 3.2 Create Drug Dim Table for users over past 5 years

DROP TABLE if exists metformin;
CREATE TEMPORARY TABLE metformin as SELECT PATID, RAW_RX_MED_NAME, RX_START_DATE, RX_END_DATE from PCORNET_CDM.CDM.prescribing
where RAW_RX_MED_NAME like '%metformin%' or RAW_RX_MED_NAME like '%Metformin%';

DROP TABLE if exists metformin_users;
CREATE TEMPORARY TABLE metformin_users as
select distinct PATID from metformin;
select * from metformin_users;

drop table if exists metformin5years;
Create TEMPORARY table metformin5years as
Select * from metformin where (RX_END_DATE >= CAST(DATEADD(YEAR, -5, GETDATE()) AS date) OR RX_END_DATE is null) AND
RX_START_DATE < CAST(GETDATE() AS date) ;
select * from metformin5years order by RX_END_DATE ASC;

DROP TABLE IF EXISTS metformin_users5years;
CREATE TEMPORARY TABLE metformin_users5years as
select distinct PATID from metformin5years;

-- 3.3 Identify Patients with diabetes on metformin
DROP TABLE IF EXISTS G9;
CREATE TEMPORARY TABLE G9 as
SELECT DISTINCT G8.PATID, Race, ethnicity, sex, birthdatetime, first_vis
FROM G8
INNER JOIN metformin_users5years AS D
ON G8.PATID = D.PATID;
select * from G9;

-- 3.4 Save Row Cohort in FEAS2 and Get Distinct Patient Counts
DROP TABLE IF EXISTS FEAS2;
CREATE TEMPORARY TABLE FEAS2 as
SELECT DISTINCT PATID FROM G9;
SELECT COUNT(DISTINCT PATID) FROM FEAS2;

-- 3.5 Breakdowns
DROP TABLE IF EXISTS G9BD;
--Calculate age for all rows and add it as a column
CREATE TEMPORARY TABLE G9BD as
SELECT DISTINCT G9.PATID, G9.BIRTHDATETIME, G9.First_Vis, CAST(DATEDIFF(DAY,G9.BirthDateTime, g9.First_Vis)/365.25 AS INT)
AS Age_1st_Vis, G9.SEX, g9.Race, G9.Ethnicity FROM G9;
-- null in age first vis? what to do

-- Age
WITH Age AS (SELECT DISTINCT PATID,
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
SELECT Age_Cat, COUNT(DISTINCT PATID)
FROM Age GROUP BY Age_Cat ORDER BY Age_Cat;

SELECT SEX, COUNT(DISTINCT PATID) FROM G9 GROUP BY SEX ORDER BY SEX;
SELECT Race, COUNT(DISTINCT PATID) FROM G9 GROUP BY Race ORDER BY Race;
SELECT Ethnicity, COUNT(DISTINCT PATID) FROM G9 GROUP BY Ethnicity ORDER BY Ethnicity;
/****************************************************************/
