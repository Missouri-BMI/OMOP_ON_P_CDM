with
-- First NICU visit within 10 days from birth
first_nicu_visit as
(select vo.person_id, p.birth_datetime,
min(vo.visit_start_datetime) as first_visit_dtm, date_diff(DAY, p.birth_datetime, min(vo.visit_start_datetime)) as age_at_first_nicu,
count(distinct vo.visit_occurrence_id) as total_visits
from visit_occurrence vo 
join person p on vo.person_id = p.person_id
join care_site cs1 on vo.care_site_id = cs1.care_site_id
left join visit_detail vd on vo.visit_occurrence_id = vd.visit_occurrence_id
left join care_site cs2 on vd.care_site_id = cs2.care_site_id
where vo.visit_start_date between '2015-01-01' and '2025-12-31'
and vo.visit_concept_id in (
262	--Emergency Room and Inpatient Visit
,9201 --Inpatient Visit
)
-- This part should be replaced with the names of your NICU units
and (cs1.care_site_name in ('TH 9 NICU', 'LB 5200 NICU', 'LI NW 2 NP 2800 NICU', 'LI NW 1 NP 1800 NICU') or cs2.care_site_name in ('TH 9 NICU', 'LB 5200 NICU', 'LI NW 2 NP 2800 NICU', 'LI NW 1 NP 1800 NICU'))
group by vo.person_id, p.birth_datetime
having date_diff(DAY, p.birth_datetime, min(vo.visit_start_datetime)) <=10
),
-- Selected NICU visits with all relevant data
nicu_visits as
(select vo.person_id, vo.visit_occurrence_id, vo.visit_start_datetime, vo.visit_start_date, vo.visit_end_datetime, vo.visit_end_date,
date_diff(DAY, vo.visit_start_datetime, vo.visit_end_datetime) as visit_length_in_days,
--vo.visit_type_concept_id
--vo.visit_concept_id, c1.concept_name as visit_concept_name,
--vo.discharged_to_source_value, 
d.death_date, d.death_datetime,
case when date_diff(DAY, vo.visit_end_date, coalesce(death_date, date_add(vo.visit_end_date, 1))) > 0 then 'Alive' else 'Dead' end as vital_status_at_dicharge
--vo.discharged_to_concept_id, c2.concept_name as discharged_to_concept_name
from first_nicu_visit fnv
join visit_occurrence vo on fnv.person_id = vo.person_id and vo.visit_start_datetime = fnv.first_visit_dtm
join concept c1 on vo.visit_concept_id = c1.concept_id
join concept c2 on vo.discharged_to_concept_id = c2.concept_id
left join death d on vo.person_id = d.person_id
where date_diff(HOUR, vo.visit_start_datetime, vo.visit_end_datetime) > 48
),
-- NICU patients with Sepsis diagnosis
sepsis_dx as
(select vo.person_id, min(co.condition_start_datetime) as sepsis_dx_dtm
from condition_occurrence co
join nicu_visits vo on co.visit_occurrence_id = vo.visit_occurrence_id
and co.condition_start_date between vo.visit_start_date and vo.visit_end_date
where co.condition_concept_id in
(select descendant_concept_id 
from concept_ancestor
where ancestor_concept_id = 4071063	--Sepsis of the newborn
)
group by vo.person_id
),
-- NICU Patients on Antibiotics for 5 days or longer
drug_exp as
(select vo.person_id, count(de.drug_exposure_id) as drug_count, min(date_diff(de.drug_exposure_end_date, de.drug_exposure_start_date)) as min_drug_length
from nicu_visits vo 
join drug_exposure de on de.person_id = vo.person_id
and (de.drug_exposure_start_date between vo.visit_start_date and vo.visit_end_date
or de.drug_exposure_end_date between vo.visit_start_date and vo.visit_end_date)
where de.drug_concept_id in
(select descendant_concept_id 
from concept_ancestor
where ancestor_concept_id = 21602796	--ANTIBACTERIALS FOR SYSTEMIC USE
--where ancestor_concept_id in (1707687,1709170,1717327,1774470,1777806,45892419)	--ANTIBACTERIALS used for new-born sepsis
)
group by vo.person_id
having (min(date_diff(de.drug_exposure_end_date, de.drug_exposure_start_date)) >= 5 or count(de.drug_exposure_id) > 5 )
),
-- Complete cohort
cohort as
(select nv.person_id, nv.visit_start_datetime, nv.visit_end_datetime, nv.visit_length_in_days, nv.vital_status_at_dicharge,
case when sd.sepsis_dx_dtm is null then 'No' else 'Yes' end as sepsis_dx,
sd.sepsis_dx_dtm,
case when sd.sepsis_dx_dtm is null then null else date_diff(HOUR, nv.visit_start_datetime, sd.sepsis_dx_dtm) end as time_to_sepsis_in_hours,
de.drug_count,
de.min_drug_length,
case when de.drug_count is null then 'No' else 'Yes' end as antibiotics_5_times,
case when de.min_drug_length is null  then 'No' else 'Yes' end as antibiotics_5_days
from nicu_visits nv
left join sepsis_dx sd on nv.person_id = sd.person_id
left join drug_exp de on nv.person_id = de.person_id
),
-- Cohort statistics
cohort_stats as 
(
select count(person_id) as nicu_visits, 
min(to_date(visit_start_datetime)) as min_visit_date, 
max(to_date(visit_start_datetime)) as max_visit_date,
min(visit_length_in_days) as min_visit_length_in_days,
max(visit_length_in_days) as max_visit_length_in_days,
sum(case when vital_status_at_dicharge = 'Alive' then 1 else 0 end) as discharged_alive,
sum(case when sepsis_dx = 'Yes' then 1 else 0 end) as sepsis_dx,
sum(case when antibiotics_5_days = 'Yes' or antibiotics_5_times = 'Yes' then 1 else 0 end) as antibiotics,
sum(case when sepsis_dx = 'Yes' or antibiotics_5_days = 'Yes' or antibiotics_5_times = 'Yes' then 1 else 0 end) as sepsis_or_antibiotics
from cohort
)

--QUERY
select *
from cohort_stats