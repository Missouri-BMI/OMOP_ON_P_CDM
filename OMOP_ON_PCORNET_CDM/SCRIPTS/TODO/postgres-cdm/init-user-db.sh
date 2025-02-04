#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER"<<-EOSQL
	                                    
	CREATE DATABASE omop_cdm;

EOSQL


psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d omop_cdm<<-EOSQL
	CREATE SCHEMA cdm;
	CREATE SCHEMA results;
	CREATE SCHEMA temp;
	CREATE SCHEMA native;
EOSQL
