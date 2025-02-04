#!/bin/bash

set -e

psql -a -U "$POSTGRES_USER" -d omop_cdm  -f /OMOPCDM_GENERATE.sql