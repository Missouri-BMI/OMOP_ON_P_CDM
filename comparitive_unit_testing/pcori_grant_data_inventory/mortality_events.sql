
WITH 
-- Inpatient visits between 2013 and 2018
cohort AS (
  SELECT
    vo.person_id,
    vo.visit_occurrence_id,
    vo.visit_start_date,
    vo.visit_end_date,
    d.death_date,
    CASE WHEN date_diff(DAY, vo.visit_end_date, coalesce(d.death_date, date_add(vo.visit_end_date, -1))) BETWEEN 0 AND 60 THEN 'Y' ELSE 'N' END AS dead_within_2months
  FROM visit_occurrence vo
  JOIN person p ON vo.person_id = p.person_id
  LEFT JOIN death d ON vo.person_id = d.person_id
  WHERE
    vo.visit_start_date BETWEEN '2013-01-01' AND '2018-12-31'
    AND (vo.visit_concept_id = 9201 OR vo.visit_concept_id = 262)
    AND YEAR(vo.visit_start_date) - p.year_of_birth >= 18
),
-- Conditions within past year of visit start date
cond as
(select coh.visit_occurrence_id, case when count(distinct co.condition_concept_id) = 0 then 1 else 0 end as visit_without_event,
count(distinct co.condition_concept_id) as event_count     
from cohort coh
left join condition_occurrence co on co.person_id = coh.person_id 
and (co.condition_start_date between date_add(coh.visit_start_date, -365) and coh.visit_start_date 
     or co.condition_end_date between date_add(coh.visit_start_date, -365) and coh.visit_start_date)
group by coh.visit_occurrence_id
),
-- Procedures within past year of visit start date
proc as
(select coh.visit_occurrence_id, case when count(distinct po.procedure_concept_id) = 0 then 1 else 0 end as visit_without_event,
count(distinct po.procedure_concept_id) as event_count     
from cohort coh
left join procedure_occurrence po on po.person_id = coh.person_id 
and po.procedure_date between date_add(coh.visit_start_date, -365) and coh.visit_start_date
group by coh.visit_occurrence_id
),
-- Measurements within past year of visit start date
meas as
(select coh.visit_occurrence_id, case when count(distinct m.measurement_concept_id) = 0 then 1 else 0 end as visit_without_event,
count(distinct m.measurement_concept_id) as event_count     
from cohort coh
left join measurement m on m.person_id = coh.person_id 
and m.measurement_date between date_add(coh.visit_start_date, -365) and coh.visit_start_date
group by coh.visit_occurrence_id
),
-- Medications within past year of visit start date
drug as
(select coh.visit_occurrence_id, case when count(distinct de.drug_concept_id) = 0 then 1 else 0 end as visit_without_event,
count(distinct c.concept_id) as event_count     
from cohort coh
left join drug_exposure de on de.person_id = coh.person_id 
and (de.drug_exposure_start_date between date_add(coh.visit_start_date, -365) and coh.visit_start_date
or de.drug_exposure_end_date between date_add(coh.visit_start_date, -365) and coh.visit_start_date)
left join concept_ancestor ca on de.drug_concept_id = ca.descendant_concept_id
left join concept c on ca.ancestor_concept_id = c.concept_id and c.concept_class_id = 'Ingredient'
group by coh.visit_occurrence_id
),
-- Tobacco use/smoking history before or during the visit
obs as
(select coh.visit_occurrence_id, case when count(distinct o.observation_concept_id) = 0 then 1 else 0 end as visit_without_event,
count(distinct o.observation_concept_id) as event_count     
from cohort coh
left join observation o on o.person_id = coh.person_id 
and o.visit_occurrence_id = coh.visit_occurrence_id and o.observation_date <= coh.visit_end_date
and (o.observation_concept_id in (62352333, 40766945, 2101895, 2617854, 32531616, 42742404, 31627890, 903651, 903653, 903654, 903656, 903657, 903667, 2101895, 2101897, 2108525, 2108526, 2617854, 40756893, 40766945, 42742404) -- Smoking
or o.value_as_concept_id in (62352333, 40766945, 2101895, 2617854, 32531616, 42742404, 31627890, 903651, 903653, 903654, 903656, 903657, 903667, 2101895, 2101897, 2108525, 2108526, 2617854, 40756893, 40766945, 42742404) -- Smoking
)
group by coh.visit_occurrence_id
)

-- QUERY
select 'condition_occurrence' as domain, count(distinct visit_occurrence_id) as visit_count, sum(visit_without_event) as visits_without_event, round(avg(event_count)) as avg_event_count, max(event_count) as max_event_count
from cond
union all
select 'procedure_occurrence' as domain, count(distinct visit_occurrence_id) as visit_count, sum(visit_without_event) as visits_without_event, round(avg(event_count)) as avg_event_count, max(event_count) as max_event_count
from proc
UNION all
select 'measurement' as domain, count(distinct visit_occurrence_id) as visit_count, sum(visit_without_event) as visits_without_event, round(avg(event_count)) as avg_event_count, max(event_count) as max_event_count
from meas
UNION all
select 'drug_exposure' as domain, count(distinct visit_occurrence_id) as visit_count, sum(visit_without_event) as visits_without_event, round(avg(event_count)) as avg_event_count, max(event_count) as max_event_count
from drug
UNION all
select 'smoking observation' as domain, count(distinct visit_occurrence_id) as visit_count, sum(visit_without_event) as visits_without_event, round(avg(event_count)) as avg_event_count, max(event_count) as max_event_count
from obs
