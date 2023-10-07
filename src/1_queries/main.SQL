-- auxiliary tables for FiO2, across 24h, 48h, 72h, 96h
WITH 
  fio2_24h AS (

  SELECT
    icu.subject_id
  , icu.stay_id
  , AVG(COALESCE(fio2,fio2_chartevents, NULL)) AS FiO2_mean_6_24h

  FROM `db_name.mimiciv_derived.icustay_detail` icu

  LEFT JOIN `physionet-data.mimiciv_derived.bg` 
  AS fio2_table
  ON fio2_table.subject_id = icu.subject_id

  WHERE TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) <= 1440 
  AND   TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) >= 360
  GROUP BY subject_id, stay_id
)
,  fio2_48h AS (

  SELECT
    icu.subject_id
  , icu.stay_id
  , AVG(COALESCE(fio2,fio2_chartevents, NULL)) AS FiO2_mean_24_48h

  FROM `db_name.mimiciv_derived.icustay_detail` icu

  LEFT JOIN `physionet-data.mimiciv_derived.bg` 
  AS fio2_table
  ON fio2_table.subject_id = icu.subject_id

  WHERE TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) <= 2*1440 
  AND   TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) >  1440
  GROUP BY subject_id, stay_id
)
,  fio2_72h AS (

  SELECT
    icu.subject_id
  , icu.stay_id
  , AVG(COALESCE(fio2,fio2_chartevents, NULL)) AS FiO2_mean_48_72h

  FROM `db_name.mimiciv_derived.icustay_detail` icu

  LEFT JOIN `physionet-data.mimiciv_derived.bg` 
  AS fio2_table
  ON fio2_table.subject_id = icu.subject_id

  WHERE TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) <= 3*1440 
  AND   TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) >  2*1440
  GROUP BY subject_id, stay_id
)
,  fio2_96h AS (

  SELECT
    icu.subject_id
  , icu.stay_id
  , AVG(COALESCE(fio2,fio2_chartevents, NULL)) AS FiO2_mean_72_96h

  FROM `db_name.mimiciv_derived.icustay_detail` icu

  LEFT JOIN `physionet-data.mimiciv_derived.bg` 
  AS fio2_table
  ON fio2_table.subject_id = icu.subject_id

  WHERE TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) <= 4*1440 
  AND   TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) >  3*1440
  GROUP BY subject_id, stay_id
)
-- auxiliary table for fluids, overall
, fluids_table AS (
    SELECT
      ce.stay_id
    , SUM(amount) AS fluids_volume
    , SUM(amount)/MAX(icu.los_icu) AS fluids_volume_norm_by_los_icu
    , MAX(icu.los_icu) AS los_icu

    FROM  `physionet-data.mimiciv_icu.inputevents` ce

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = ce.stay_id

    WHERE itemid IN (220952,225158,220954,220955,220958,220960,220961,220962,221212,221213,220861,220863)
    AND amount is NOT NULL
    AND amount > 0 
    AND icu.los_icu > 0
    GROUP BY stay_id
)
-- auxiliary tables for fluids, across 24h, 48h, 72h, 96h
, fluids_24h AS (
    SELECT
      ce.stay_id
    , SUM(amount) AS fluids_6_24h

    FROM  `physionet-data.mimiciv_icu.inputevents` ce

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = ce.stay_id

    WHERE itemid IN (220952,225158,220954,220955,220958,220960,220961,220962,221212,221213,220861,220863)
    AND amount is NOT NULL
    AND amount > 0 
    AND icu.los_icu > 0
    AND TIMESTAMP_DIFF(ce.starttime, icu.admittime, MINUTE) <= 1440 
    AND TIMESTAMP_DIFF(ce.starttime, icu.admittime, MINUTE) >= 360
    GROUP BY stay_id
)

, fluids_48h AS (
    SELECT
      ce.stay_id
    , SUM(amount) AS fluids_24_48h

    FROM  `physionet-data.mimiciv_icu.inputevents` ce

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = ce.stay_id

    WHERE itemid IN (220952,225158,220954,220955,220958,220960,220961,220962,221212,221213,220861,220863)
    AND amount is NOT NULL
    AND amount > 0 
    AND icu.los_icu > 0
    AND TIMESTAMP_DIFF(ce.starttime, icu.admittime, MINUTE) <= 2*1440 
    AND TIMESTAMP_DIFF(ce.starttime, icu.admittime, MINUTE) >  1440
    GROUP BY stay_id
)

, fluids_72h AS (
    SELECT
      ce.stay_id
    , SUM(amount) AS fluids_48_72h

    FROM  `physionet-data.mimiciv_icu.inputevents` ce

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = ce.stay_id

    WHERE itemid IN (220952,225158,220954,220955,220958,220960,220961,220962,221212,221213,220861,220863)
    AND amount is NOT NULL
    AND amount > 0 
    AND icu.los_icu > 0
    AND TIMESTAMP_DIFF(ce.starttime, icu.admittime, MINUTE) <= 3*1440 
    AND TIMESTAMP_DIFF(ce.starttime, icu.admittime, MINUTE) >  2*1440
    GROUP BY stay_id
)

, fluids_96h AS (
    SELECT
      ce.stay_id
    , SUM(amount) AS fluids_72_96h

    FROM  `physionet-data.mimiciv_icu.inputevents` ce

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = ce.stay_id

    WHERE itemid IN (220952,225158,220954,220955,220958,220960,220961,220962,221212,221213,220861,220863)
    AND amount is NOT NULL
    AND amount > 0 
    AND icu.los_icu > 0
    AND TIMESTAMP_DIFF(ce.starttime, icu.admittime, MINUTE) <= 4*1440 
    AND TIMESTAMP_DIFF(ce.starttime, icu.admittime, MINUTE) >  3*1440
    GROUP BY stay_id
)

-- auxiliary tables for urine outputs across 24h, 48h, 72h, 96h, note project id appeared to be hardcoded so swapped out for db_name in icu

, uo_24h AS (
    SELECT
      uor.stay_id
    , MAX(urineoutput_24hr) AS uo_6_24h
    
    FROM  `physionet-data.mimiciv_derived.urine_output_rate`  AS uor

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = uor.stay_id

    WHERE urineoutput_24hr is NOT NULL
    AND icu.los_icu > 0
    AND TIMESTAMP_DIFF(uor.charttime, icu.admittime, MINUTE) <= 1440 
    AND TIMESTAMP_DIFF(uor.charttime, icu.admittime, MINUTE) >= 360
    GROUP BY stay_id
)

, uo_48h AS (
    SELECT
      uor.stay_id
    , MAX(urineoutput_24hr) AS uo_24_48h

    FROM  `physionet-data.mimiciv_derived.urine_output_rate`  AS uor

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = uor.stay_id

    WHERE urineoutput_24hr is NOT NULL
    AND icu.los_icu > 0
    AND TIMESTAMP_DIFF(uor.charttime, icu.admittime, MINUTE) <= 2*1440 
    AND TIMESTAMP_DIFF(uor.charttime, icu.admittime, MINUTE) >  1440
    GROUP BY stay_id
)

, uo_72h AS (
    SELECT
      uor.stay_id
    , MAX(urineoutput_24hr) AS uo_48_72h

    FROM  `physionet-data.mimiciv_derived.urine_output_rate`  AS uor

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = uor.stay_id

    WHERE urineoutput_24hr is NOT NULL
    AND icu.los_icu > 0
    AND TIMESTAMP_DIFF(uor.charttime, icu.admittime, MINUTE) <= 3*1440 
    AND TIMESTAMP_DIFF(uor.charttime, icu.admittime, MINUTE) >  2*1440
    GROUP BY stay_id
)

, uo_96h AS (
    SELECT
      uor.stay_id
    , MAX(urineoutput_24hr) AS uo_72_96h

    FROM  `physionet-data.mimiciv_derived.urine_output_rate`  AS uor

    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = uor.stay_id

    WHERE urineoutput_24hr is NOT NULL
    AND icu.los_icu > 0
    AND TIMESTAMP_DIFF(uor.charttime, icu.admittime, MINUTE) <= 4*1440 
    AND TIMESTAMP_DIFF(uor.charttime, icu.admittime, MINUTE) >  3*1440
    GROUP BY stay_id
)

-- auxiliary table for labs, custom because are not in the derived ones!
, labs_24h AS (
  SELECT lab.hadm_id,
  MIN(
      CASE
      WHEN lab.itemid IN (50909) THEN valuenum
      ELSE NULL
      END) AS cortisol_min,

  MIN(
      CASE
      WHEN lab.itemid IN (50811, 51222) THEN valuenum
      ELSE NULL
      END) AS hemoglobin_min

  FROM `physionet-data.mimiciv_hosp.labevents` AS lab
  LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
  ON icu.hadm_id = lab.hadm_id
  WHERE itemid IN (50909, 50811, 51222)
  AND TIMESTAMP_DIFF(lab.charttime, icu.admittime, MINUTE) <= 1440 
  AND TIMESTAMP_DIFF(lab.charttime, icu.admittime, MINUTE) >= 360
  GROUP BY hadm_id
)

, labs_48h AS (
  SELECT lab.hadm_id,
  MIN(
      CASE
      WHEN lab.itemid IN (50909) THEN valuenum
      ELSE NULL
      END) AS cortisol_min,

  MIN(
      CASE
      WHEN lab.itemid IN (50811, 51222) THEN valuenum
      ELSE NULL
      END) AS hemoglobin_min

  FROM `physionet-data.mimiciv_hosp.labevents` AS lab
  LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
  ON icu.hadm_id = lab.hadm_id
  WHERE itemid IN (50909, 50811, 51222)
  AND TIMESTAMP_DIFF(lab.charttime, icu.admittime, MINUTE) <= 2*1440 
  AND TIMESTAMP_DIFF(lab.charttime, icu.admittime, MINUTE) >  1440
  GROUP BY hadm_id
)

, labs_72h AS (
  SELECT lab.hadm_id,
  MIN(
      CASE
      WHEN lab.itemid IN (50909) THEN valuenum
      ELSE NULL
      END) AS cortisol_min,

  MIN(
      CASE
      WHEN lab.itemid IN (50811, 51222) THEN valuenum
      ELSE NULL
      END) AS hemoglobin_min

  FROM `physionet-data.mimiciv_hosp.labevents` AS lab
  LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
  ON icu.hadm_id = lab.hadm_id
  WHERE itemid IN (50909, 50811, 51222)
  AND TIMESTAMP_DIFF(lab.charttime, icu.admittime, MINUTE) <= 3*1440 
  AND TIMESTAMP_DIFF(lab.charttime, icu.admittime, MINUTE) >  2*1440
  GROUP BY hadm_id
)

, labs_96h AS (
  SELECT lab.hadm_id,
  MIN(
      CASE
      WHEN lab.itemid IN (50909) THEN valuenum
      ELSE NULL
      END) AS cortisol_min,

  MIN(
      CASE
      WHEN lab.itemid IN (50811, 51222) THEN valuenum
      ELSE NULL
      END) AS hemoglobin_min

  FROM `physionet-data.mimiciv_hosp.labevents` AS lab
  LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
  ON icu.hadm_id = lab.hadm_id
  WHERE itemid IN (50909, 50811, 51222)
  AND TIMESTAMP_DIFF(lab.charttime, icu.admittime, MINUTE) <= 4*1440 
  AND TIMESTAMP_DIFF(lab.charttime, icu.admittime, MINUTE) >  3*1440 
  GROUP BY hadm_id
)

SELECT 
-- icu details
    icu.subject_id
  , icu.stay_id
  , icu.hadm_id
  , icu.los_icu
  , icu.los_hospital
  , icu.admittime AS hosp_intime
  , icu.dischtime AS hosp_outtime
  , icu.icu_intime
  , icu.icu_outtime
  , icu.hospstay_seq
  , icu.icustay_seq
  , icu.dod
  , CASE WHEN s3.sepsis3 IS TRUE THEN 1 ELSE 0 END AS sepsis3

-- baseline clinical and demographics vars
  , pat.anchor_year_group
  , icu.admission_age
  , icu.gender
  , CASE WHEN icu.gender = "F" THEN 1 ELSE 0 END AS sex_female
  , icu.race
  , CASE 
      WHEN (
         LOWER(icu.race) LIKE "%white%"
      OR LOWER(icu.race) LIKE "%portuguese%" 
      OR LOWER(icu.race) LIKE "%caucasian%" 
      ) THEN "White"
      WHEN (
         LOWER(icu.race) LIKE "%black%"
      OR LOWER(icu.race) LIKE "%african american%"
      ) THEN "Black"
      WHEN (
         LOWER(icu.race) LIKE "%hispanic%"
      OR LOWER(icu.race) LIKE "%south american%" 
      ) THEN "Hispanic"
      WHEN (
         LOWER(icu.race) LIKE "%asian%"
      ) THEN "Asian"
      ELSE "Other"
    END AS race_group

  , weight.weight_admit
  , charlson.charlson_comorbidity_index
  , ad.language
  , CASE WHEN ad.language = "ENGLISH" THEN 1 ELSE 0 END AS eng_prof
  , ad.insurance
  , CASE WHEN ad.insurance = "Other" THEN 1 ELSE 0 END AS private_insurance
  , adm.adm_type
  , adm.adm_elective
  , major_surgery

-- illness severity - admission
  , oa.oasis
  , oa.oasis_prob AS prob_mort
  , sf.sofa AS SOFA_admit
  , sf.respiration AS respiratory_admit
  , sf.coagulation AS coagulation_admit
  , sf.liver AS liver_admit
  , sf.cardiovascular AS cardiovascular_admit
  , sf.cns AS cns_admit
  , sf.renal AS renal_admit

-- SOFA and components - day 1
  , sofa1.sofa_24hours            AS sofa_max_0_24h
  , sofa1.respiration_24hours     AS respiratory_max_0_24h
  , sofa1.coagulation_24hours     AS coagulation_max_0_24h
  , sofa1.liver_24hours           AS liver_max_0_24h
  , sofa1.cardiovascular_24hours  AS cardiovascular_max_0_24h
  , sofa1.cns_24hours             AS cns_max_0_24h
  , sofa1.renal_24hours           AS renal_max_0_24h

-- SOFA and components - day 2
  , sofa2.sofa_24hours            AS sofa_max_24_48h
  , sofa2.respiration_24hours     AS respiratory_max_24_48h
  , sofa2.coagulation_24hours     AS coagulation_max_24_48h
  , sofa2.liver_24hours           AS liver_max_24_48h
  , sofa2.cardiovascular_24hours  AS cardiovascular_max_24_48h
  , sofa2.cns_24hours             AS cns_max_24_48h
  , sofa2.renal_24hours           AS renal_max_24_48h

-- SOFA and components - day 3
  , sofa3.sofa_24hours            AS sofa_max_48_72h
  , sofa3.respiration_24hours     AS respiratory_max_48_72h
  , sofa3.coagulation_24hours     AS coagulation_max_48_72h
  , sofa3.liver_24hours           AS liver_max_48_72h
  , sofa3.cardiovascular_24hours  AS cardiovascular_max_48_72h
  , sofa3.cns_24hours             AS cns_max_48_72h
  , sofa3.renal_24hours           AS renal_max_48_72h

-- SOFA and components - day 4
  , sofa4.sofa_24hours            AS sofa_max_72_96h
  , sofa4.respiration_24hours     AS respiratory_max_72_96h
  , sofa4.coagulation_24hours     AS coagulation_max_72_96h
  , sofa4.liver_24hours           AS liver_max_72_96h
  , sofa4.cardiovascular_24hours  AS cardiovascular_max_72_96h
  , sofa4.cns_24hours             AS cns_max_72_96h
  , sofa4.renal_24hours           AS renal_max_72_96h

-- FiO2 per day
  , fio2_24h.FiO2_mean_6_24h
  , fio2_48h.FiO2_mean_24_48h
  , fio2_72h.FiO2_mean_48_72h
  , fio2_96h.FiO2_mean_72_96h

-- fluids - per day
  , fluids_24h.fluids_6_24h
  , fluids_48h.fluids_24_48h
  , fluids_72h.fluids_48_72h
  , fluids_96h.fluids_72_96h

-- urine volumes - per day
  , uo_24h.uo_6_24h
  , uo_48h.uo_24_48h
  , uo_72h.uo_48_72h
  , uo_96h.uo_72_96h

-- treatments - overall
  , fluids_volume
  , fluids_volume_norm_by_los_icu
  , transfusion_yes
  , insulin_yes

  , InvasiveVent.InvasiveVent_hr
  , Oxygen.Oxygen_hr
  , HighFlow.HighFlow_hr
  , NonInvasiveVent.NonInvasiveVent_hr
  , Trach.Trach_hr

  , CASE
    WHEN (InvasiveVent.InvasiveVent_hr IS NOT NULL OR Trach.Trach_hr IS NOT NULL)
    THEN 1
    ELSE 0
  END AS mech_vent_overall

  , CASE WHEN rrt.rrt = 1 THEN 1 ELSE 0 END AS rrt_overall
  , CASE WHEN (pressor.stay_id = icu.stay_id) IS TRUE THEN 1 ELSE 0 END AS vasopressor_overall

  , MV_time_hr/24 AS MV_time_abs
  , vp_time_hr/24 AS VP_time_abs
  , MV_time_hr/24/icu.los_icu AS MV_time_perc_of_stay
  , vp_time_hr/24/icu.los_icu AS VP_time_perc_of_stay

-- initiation offsets
  , CASE
    WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR)/24/icu.los_icu
    WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS MV_init_offset_perc

  , CASE
    WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR)/24
    WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS MV_init_offset_abs

  , CASE
    WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR)/24/icu.los_icu
    WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS RRT_init_offset_perc
  , CASE
    WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR)/24
    WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS RRT_init_offset_abs

  , CASE
    WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR)/24/icu.los_icu
    WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS VP_init_offset_perc

  , CASE
    WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) >= 0
    THEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR)/24
    WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) < 0
    THEN 0
    ELSE NULL
  END AS VP_init_offset_abs

-- vital signs - day 1
  , vital_day1.resp_rate_mean AS resp_rate_mean_6_24h
  , vital_day1.mbp_mean AS mbp_mean_6_24h
  , vital_day1.heart_rate_mean AS heart_rate_mean_6_24h
  , vital_day1.temperature_mean AS temperature_mean_6_24h
  , vital_day1.spo2_mean AS spo2_mean_6_24h

-- vital signs - day 2
  , vital_day2.resp_rate_mean AS resp_rate_mean_24_48h
  , vital_day2.mbp_mean AS mbp_mean_24_48h
  , vital_day2.heart_rate_mean AS heart_rate_mean_24_48h
  , vital_day2.temperature_mean AS temperature_mean_24_48h
  , vital_day2.spo2_mean AS spo2_mean_24_48h

-- vital signs - day 3
  , vital_day3.resp_rate_mean AS resp_rate_mean_48_72h
  , vital_day3.mbp_mean AS mbp_mean_48_72h
  , vital_day3.heart_rate_mean AS heart_rate_mean_48_72h
  , vital_day3.temperature_mean AS temperature_mean_48_72h
  , vital_day3.spo2_mean AS spo2_mean_48_72h

-- vital signs - day 4
  , vital_day4.resp_rate_mean AS resp_rate_mean_72_96h
  , vital_day4.mbp_mean AS mbp_mean_72_96h
  , vital_day4.heart_rate_mean AS heart_rate_mean_72_96h
  , vital_day4.temperature_mean AS temperature_mean_72_96h
  , vital_day4.spo2_mean AS spo2_mean_72_96h

-- lab values - day 1
  , bg_art_day1.po2_min AS po2_min_6_24h
  , bg_art_day1.pco2_max AS pco2_max_6_24h
  , bg_day1.ph_min AS ph_min_6_24h
  , bg_day1.lactate_max AS lactate_max_6_24h
  , lab_day1.glucose_max AS glucose_max_6_24h
  , lab_day1.sodium_min AS sodium_min_6_24h
  , lab_day1.potassium_max AS potassium_max_6_24h
  , lab_day1.fibrinogen_min AS fibrinogen_min_6_24h
  , lab_day1.inr_max AS inr_max_6_24h
  , labs_24h.cortisol_min AS cortisol_min_6_24h
  , labs_24h.hemoglobin_min AS hemoglobin_min_6_24h
-- sens. analyses
  , bg_art_day1.pco2_min AS pco2_min_6_24h
  , lab_day1.potassium_min AS potassium_min_6_24h
  , bg_day1.ph_max AS ph_max_6_24h
  , bg_day1.bicarbonate_max AS bicarbonate_max_6_24h
  , bg_day1.lactate_min AS lactate_min_6_24h
  , bg_day1.pao2fio2ratio_avg AS pf_6_24h

-- lab values - day 2
  , bg_art_day2.po2_min AS po2_min_24_48h
  , bg_art_day2.pco2_max AS pco2_max_24_48h
  , bg_day2.ph_min AS ph_min_24_48h
  , bg_day2.lactate_max AS lactate_max_24_48h
  , lab_day2.glucose_max AS glucose_max_24_48h
  , lab_day2.sodium_min AS sodium_min_24_48h
  , lab_day2.potassium_max AS potassium_max_24_48h
  , lab_day2.fibrinogen_min AS fibrinogen_min_24_48h
  , lab_day2.inr_max AS inr_max_24_48h
  , labs_48h.cortisol_min AS cortisol_min_24_48h
  , labs_48h.hemoglobin_min AS hemoglobin_min_24_48h
-- sens. analyses
  , bg_art_day2.pco2_min AS pco2_min_24_48h
  , lab_day2.potassium_min AS potassium_min_24_48h
  , bg_day2.ph_max AS ph_max_24_48h
  , bg_day2.bicarbonate_max AS bicarbonate_max_24_48h
  , bg_day2.lactate_min AS lactate_min_24_48h
  , bg_day2.pao2fio2ratio_avg AS pf_24_48h

-- lab values - day 3
  , bg_art_day3.po2_min AS po2_min_48_72h
  , bg_art_day3.pco2_max AS pco2_max_48_72h
  , bg_day3.ph_min AS ph_min_48_72h
  , bg_day3.lactate_max AS lactate_max_48_72h
  , lab_day3.glucose_max AS glucose_max_48_72h
  , lab_day3.sodium_min AS sodium_min_48_72h
  , lab_day3.potassium_max AS potassium_max_48_72h
  , lab_day3.fibrinogen_min AS fibrinogen_min_48_72h
  , lab_day3.inr_max AS inr_max_48_72h
  , labs_72h.cortisol_min AS cortisol_min_48_72h
  , labs_72h.hemoglobin_min AS hemoglobin_min_48_72h
-- sens. analyses
  , bg_art_day3.pco2_min AS pco2_min_48_72h
  , lab_day3.potassium_min AS potassium_min_48_72h
  , bg_day3.ph_max AS ph_max_48_72h
  , bg_day3.bicarbonate_max AS bicarbonate_max_48_72h
  , bg_day3.lactate_min AS lactate_min_48_72h
  , bg_day3.pao2fio2ratio_avg AS pf_48_72h

-- lab values - day 4
  , bg_art_day4.po2_min AS po2_min_72_96h
  , bg_art_day4.pco2_max AS pco2_max_72_96h
  , bg_day4.ph_min AS ph_min_72_96h
  , bg_day4.lactate_max AS lactate_max_72_96h
  , lab_day4.glucose_max AS glucose_max_72_96h
  , lab_day4.sodium_min AS sodium_min_72_96h
  , lab_day4.potassium_max AS potassium_max_72_96h
  , lab_day4.fibrinogen_min AS fibrinogen_min_72_96h
  , lab_day4.inr_max AS inr_max_72_96h
  , labs_96h.cortisol_min AS cortisol_min_72_96h
  , labs_96h.hemoglobin_min AS hemoglobin_min_72_96h
-- sens. analyses
  , bg_art_day4.pco2_min AS pco2_min_72_96h
  , lab_day4.potassium_min AS potassium_min_72_96h
  , bg_day4.ph_max AS ph_max_72_96h
  , bg_day4.bicarbonate_max AS bicarbonate_max_72_96h
  , bg_day4.lactate_min AS lactate_min_72_96h
  , bg_day4.pao2fio2ratio_avg AS pf_72_96h

-- comorbidites
  , hypertension_present
  , heart_failure_present
  , copd_present
  , asthma_present
  , cad_present
  , ckd_stages
  , diabetes_types
  , connective_disease

-- origin of infection
  , pneumonia
  , uti
  , biliary
  , skin
  
-- hospital complications
  , clabsi
  , cauti
  , ssi
  , vap

-- code
  , first_code
  , last_code
  , CASE
      WHEN codes.first_code IS NULL
        OR codes.first_code = "Full code" 
      THEN 1
      ELSE 0
    END AS is_full_code_admission
  
  , CASE
      WHEN codes.last_code IS NULL
        OR codes.last_code = "Full code" 
      THEN 1
      ELSE 0
    END AS is_full_code_discharge

-- outcome
  , ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) as dod_icuout_offset

  , CASE WHEN (
         discharge_location = "DIED"
      OR discharge_location = "HOSPICE"
  ) THEN 1
    ELSE 0
  END AS mortality_in

  , CASE WHEN (
         discharge_location = "DIED"
      OR discharge_location = "HOSPICE"
      OR ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) <= 90
  ) THEN 1
    ELSE 0
  END AS mortality_90

FROM `physionet-data.mimiciv_derived.icustay_detail`
AS icu

-- Sepsis Patients
LEFT JOIN physionet-data.mimiciv_derived.sepsis3
AS s3
ON s3.stay_id = icu.stay_id

LEFT JOIN `physionet-data.mimiciv_hosp.patients` as pat
on icu.subject_id = pat.subject_id

LEFT JOIN `physionet-data.mimiciv_hosp.admissions` as ad
on icu.hadm_id = ad.hadm_id

LEFT JOIN `physionet-data.mimiciv_derived.first_day_sofa` as sf
on icu.stay_id = sf.stay_id 

LEFT JOIN `physionet-data.mimiciv_derived.first_day_weight` as weight
on icu.stay_id = weight.stay_id 

LEFT JOIN `physionet-data.mimiciv_derived.charlson` as charlson
on icu.hadm_id = charlson.hadm_id 

LEFT JOIN `physionet-data.mimiciv_derived.first_day_urine_output` as fd_uo
on icu.stay_id = fd_uo.stay_id 

-- rrt
LEFT JOIN (select distinct stay_id, dialysis_present as rrt  from `physionet-data.mimiciv_derived.rrt` WHERE dialysis_present = 1) as rrt
on icu.stay_id = rrt.stay_id 

-- RRT initiation offset
LEFT JOIN (
  SELECT dia.stay_id,
  MAX(dialysis_present) AS rrt,
  MIN(charttime) AS charttime
  FROM `physionet-data.mimiciv_derived.rrt` dia
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = dia.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, charttime, HOUR) > 0 -- to make sure it's within the ICU stay
  AND TIMESTAMP_DIFF(charttime, icu.icu_intime, HOUR) > 0
  WHERE dialysis_present = 1
  GROUP BY stay_id
) AS rrt_time
ON icu.stay_id = rrt_time.stay_id 

-- vasopressors
LEFT JOIN (select distinct stay_id from  `physionet-data.mimiciv_derived.epinephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.norepinephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.phenylephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.vasopressin`) as pressor
on icu.stay_id = pressor.stay_id 

-- for VP percentage of stay
LEFT JOIN(
  SELECT
    nor.stay_id
    , SUM(TIMESTAMP_DIFF(endtime, starttime, HOUR)) AS vp_time_hr
  FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose` nor
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = nor.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  GROUP BY stay_id
) AS vp_time
ON vp_time.stay_id = icu.stay_id

-- VPs offset initiation
LEFT JOIN(
  SELECT
    nor.stay_id
    , MIN(starttime) AS starttime
  FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose` nor
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = nor.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  GROUP BY stay_id
) AS vp_mtime
ON vp_mtime.stay_id = icu.stay_id

LEFT JOIN (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as InvasiveVent_hr
FROM `physionet-data.mimiciv_derived.ventilation` WHERE ventilation_status = "InvasiveVent" GROUP BY stay_id) as InvasiveVent
on InvasiveVent.stay_id = icu.stay_id

LEFT JOIN (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as Oxygen_hr
FROM `physionet-data.mimiciv_derived.ventilation` WHERE ventilation_status = "Oxygen" GROUP BY stay_id) as Oxygen
on Oxygen.stay_id = icu.stay_id

LEFT JOIN (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as HighFlow_hr
FROM `physionet-data.mimiciv_derived.ventilation` WHERE ventilation_status = "HighFlow" GROUP BY stay_id) as HighFlow
on HighFlow.stay_id = icu.stay_id

LEFT JOIN (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as NonInvasiveVent_hr
FROM `physionet-data.mimiciv_derived.ventilation` WHERE ventilation_status = "NonInvasiveVent" GROUP BY stay_id) as NonInvasiveVent
on NonInvasiveVent.stay_id = icu.stay_id

LEFT JOIN (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as Trach_hr
FROM `physionet-data.mimiciv_derived.ventilation` WHERE ventilation_status = "Trach" GROUP BY stay_id) as Trach
on Trach.stay_id = icu.stay_id

-- for MV perc of stay
LEFT JOIN (
  SELECT vent.stay_id,
  SUM(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as MV_time_hr
  FROM `physionet-data.mimiciv_derived.ventilation` vent
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = vent.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  WHERE (ventilation_status = "Trach" OR ventilation_status = "InvasiveVent")
  GROUP BY stay_id
) AS mv_time
ON mv_time.stay_id = icu.stay_id

-- for MV initation offset 
LEFT JOIN (
  SELECT vent.stay_id, MIN(starttime) as starttime
  FROM `physionet-data.mimiciv_derived.ventilation` vent
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = vent.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  WHERE (ventilation_status = "Trach" OR ventilation_status = "InvasiveVent")
  GROUP BY stay_id
)
AS mv_mtime
ON mv_mtime.stay_id = icu.stay_id

-- Add admission type
-- Mapping: 
-- Emergency: ‘AMBULATORY OBSERVATION’, ‘DIRECT EMER.’, ‘URGENT’, ‘EW EMER.’, ‘DIRECT OBSERVATION’, ‘EU OBSERVATION’, ‘OBSERVATION ADMIT’
-- Elective: ‘ELECTIVE’, ‘SURGICAL SAME DAY ADMISSION’

LEFT JOIN (SELECT hadm_id, admission_type as adm_type,
CASE
    WHEN (admission_type LIKE "%ELECTIVE%" OR
     admission_type LIKE "%SURGICAL SAME DAY ADMISSION%") 
     THEN 1
     ELSE 0
     END AS adm_elective
FROM `physionet-data.mimiciv_hosp.admissions`) as adm
on adm.hadm_id = icu.hadm_id

-- Add OASIS Score
LEFT JOIN (SELECT stay_id, oasis, oasis_prob
FROM `physionet-data.mimiciv_derived.oasis`) as oa
on oa.stay_id = icu.stay_id

-- Add Transfusions
LEFT JOIN (
SELECT ce.stay_id --, amount --, valueuom --itemid
, max(
    CASE
    WHEN ce.itemid IN ( 226368, 227070, 220996, 221013,226370) THEN 1
    ELSE 0
    END) AS transfusion_yes
FROM  `physionet-data.mimiciv_icu.inputevents` ce
WHERE itemid IN (226368, 227070, 220996, 221013, 226370) 
and amount is NOT NULL and amount >0 
GROUP BY stay_id
)
AS ce
ON ce.stay_id = icu.stay_id

-- Add insulin transfusion
LEFT JOIN (
SELECT cee.stay_id --, amount --, valueuom --itemid
, max(
    CASE
    WHEN cee.itemid IN (223257, 223258, 223259, 223260, 223261, 223262, 229299, 229619) THEN 1
    ELSE 0
    END) AS insulin_yes
FROM  `physionet-data.mimiciv_icu.inputevents` cee
WHERE itemid IN (223257, 223258, 223259, 223260, 223261, 223262, 229299, 229619)
and amount is NOT NULL and amount > 0 
GROUP BY stay_id
)
AS cee
ON cee.stay_id = icu.stay_id

-- Add Lab from original table
-- minimal whole stay cortisol and hemoglobin
LEFT JOIN (
SELECT hadm_id,
MIN(
    CASE
    WHEN lab.itemid IN (50909) THEN valuenum
    ELSE NULL
    END) AS cortisol_min,

MIN(
    CASE
    WHEN lab.itemid IN (50811, 51222) THEN valuenum
    ELSE NULL
    END) AS hemoglobin_min

FROM `physionet-data.mimiciv_hosp.labevents` AS lab
WHERE itemid IN (50909, 50811, 51222)
GROUP BY hadm_id
)
AS lab
ON lab.hadm_id = icu.hadm_id

-- Add Code
LEFT JOIN (
  SELECT
      stay_id
    , first_code
    , last_code
  FROM `db_name.my_MIMIC.pivoted_codes`
) AS codes
ON codes.stay_id = icu.stay_id

-- Add major surgery based on Alistair's OASIS implementation
LEFT JOIN (
 
 WITH surgflag as (
 SELECT ie.stay_id
        , MAX(CASE
            WHEN LOWER(curr_service) LIKE '%surg%' THEN 1
            WHEN curr_service = 'ORTHO' THEN 1
            ELSE NULL END) AS major_surgery
        
        , MAX(CASE
            WHEN first_careunit LIKE  "%SICU%" AND
            first_careunit NOT LIKE "%MICU/SICU%"  THEN 1
            ELSE NULL END) AS surgical_icu

    FROM mimiciv_icu.icustays ie

    LEFT JOIN mimiciv_hosp.services se
        ON ie.hadm_id = se.hadm_id
        AND se.transfertime < DATETIME_ADD(ie.intime, INTERVAL '2' DAY)
    GROUP BY ie.stay_id
 )  
  SELECT *
  FROM surgflag
  WHERE major_surgery = 1 OR surgical_icu = 1
) 
AS ms
ON ms.stay_id = icu.stay_id

-- Add comorbidities, conditions present on admission, and complications
LEFT JOIN `db_name.my_MIMIC.pivoted_comorbidities` AS com
ON com.hadm_id = icu.hadm_id

-- Add fluids' volume
LEFT JOIN fluids_table
ON fluids_table.stay_id = icu.stay_id

-- Add fluids per day
LEFT JOIN fluids_24h
ON fluids_24h.stay_id = icu.stay_id
LEFT JOIN fluids_48h
ON fluids_48h.stay_id = icu.stay_id
LEFT JOIN fluids_72h
ON fluids_72h.stay_id = icu.stay_id
LEFT JOIN fluids_96h
ON fluids_96h.stay_id = icu.stay_id

-- Add urine output per day
LEFT JOIN uo_24h
ON uo_24h.stay_id = icu.stay_id
LEFT JOIN uo_48h
ON uo_48h.stay_id = icu.stay_id
LEFT JOIN uo_72h
ON uo_72h.stay_id = icu.stay_id
LEFT JOIN uo_96h
ON uo_96h.stay_id = icu.stay_id

-- Add FiO2 per day
LEFT JOIN fio2_24h
ON fio2_24h.stay_id = icu.stay_id
LEFT JOIN fio2_48h
ON fio2_48h.stay_id = icu.stay_id
LEFT JOIN fio2_72h
ON fio2_72h.stay_id = icu.stay_id
LEFT JOIN fio2_96h
ON fio2_96h.stay_id = icu.stay_id

-- Add SOFA per day
LEFT JOIN `db_name.mimiciv_derived.sofa`
AS sofa1
ON sofa1.stay_id = icu.stay_id
AND sofa1.hr = 24

LEFT JOIN `db_name.mimiciv_derived.sofa`
AS sofa2
ON sofa2.stay_id = icu.stay_id
AND sofa2.hr = 48

LEFT JOIN `db_name.mimiciv_derived.sofa`
AS sofa3
ON sofa3.stay_id = icu.stay_id
AND sofa3.hr = 72

LEFT JOIN `db_name.mimiciv_derived.sofa`
AS sofa4
ON sofa4.stay_id = icu.stay_id
AND sofa4.hr = 96

-- Add labs per day
LEFT JOIN `db_name.mimiciv_sepsisTx.lab_day1`
AS lab_day1
ON lab_day1.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.lab_day2`
AS lab_day2
ON lab_day2.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.lab_day3`
AS lab_day3
ON lab_day3.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.lab_day4`
AS lab_day4
ON lab_day4.stay_id = icu.stay_id

-- Add custom labs
LEFT JOIN labs_24h
ON labs_24h.hadm_id = icu.hadm_id
LEFT JOIN labs_48h
ON labs_48h.hadm_id = icu.hadm_id
LEFT JOIN labs_72h
ON labs_72h.hadm_id = icu.hadm_id
LEFT JOIN labs_96h
ON labs_96h.hadm_id = icu.hadm_id

-- Add bg per day
LEFT JOIN `db_name.mimiciv_sepsisTx.bg_day1`
AS bg_day1
ON bg_day1.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.bg_day2`
AS bg_day2
ON bg_day2.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.bg_day3`
AS bg_day3
ON bg_day3.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.bg_day4`
AS bg_day4
ON bg_day4.stay_id = icu.stay_id

-- Add bg_art per day
LEFT JOIN `db_name.mimiciv_sepsisTx.bg_art_day1`
AS bg_art_day1
ON bg_art_day1.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.bg_art_day2`
AS bg_art_day2
ON bg_art_day2.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.bg_art_day3`
AS bg_art_day3
ON bg_art_day3.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.bg_art_day4`
AS bg_art_day4
ON bg_art_day4.stay_id = icu.stay_id

-- Add vital signs per day
LEFT JOIN `db_name.mimiciv_sepsisTx.vital_day1`
AS vital_day1
ON vital_day1.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.vital_day2`
AS vital_day2
ON vital_day2.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.vital_day3`
AS vital_day3
ON vital_day3.stay_id = icu.stay_id

LEFT JOIN `db_name.mimiciv_sepsisTx.vital_day4`
AS vital_day4
ON vital_day4.stay_id = icu.stay_id

WHERE icu.los_icu > 0

ORDER BY icu.subject_id, icu.hadm_id, icu.stay_id

