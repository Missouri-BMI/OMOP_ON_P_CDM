

CREATE DATABASE atlas_mu_sandbox;

GRANT OWNERSHIP ON DATABASE atlas_mu_sandbox TO ROLE omop_elt REVOKE CURRENT GRANTS;

USE ROLE omop_elt;

USE DATABASE atlas_mu_sandbox;

CREATE OR REPLACE SCHEMA cdm;
CREATE OR REPLACE SCHEMA vocabulary;
CREATE OR REPLACE SCHEMA results;
CREATE OR REPLACE SCHEMA temp;


--usage on cdm
GRANT USAGE ON SCHEMA cdm TO ROLE omop_atlas_sandbox;
GRANT SELECT ON ALL TABLES IN SCHEMA cdm TO ROLE omop_atlas_sandbox;
GRANT SELECT ON ALL VIEWS IN SCHEMA cdm TO ROLE omop_atlas_sandbox;
GRANT SELECT ON FUTURE TABLES IN SCHEMA cdm TO ROLE omop_atlas_sandbox;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA cdm TO ROLE omop_atlas_sandbox;

--usage on vocabulary
GRANT USAGE ON SCHEMA vocabulary TO ROLE omop_atlas_sandbox;
GRANT SELECT ON ALL TABLES IN SCHEMA vocabulary TO ROLE omop_atlas_sandbox; 
GRANT SELECT ON FUTURE TABLES IN SCHEMA vocabulary TO ROLE omop_atlas_sandbox;

--access on results
GRANT USAGE ON SCHEMA results TO ROLE omop_atlas_sandbox;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA results TO ROLE omop_atlas_sandbox;
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA results TO ROLE omop_atlas_sandbox;

--access on temp
GRANT USAGE ON SCHEMA temp TO ROLE omop_atlas_sandbox;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA temp TO ROLE omop_atlas_sandbox;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA temp TO ROLE omop_atlas_sandbox;
GRANT CREATE TABLE ON SCHEMA temp TO ROLE omop_atlas_sandbox;