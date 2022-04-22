//Created by CMS 2022/04/22 to prepare to stage table from https://github.com/PEDSnet/pcornetcdm_to_pedsnetcdm/blob/main/sql_etl/data/concept_map.txt
//Edited by 
//SnowSQL

CREATE TABLE pedsnet_pcornet_valueset_map (
			source_concept_class varchar(50) NOT NULL,
			target_concept varchar(100) NULL,
			pcornet_name varchar(255) NULL,
			source_concept_id varchar(255) NULL,
            concept_description varchar(255) NULL,
			value_as_concept_id varchar(50) NULL );
