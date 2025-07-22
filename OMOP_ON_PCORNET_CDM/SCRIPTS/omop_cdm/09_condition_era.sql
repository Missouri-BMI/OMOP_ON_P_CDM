CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.condition_era (
    condition_era_id integer NOT NULL,
    person_id integer NOT NULL,
    condition_concept_id integer NOT NULL,
    condition_era_start_date date NOT NULL,
    condition_era_end_date date NOT NULL,
    condition_occurrence_count integer NULL
) AS
WITH cteConditionTarget (condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_end_date) AS (
    SELECT
        co.condition_occurrence_id,
        co.person_id,
        co.condition_concept_id,
        co.condition_start_date,
        COALESCE(co.condition_end_date, DATEADD(day, 1, condition_start_date)) AS condition_end_date
    FROM {{ cdm_db }}.{{ cdm_schema }}.condition_occurrence co
    -- Uncomment to exclude unmapped concept IDs:
    -- WHERE co.condition_concept_id != 0
),
--------------------------------------------------------------------------------------------------------------
cteEndDates (person_id, condition_concept_id, end_date) AS (
    SELECT
        person_id,
        condition_concept_id,
        DATEADD(day, -30, event_date) AS end_date
    FROM (
        SELECT
            person_id,
            condition_concept_id,
            event_date,
            event_type,
            MAX(start_ordinal) OVER (
                PARTITION BY person_id, condition_concept_id 
                ORDER BY event_date, event_type 
                ROWS UNBOUNDED PRECEDING
            ) AS start_ordinal,
            ROW_NUMBER() OVER (
                PARTITION BY person_id, condition_concept_id 
                ORDER BY event_date, event_type
            ) AS overall_ord
        FROM (
            SELECT
                person_id,
                condition_concept_id,
                condition_start_date AS event_date,
                -1 AS event_type,
                ROW_NUMBER() OVER (
                    PARTITION BY person_id, condition_concept_id 
                    ORDER BY condition_start_date
                ) AS start_ordinal
            FROM cteConditionTarget
            UNION ALL
            SELECT
                person_id,
                condition_concept_id,
                DATEADD(day, 30, condition_end_date),
                1 AS event_type,
                NULL
            FROM cteConditionTarget
        ) RAWDATA
    ) e
    WHERE (2 * e.start_ordinal) - e.overall_ord = 0
),
--------------------------------------------------------------------------------------------------------------
cteConditionEnds (person_id, condition_concept_id, condition_start_date, era_end_date) AS (
    SELECT
        c.person_id,
        c.condition_concept_id,
        c.condition_start_date,
        MIN(e.end_date) AS era_end_date
    FROM cteConditionTarget c
    JOIN cteEndDates e 
        ON c.person_id = e.person_id 
        AND c.condition_concept_id = e.condition_concept_id 
        AND e.end_date >= c.condition_start_date
    GROUP BY
        c.condition_occurrence_id,
        c.person_id,
        c.condition_concept_id,
        c.condition_start_date
)
--------------------------------------------------------------------------------------------------------------
SELECT
    ROW_NUMBER() OVER (ORDER BY person_id) AS condition_era_id,
    person_id,
    condition_concept_id,
    MIN(condition_start_date) AS condition_era_start_date,
    era_end_date AS condition_era_end_date,
    COUNT(*) AS condition_occurrence_count
FROM cteConditionEnds
GROUP BY person_id, condition_concept_id, era_end_date
;
