
WITH 
-- Inpatient visits between 2013 and 2018
cohort AS (
  SELECT
    vo.person_id,
    vo.visit_occurrence_id,
    vo.visit_start_date AS AdmissionDate,
    vo.visit_end_date AS DischargeDate,
    d.death_date,
    CASE WHEN date_diff(DAY, vo.visit_start_date, coalesce(d.death_date, date_add(vo.visit_start_date, -1))) BETWEEN 0 AND 60 THEN 'Y' ELSE 'N' END AS dead_within_2months
  FROM visit_occurrence vo
  JOIN person p ON vo.person_id = p.person_id
  LEFT JOIN death d ON vo.person_id = d.person_id
  WHERE
    vo.visit_start_date BETWEEN '2013-01-01' AND '2018-12-31'
    AND (vo.visit_concept_id = 9201 OR vo.visit_concept_id = 262)
    AND YEAR(vo.visit_start_date) - p.year_of_birth >= 18
),
-- Cohort statistics
cohort_stats AS (
 SELECT 
dead_within_2months, count(distinct person_id) as total_patients, count(distinct visit_occurrence_id) as total_visits
FROM cohort
GROUP by dead_within_2months
)

--QUERY
SELECT *
FROM cohort_stats
