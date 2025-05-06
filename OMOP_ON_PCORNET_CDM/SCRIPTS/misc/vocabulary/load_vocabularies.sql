COPY INTO {cdm_db}.{vocabulary}.DRUG_STRENGTH
  FROM @{pcornet_db}.staging.aws_stage
  PATTERN = '.*DRUG_STRENGTH.*'
  FILE_FORMAT = (FORMAT_NAME = csv_files);

COPY INTO {cdm_db}.{vocabulary}.CONCEPT_SYNONYM
  FROM @{pcornet_db}.staging.aws_stage
  PATTERN = '.*CONCEPT_SYNONYM.*'
  FILE_FORMAT = (FORMAT_NAME = csv_files);

COPY INTO {cdm_db}.{vocabulary}.CONCEPT
  FROM @{pcornet_db}.staging.aws_stage
  PATTERN = '.*CONCEPT.csv'
  FILE_FORMAT = (FORMAT_NAME = csv_files);

COPY INTO {cdm_db}.{vocabulary}.CONCEPT_ANCESTOR
  FROM @{pcornet_db}.staging.aws_stage
  PATTERN = '.*CONCEPT_ANCESTOR.*'
  FILE_FORMAT = (FORMAT_NAME = csv_files);

COPY INTO {cdm_db}.{vocabulary}.CONCEPT_RELATIONSHIP
  FROM @{pcornet_db}.staging.aws_stage
  PATTERN = '.*CONCEPT_RELATIONSHIP.*'
  FILE_FORMAT = (FORMAT_NAME = csv_files);