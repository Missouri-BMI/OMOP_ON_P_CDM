--create sequence measurement_id_seq;

create or replace view omop_cdm.cdm.deid_measurement
AS
SELECT DISTINCT
    lab.LAB_RESULT_CM_ID::INTEGER AS measurement_id,

    lab.patid::INTEGER AS person_id,

    coalesce(c.concept_id,0)::INTEGER AS measurement_concept_id,

    coalesce(lab.result_date,lab.specimen_date)::DATE AS measurement_date,

  coalesce(lab.result_date,lab.specimen_date)::DATETIME AS measurement_datetime,

    lab.SPECIMEN_TIME::VARCHAR(10) AS measurement_time,

    44818702::INTEGER AS measurement_type_concept_id,

    coalesce(
          case
               when lab.result_modifier = 'OT' then 4172703
               else opa.source_concept_id::int
          end,0)::INTEGER AS operator_concept_id,

    lab.result_num::NUMERIC AS value_as_number,

 case
		when lower(trim(result_qual)) = 'positive' then 45884084
	     when lower(trim(result_qual)) = 'negative' then 45878583
          when lower(trim(result_qual)) = 'pos' then 45884084
          when lower(trim(result_qual)) = 'neg' then 45878583
          when lower(trim(result_qual)) = 'presumptive positive' then 45884084
          when lower(trim(result_qual)) = 'presumptive negative' then 45878583
          when lower(trim(result_qual)) = 'detected' then 45884084
          when lower(trim(result_qual)) = 'not detected' then 45878583
          when lower(trim(result_qual)) = 'inconclusive' then 45877990
          when lower(trim(result_qual)) = 'normal' then 45884153
          when lower(trim(result_qual)) = 'abnormal' then 45878745
          when lower(trim(result_qual)) = 'low' then 45881666
          when lower(trim(result_qual)) = 'high' then 45876384
          when lower(trim(result_qual)) = 'borderline' then 45880922
          when lower(trim(result_qual)) = 'elevated' then 4328749
          when lower(trim(result_qual)) = 'undetermined' then 45880649
          when lower(trim(result_qual)) = 'undetectable' then 45878583
          when lower(trim(result_qual)) = 'un' then 0
          when lower(trim(result_qual)) = 'unknown' then 0
          when lower(trim(result_qual)) = 'no information' then 46237210
          else 45877393
     end::INTEGER AS value_as_concept_id,

    coalesce(
          case
               when lab.result_unit = '[ppm]' then 9387
               when lab.result_unit = '%{activity}' then 8687
               when lab.result_unit = 'nmol/min/mL' then 44777635
               when lab.result_unit = 'kU/L' then 8810
               else units.source_concept_id::int
          end, 0)::INTEGER AS unit_concept_id,

         /* (case
               when lab.norm_range_low = '' then 0::Integer
               else lab.norm_range_low
            end)

            */
            NULL::NUMERIC AS range_low,
         /* (case
               when lab.norm_range_high = '' then 0::Integer
               else lab.norm_range_high
            end)
            */
            NULL::NUMERIC AS range_high,

  NULL::INTEGER AS provider_id,

  lab.encounterid::INTEGER AS visit_occurrence_id,

  NULL::INTEGER AS visit_detail_id,

  lab.LAB_LOINC::VARCHAR(50) AS measurement_source_value,

  coalesce(c.concept_id,0)::INTEGER AS measurement_source_concept_id,

  left(lab.raw_unit,50)::VARCHAR(50) AS unit_source_value,

  coalesce(
          case
               when lab.result_unit = '[ppm]' then 9387
               when lab.result_unit = '%{activity}' then 8687
               when lab.result_unit = 'nmol/min/mL' then 44777635
               when lab.result_unit = 'kU/L' then 8810
               else units.source_concept_id::int
          end, 0)::INTEGER AS unit_source_concept_id,

 COALESCE(NULLIF(lab.result_num, 0)::text, left(lab.raw_result,50), 'Unknown')::VARCHAR(50) AS value_source_value,

 NULL::INTEGER AS measurement_event_id,

 NULL::INTEGER AS meas_event_field_concept_id

FROM pcornet_cdm.cdm.deid_lab_result_cm lab
left join
     (
          select target_concept, source_concept_id
          from OMOP_CDM.CROSSWALK.PEDSNET_PCORNET_VALUESET_MAP
          where source_concept_class = 'Result modifier'
          and not (target_concept = 'OT' and source_concept_id = '0')
     ) as opa on opa.target_concept = lab.result_modifier
left join
     (
          select target_concept, source_concept_id
          from OMOP_CDM.CROSSWALK.PEDSNET_PCORNET_VALUESET_MAP
          where source_concept_class = 'Result unit'
		  and source_concept_id <> 'null'
          and not (target_concept = '10*3/uL' and pcornet_name is null)
          and not (target_concept = '10*6/uL' and pcornet_name is null)
          and not (target_concept = 'a' and concept_description = 'y | year')
          and not (target_concept = '[APL''U]/mL' and pcornet_name is null)
          and not (target_concept = '{breaths}/min' and concept_description = 'breaths/min')
          and not (target_concept = '{cells}/[HPF]' and concept_description <> 'cells per high power field')
          and not (target_concept = '{cells}/uL' and concept_description = 'cells/cumm')
          and not (target_concept = '[GPL''U]/mL' and pcornet_name is null)
          and not (target_concept = '{index_val}' and concept_description <> 'index value')
          and not (target_concept = '[IU]/g{Hb}' and pcornet_name is null)
          and not (target_concept = 'k[IU]/L' and concept_description = 'kilo-international unit per liter')
          and not (target_concept = 'meq/L' and pcornet_name is null)
          and not (target_concept = 'mmol/mol{creat}' and concept_description = 'mmol/mol cr')
          and not (target_concept = '[MPL''U]/mL' and pcornet_name is null)
          and not (target_concept = 'NI' and source_concept_id = '0')
          and not (target_concept = '%{normal}' and concept_description = 'NEG>CULTURE')
          and not (target_concept = '[pH]' and pcornet_name is null)
          and not (target_concept = '{ratio}' and pcornet_name is null)
          and not (target_concept = 'ug{FEU}/mL' and pcornet_name is null)
          and not (target_concept = 'U/g{Hb}' and pcornet_name is null)
          and not (target_concept = '/uL' and concept_description = '/cumm')
          and not (target_concept = 'U/mL' and pcornet_name is null)
     ) as units on lab.result_unit = units.target_concept
left join OMOP_CDM.vocabulary.concept c on lab.lab_loinc=c.concept_code and c.vocabulary_id='LOINC'
;

select count(distinct person_id) from omop_cdm.cdm.death; --306091
select count(distinct patid) from  pcornet_cdm.cdm_2023_april.deid_death; --306091

select count(*) from omop_cdm.cdm.measurement; --192210867
select count(*) from  pcornet_cdm.cdm_2023_april.deid_lab_result_cm; --172156949


--select distinct norm_range_high from pcornet_cdm.cdm_2023_april.deid_lab_result_cm lab