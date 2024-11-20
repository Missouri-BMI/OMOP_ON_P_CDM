--multiple entry per patid
--multiple entry in death per patid
Create or replace view CDM.person AS
(
SELECT distinct demographic.patid::INTEGER                                                   AS PERSON_ID,
 
   left join
        CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING gender_map
        on demographic.sex = gender_map.PCORNET_VALUESET_ITEM
            and gender_map.source_concept_class = 'Gender'
            and gender_map.pcornet_table_name = 'DEMOGRAPHIC' 
            and gender_map.pcornet_field_name = 'SEX'
    left join
        CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING ethnicity_map
        on demographic.hispanic = ethnicity_map.PCORNET_VALUESET_ITEM
        and ethnicity_map.source_concept_class = 'Hispanic'
        and ethnicity_map.pcornet_table_name = 'DEMOGRAPHIC' 
        and ethnicity_map.pcornet_field_name = 'HISPANIC'
    left join
        CROSSWALK.OMOP_PCORNET_VALUESET_MAPPING race_map
        on demographic.race = race_map.PCORNET_VALUESET_ITEM
        and race_map.source_concept_class = 'Race'
        and race_map.pcornet_table_name = 'DEMOGRAPHIC' 
        and race_map.pcornet_field_name = 'RACE'
    left join DEIDENTIFIED_PCORNET_CDM.CDM.DEID_DEATH death
        on death.patid = demographic.patid

where year_of_birth is not null
    );



