-- BEGIN WRITE --
/*********************************************************************************
# Copyright 2014 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/

/************************

 ####### #     # ####### ######      #####  ######  #     #           #######      #####     ###
 #     # ##   ## #     # #     #    #     # #     # ##   ##    #    # #           #     #     #  #    # #####  ###### #    # ######  ####
 #     # # # # # #     # #     #    #       #     # # # # #    #    # #                 #     #  ##   # #    # #       #  #  #      #
 #     # #  #  # #     # ######     #       #     # #  #  #    #    # ######       #####      #  # #  # #    # #####    ##   #####   ####
 #     # #     # #     # #          #       #     # #     #    #    #       # ###       #     #  #  # # #    # #        ##   #           #
 #     # #     # #     # #          #     # #     # #     #     #  #  #     # ### #     #     #  #   ## #    # #       #  #  #      #    #
 ####### #     # ####### #           #####  ######  #     #      ##    #####  ###  #####     ### #    # #####  ###### #    # ######  ####


sql server script to create the required indexes within OMOP common data model, version 5.3

last revised: 14-November-2017

author:  Patrick Ryan, Clair Blacketer

description:  These primary keys and indices are considered a minimal requirement to ensure adequate performance of analyses.

*************************/


/************************
*************************
*************************
*************************

Primary key constraints

*************************
*************************
*************************
************************/



/************************

Standardized vocabulary

************************/

/**************************

Standardized meta-data

***************************/



/************************

Standardized clinical data

************************/


/**PRIMARY KEY NONCLUSTERED constraints**/

ALTER TABLE TRACS_CDM.OMOP.xstg_person ADD CONSTRAINT xpk_person PRIMARY KEY NONCLUSTERED ( person_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_observation_period ADD CONSTRAINT xpk_observation_period PRIMARY KEY NONCLUSTERED ( observation_period_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_specimen ADD CONSTRAINT xpk_specimen PRIMARY KEY NONCLUSTERED ( specimen_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_death ADD CONSTRAINT xpk_death PRIMARY KEY NONCLUSTERED ( person_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_visit_occurrence ADD CONSTRAINT xpk_visit_occurrence PRIMARY KEY NONCLUSTERED ( visit_occurrence_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_visit_detail ADD CONSTRAINT xpk_visit_detail PRIMARY KEY NONCLUSTERED ( visit_detail_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_procedure_occurrence ADD CONSTRAINT xpk_procedure_occurrence PRIMARY KEY NONCLUSTERED ( procedure_occurrence_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_drug_exposure ADD CONSTRAINT xpk_drug_exposure PRIMARY KEY NONCLUSTERED ( drug_exposure_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_device_exposure ADD CONSTRAINT xpk_device_exposure PRIMARY KEY NONCLUSTERED ( device_exposure_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_condition_occurrence ADD CONSTRAINT xpk_condition_occurrence PRIMARY KEY NONCLUSTERED ( condition_occurrence_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_measurement ADD CONSTRAINT xpk_measurement PRIMARY KEY NONCLUSTERED ( measurement_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_note ADD CONSTRAINT xpk_note PRIMARY KEY NONCLUSTERED ( note_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_note_nlp ADD CONSTRAINT xpk_note_nlp PRIMARY KEY NONCLUSTERED ( note_nlp_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

ALTER TABLE TRACS_CDM.OMOP.xstg_observation  ADD CONSTRAINT xpk_observation PRIMARY KEY NONCLUSTERED ( observation_id ) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );



/************************

Standardized health system data

************************/


ALTER TABLE TRACS_CDM.OMOP.xstg_location ADD CONSTRAINT xpk_location PRIMARY KEY NONCLUSTERED ( location_id ) ;

ALTER TABLE TRACS_CDM.OMOP.xstg_care_site ADD CONSTRAINT xpk_care_site PRIMARY KEY NONCLUSTERED ( care_site_id ) ;

ALTER TABLE TRACS_CDM.OMOP.xstg_provider ADD CONSTRAINT xpk_provider PRIMARY KEY NONCLUSTERED ( provider_id ) ;



/************************

Standardized health economics

************************/

/************************

Standardized derived elements

************************/

-- END WRITE --
-- BEGIN WRITE --

/************************
*************************
*************************
*************************

Indices

*************************
*************************
*************************
************************/

/************************

Standardized vocabulary

************************/

/**************************

Standardized meta-data

***************************/





/************************

Standardized clinical data

************************/

CREATE UNIQUE CLUSTERED INDEX idx_person_id ON TRACS_CDM.OMOP.xstg_person (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_observation_period_id ON TRACS_CDM.OMOP.xstg_observation_period (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_specimen_person_id ON TRACS_CDM.OMOP.xstg_specimen (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_specimen_concept_id ON TRACS_CDM.OMOP.xstg_specimen (specimen_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_death_person_id ON TRACS_CDM.OMOP.xstg_death (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_visit_person_id ON TRACS_CDM.OMOP.xstg_visit_occurrence (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_visit_concept_id ON TRACS_CDM.OMOP.xstg_visit_occurrence (visit_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_visit_detail_person_id ON TRACS_CDM.OMOP.xstg_visit_detail (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_visit_detail_concept_id ON TRACS_CDM.OMOP.xstg_visit_detail (visit_detail_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_procedure_person_id ON TRACS_CDM.OMOP.xstg_procedure_occurrence (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_procedure_concept_id ON TRACS_CDM.OMOP.xstg_procedure_occurrence (procedure_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_procedure_visit_id ON TRACS_CDM.OMOP.xstg_procedure_occurrence (visit_occurrence_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_drug_person_id ON TRACS_CDM.OMOP.xstg_drug_exposure (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_drug_concept_id ON TRACS_CDM.OMOP.xstg_drug_exposure (drug_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_drug_visit_id ON TRACS_CDM.OMOP.xstg_drug_exposure (visit_occurrence_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_device_person_id ON TRACS_CDM.OMOP.xstg_device_exposure (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_device_concept_id ON TRACS_CDM.OMOP.xstg_device_exposure (device_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_device_visit_id ON TRACS_CDM.OMOP.xstg_device_exposure (visit_occurrence_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_condition_person_id ON TRACS_CDM.OMOP.xstg_condition_occurrence (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_condition_concept_id ON TRACS_CDM.OMOP.xstg_condition_occurrence (condition_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_condition_visit_id ON TRACS_CDM.OMOP.xstg_condition_occurrence (visit_occurrence_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_measurement_person_id ON TRACS_CDM.OMOP.xstg_measurement (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_measurement_concept_id ON TRACS_CDM.OMOP.xstg_measurement (measurement_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_measurement_visit_id ON TRACS_CDM.OMOP.xstg_measurement (visit_occurrence_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_note_person_id ON TRACS_CDM.OMOP.xstg_note (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_note_concept_id ON TRACS_CDM.OMOP.xstg_note (note_type_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_note_visit_id ON TRACS_CDM.OMOP.xstg_note (visit_occurrence_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_note_nlp_note_id ON TRACS_CDM.OMOP.xstg_note_nlp (note_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_note_nlp_concept_id ON TRACS_CDM.OMOP.xstg_note_nlp (note_nlp_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE CLUSTERED INDEX idx_observation_person_id ON TRACS_CDM.OMOP.xstg_observation (person_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_observation_concept_id ON TRACS_CDM.OMOP.xstg_observation (observation_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_observation_visit_id ON TRACS_CDM.OMOP.xstg_observation (visit_occurrence_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );

CREATE INDEX idx_fact_relationship_id_1 ON TRACS_CDM.OMOP.xstg_fact_relationship (domain_concept_id_1 ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_fact_relationship_id_2 ON TRACS_CDM.OMOP.xstg_fact_relationship (domain_concept_id_2 ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );
CREATE INDEX idx_fact_relationship_id_3 ON TRACS_CDM.OMOP.xstg_fact_relationship (relationship_concept_id ASC) with (ONLINE=OFF, DATA_COMPRESSION = PAGE );



/************************

Standardized health system data

************************/





/************************

Standardized health economics

************************/




/************************

Standardized derived elements

************************/
-- END WRITE --
