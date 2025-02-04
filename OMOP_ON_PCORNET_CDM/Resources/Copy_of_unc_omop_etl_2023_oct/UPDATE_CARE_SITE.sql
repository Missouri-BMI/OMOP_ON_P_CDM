WIP!!!!!!!!!!

-- update care_site_id in VISIT_OCCURRENCE table
use tracs_cdm;
update
	tracs_cdm.omop.visit_occurrence
set
	visit_occurrence.care_site_id = care_site.care_site_id
	--pat_enc.PAT_ENC_CSN_ID,
	--pat_enc.EFFECTIVE_DEPT_ID,
	--care_site.*

from 
	tracs_cdm.omop.visit_occurrence
	--tracs_cdm.omop.VISIT_OCCURRENCE
	join tracs_cdm.xomop.COHORT_OMOP on visit_occurrence.VISIT_OCCURRENCE_ID =  cohort_omop.visit_occurrence_id and  cohort_omop.PRIMARY_CSN_ID = cohort_omop.PAT_ENC_CSN_ID
	join clarity.dbo.pat_enc on cohort_omop.PAT_ENC_CSN_ID = pat_enc.PAT_ENC_CSN_ID
	join tracs_cdm.omop.CARE_SITE on pat_enc.EFFECTIVE_DEPT_ID = care_site.care_site_source_value


$$$$$$$$$$


update
	tracs_cdm.omop.visit_detail
set
	visit_detail.care_site_id = care_site.care_site_id
	--pat_enc.PAT_ENC_CSN_ID,
	--pat_enc.EFFECTIVE_DEPT_ID,
	--care_site.*

from 
	tracs_cdm.omop.visit_detail
	join tracs_cdm.xomop.COHORT_OMOP on visit_detail.VISIT_OCCURRENCE_ID =  cohort_omop.visit_occurrence_id --and  cohort_omop.PRIMARY_CSN_ID = cohort_omop.PAT_ENC_CSN_ID
	join clarity.dbo.pat_enc on cohort_omop.PAT_ENC_CSN_ID = pat_enc.PAT_ENC_CSN_ID
	join tracs_cdm.omop.CARE_SITE on pat_enc.EFFECTIVE_DEPT_ID = care_site.care_site_source_value


