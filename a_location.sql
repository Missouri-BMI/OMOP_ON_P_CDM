//Modified from the file at https://github.com/PEDSnet/pcornetcdm_to_pedsnetcdm/blob/main/sql_etl/scripts/etl_scripts/a_ethnicity_xwalk.sql
//Edited by CMS 2022/03/28
//SnowSQL

create sequence if not exists SITE_pedsnet.loc_seq;

begin;

INSERT INTO SITE_pedsnet.location(
    location_id,
    zip,
    location_source_value,
    country_concept_id,
    country_source_value,
    site)
select 
	nextval('SITE_pedsnet.loc_seq')::bigint AS location_id,
	facility_location as zip,
	'encounter | ' || facility_location  as location_source_value,
    148838 as country_concept_id,
    'United States' as country_source_value,
	'SITE' as site
 FROM SITE_pcornet.encounter enc
 WHERE enc.facility_type IS NOT NULL
 GROUP BY facility_location;

INSERT INTO SITE_pedsnet.location(
    location_id,
    city,
    state,
    zip,
    location_source_value,
    country_concept_id,
    country_source_value,
    site)
select 
 	nextval('SITE_pedsnet.loc_seq')::bigint AS location_id,
    address_city as city,
    address_state as state,
	zip as zip,
	'patient history | ' || zip as location_source_value,
    148838 as country_concept_id,
    'United States' as country_source_value,
	'SITE' as site
FROM 
    (select 
        case
            when address_zip5 is not null then address_zip5
            else address_zip9
        end as zip,
        address_city,
        address_state
    from SITE_pcornet.lds_address_history
	) as lds
where zip is not null
GROUP BY zip, address_city, address_state;

 -- default location

 INSERT INTO SITE_pedsnet.location(
    location_id,
    site)
 values(9999999,'SITE');
commit;