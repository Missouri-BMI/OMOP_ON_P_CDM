#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER"<<-EOSQL
	CREATE DATABASE ohdsi_webapi;
EOSQL


psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d ohdsi_webapi<<-EOSQL
	
	CREATE SCHEMA webapi;

EOSQL