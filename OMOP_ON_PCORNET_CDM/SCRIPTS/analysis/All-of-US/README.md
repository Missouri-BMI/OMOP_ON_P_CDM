# All-of-US Analysis

## Stage

1. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Provide environment configuration:
```bash
create a .env file 
SNOWFLAKE_USER=user@example.com
SNOWFLAKE_ACCOUNT=ABC123-DEF456
SNOWFLAKE_ROLE=ANALYST_ROLE
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_DATABASE=SAMPLE_DB
SNOWFLAKE_SCHEMA=PUBLIC
CSV_DIR=/path/to/your/csv/files
# Edit .env with your configuration
```

3. Run staging script:
```bash
python stage_snowflake.py
```

## Run AoU Check

Build Docker container and run using Makefile:

```bash
make stage


make build
make run
```

TODO:
```
COPY INTO @{{ SNOWFLAKE_STAGE }}/provider.csv FROM (SELECT * FROM provider {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};

GET @{{ SNOWFLAKE_STAGE }}/provider.csv {{ LOCAL_STAGE }};


COPY INTO @{{ SNOWFLAKE_STAGE }}/device_exposure.csv FROM (SELECT * FROM device_exposure {{ LIMIT_PARAM }}) {{ COPY_PARAMETERS }};

GET @{{ SNOWFLAKE_STAGE }}/device_exposure.csv {{ LOCAL_STAGE }};
```