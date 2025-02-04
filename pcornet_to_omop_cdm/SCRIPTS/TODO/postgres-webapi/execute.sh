#!/bin/bash
set -e

psql -a -U "$POSTGRES_USER" -d ohdsi_webapi -c 'set search_path to webapi;' -f /OMOPCDM_DATASOURCE.sql