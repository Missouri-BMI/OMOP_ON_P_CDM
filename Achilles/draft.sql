use role omop_elt;
use warehouse omop_etl_wh;

use database atlas_gpc_dev;

create or replace schema cdm_v2;


use schema cdm_v2;

CREATE OR REPLACE PROCEDURE migrate()
  RETURNS VARCHAR
  LANGUAGE SQL
  AS
  DECLARE 
    fact_tables RESULTSET DEFAULT (select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME from information_schema.tables where table_schema = 'CDM');
    fact_cur CURSOR FOR fact_tables;
  BEGIN
   for r in fact_cur DO
    begin 
        if ( r.TABLE_NAME not in ('DRUG_EXPOSURE','VISIT_OCCURRENCE', 'PROCEDURE_OCCURRENCE', 'CONDITION_OCCURRENCE')) then
            EXECUTE IMMEDIATE 
                'CREATE OR REPLACE TABLE ' || r.TABLE_NAME || 
                ' AS SELECT * FROM ' || r.TABLE_CATALOG || '.' || r.TABLE_SCHEMA || '.' || r.TABLE_NAME;
        end if;
    end;
    END FOR;
  END;


call migrate();


select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME from information_schema.tables where table_schema = 'CDM';



select PROCEDURE_OCCURRENCE_ID from ATLAS_GPC_DEV.CDM.PROCEDURE_OCCURRENCE