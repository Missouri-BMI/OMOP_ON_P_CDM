{% if site in ['mu', 'mu-id'] %}
  {% set person_id_expr = "procedures.patid::INTEGER" %}
  {% set provider_id_expr = "procedures.providerid::INTEGER" %}
  {% set visit_occurrence_id_expr = "procedures.encounterid::INTEGER" %}
{% elif site == 'gpc' %}
  {% set person_id_expr = "procedures.patient_num::INTEGER" %}
  {% set provider_id_expr = "-1::INTEGER" %}
  {% set visit_occurrence_id_expr = "procedures.encounter_num::INTEGER" %}
{% else %}
  {% set person_id_expr = "procedures.patid::INTEGER" %}
  {% set provider_id_expr = "procedures.providerid::INTEGER" %}
  {% set visit_occurrence_id_expr = "procedures.encounterid::INTEGER" %}
{% endif %}

CREATE OR REPLACE SEQUENCE {{ cdm_db }}.{{ cdm_schema }}.procedure_occurrence_id_seq START = 1 INCREMENT = 1;
-- 1) Create a mapping table to generate procedure_occurrence_id values
CREATE OR REPLACE TABLE {{ cdm_db }}.{{ cdm_schema }}.procedure_occurrence_id_map AS
WITH ids AS (
  SELECT distinct
    procedures.PROCEDURESID     AS procedureid_source
  FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ procedure_table }} procedures
  WHERE procedures.PROCEDURESID IS NOT NULL
)
SELECT
  procedureid_source,
  {{ cdm_db }}.{{ cdm_schema }}.procedure_occurrence_id_seq.NEXTVAL::INTEGER AS procedure_occurrence_id
FROM ids
;


-- 2) PROCEDURE_OCCURRENCE using the mapper as the single source of truth for IDs
CREATE  TABLE {{ cdm_db }}.{{ cdm_schema }}.procedure_occurrence AS
SELECT
    -- maintain DDL column order
    idmap.procedure_occurrence_id::INTEGER                             AS procedure_occurrence_id,
    {{ person_id_expr }}                                               AS person_id,

    COALESCE(srctostdvm.target_concept_id, srctosrcvm.target_concept_id)::INTEGER
                                                                       AS procedure_concept_id,

    COALESCE(procedures.px_date, procedures.admit_date)::DATE          AS procedure_date,
    procedures.admit_date::TIMESTAMP                                   AS procedure_datetime,
    NULL::DATE                                                         AS procedure_end_date,
    NULL::TIMESTAMP                                                    AS procedure_end_datetime,

    CASE
      WHEN procedures.px_source = 'OD' THEN 38000275
      WHEN procedures.px_source = 'BI' THEN 44786631
      ELSE 32827
    END::INTEGER                                                       AS procedure_type_concept_id,

    0::INTEGER                                                         AS modifier_concept_id,
    NULL::INTEGER                                                      AS quantity,

    {{ provider_id_expr }}                                             AS provider_id,
    {{ visit_occurrence_id_expr }}                                     AS visit_occurrence_id,

    NULL::INTEGER                                                      AS visit_detail_id,
    LEFT(COALESCE(procedures.px::VARCHAR, ''), 50)::VARCHAR(50)         AS procedure_source_value,
    srctosrcvm.source_concept_id::INTEGER                               AS procedure_source_concept_id,
    NULL::VARCHAR(50)                                                   AS modifier_source_value

FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ procedure_table }} procedures

JOIN {{ cdm_db }}.{{ cdm_schema }}.procedure_occurrence_id_map idmap
  ON idmap.procedureid_source = procedures.PROCEDURESID

JOIN {{ cdm_db }}.{{ vocabulary }}.source_to_source_vocab_map srctosrcvm
  ON srctosrcvm.source_code = procedures.px
 AND srctosrcvm.source_vocabulary_id =
    CASE 
      WHEN procedures.px_type = '09' THEN 'ICD9Proc'
      WHEN procedures.px_type = '10' THEN 'ICD10PCS'
      WHEN procedures.px_type = 'CH' THEN 
        CASE 
          WHEN procedures.raw_px_type = 'CPT4' THEN 'CPT4'
          ELSE 'HCPCS'
        END
    END
 AND srctosrcvm.source_domain_id = 'Procedure'

LEFT JOIN {{ cdm_db }}.{{ vocabulary }}.source_to_standard_vocab_map srctostdvm
  ON srctostdvm.source_code = srctosrcvm.source_code
 AND srctostdvm.target_domain_id = srctosrcvm.source_domain_id 
 AND srctostdvm.source_vocabulary_id = srctosrcvm.source_vocabulary_id
 AND srctostdvm.target_standard_concept = 'S'
 AND srctostdvm.target_invalid_reason IS NULL
;
