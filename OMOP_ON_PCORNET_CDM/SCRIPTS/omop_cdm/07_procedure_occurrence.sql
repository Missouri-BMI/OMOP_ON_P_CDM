{% if site in ['mu', 'mu-id'] %}
  {% set person_id_expr = "procedures.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "procedures.encounterid::INTEGER" %}
{% elif site == 'gpc' %}
  {% set person_id_expr = "procedures.patient_num::INTEGER" %}
  {% set visit_occurrence_id_expr = "procedures.encounter_num::INTEGER" %}
{% else %}
  {% set person_id_expr = "procedures.patid::INTEGER" %}
  {% set visit_occurrence_id_expr = "procedures.encounterid::INTEGER" %}
{% endif %}

CREATE TABLE {{ cdm_db }}.{{ cdm_schema }}.procedure_occurrence (
    procedure_occurrence_id integer IDENTITY (1,1) not null,
    person_id integer NOT NULL,
    procedure_concept_id integer NOT NULL,
    procedure_date date NOT NULL,
    procedure_datetime TIMESTAMP NULL,
    procedure_end_date date NULL,
    procedure_end_datetime TIMESTAMP NULL,
    procedure_type_concept_id integer NOT NULL,
    modifier_concept_id integer NULL,
    quantity integer NULL,
    provider_id integer NULL,
    visit_occurrence_id integer NULL,
    visit_detail_id integer NULL,
    procedure_source_value varchar(50) NULL,
    procedure_source_concept_id integer NULL,
    modifier_source_value varchar(50) NULL 
);

INSERT INTO {{ cdm_db }}.{{ cdm_schema }}.procedure_occurrence (
    person_id,
    procedure_concept_id,
    procedure_date,
    procedure_datetime,
    procedure_end_date,
    procedure_end_datetime,
    procedure_type_concept_id,
    modifier_concept_id,
    quantity,
    provider_id,
    visit_occurrence_id,
    visit_detail_id,
    procedure_source_value,
    procedure_source_concept_id,
    modifier_source_value
)
SELECT
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
    pm.provider_id                                                     AS provider_id,
    {{ visit_occurrence_id_expr }}                                     AS visit_occurrence_id,
    NULL::INTEGER                                                      AS visit_detail_id,
    LEFT(COALESCE(procedures.px::VARCHAR, ''), 50)::VARCHAR(50)        AS procedure_source_value,
    srctosrcvm.source_concept_id::INTEGER                              AS procedure_source_concept_id,
    NULL::VARCHAR(50)                                                  AS modifier_source_value
FROM {{ pcornet_db }}.{{ pcornet_schema }}.{{ procedure_table }} procedures
LEFT JOIN {{ cdm_db }}.{{ cdm_schema }}.provider_id_map pm
  ON pm.providerid_source = procedures.providerid
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
 WHERE COALESCE(procedures.px_date, procedures.admit_date) IS NOT NULL;
 ;
