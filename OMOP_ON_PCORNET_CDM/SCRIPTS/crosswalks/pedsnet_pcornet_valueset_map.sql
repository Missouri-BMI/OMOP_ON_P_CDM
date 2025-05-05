CREATE TABLE OMOP_CDM.crosswalk.pedsnet_pcornet_valueset_map (
			source_concept_class varchar(50) NOT NULL,
			target_concept varchar(100) NULL,
			pcornet_name varchar(255) NULL,
			source_concept_id varchar(255) NULL,
            concept_description varchar(255) NULL,
			value_as_concept_id varchar(50) NULL );

--loaded data from concept_map.txt file from pedsnet 