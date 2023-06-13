#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER"<<-EOSQL
	CREATE DATABASE ohdsi_webapi;
EOSQL


psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d ohdsi_webapi<<-EOSQL
	
	CREATE SCHEMA webapi;

EOSQL


psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d ohdsi_webapi<<-EOSQL
	
	CREATE SCHEMA atlas_security;

EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d ohdsi_webapi<<-EOSQL
	
	CREATE TABLE atlas_security.demo_security
(
    username character varying(255) COLLATE pg_catalog."default",
    password character varying(255) COLLATE pg_catalog."default",
    firstname character varying(255) COLLATE pg_catalog."default",
    middlename character varying(255) COLLATE pg_catalog."default",
    lastname character varying(255) COLLATE pg_catalog."default"
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

EOSQL


psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d ohdsi_webapi<<-EOSQL
	
	
insert into atlas_security.demo_security (username,password) 
values ('mhmcb@umsystem.edu', '$2a$10$yWxENTszMTH10V.w5hO4TuKetluoCP68Ex7EnpebHYn6nAxIRMr6u');

EOSQL

