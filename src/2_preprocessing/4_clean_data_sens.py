import pandas as pd
import numpy as np


def clean_data(cohort_number, hr_bound, treatment):

    data = pd.read_csv(f'data/main/MIMIC_coh_{cohort_number}_{treatment}.csv')

    # Start of Operations that in the main analysis are being done in the table1 script

    # Encode race_white as being white vs. non-white, note this will thow up incorrect number in summary tables for REG but doesn't matter for Language analysis
    data['race_white'] = data.race_group.apply(lambda x: "White" if x == "White" else "Racial-Ethnic Group")

    # Continuous Variables
    data['los_hosp_dead'] = data[data.mortality_in == 1].los_hospital
    data['los_hosp_surv'] = data[data.mortality_in == 0].los_hospital

    data['los_icu_dead'] = data[data.mortality_in == 1].los_icu
    data['los_icu_surv'] = data[data.mortality_in == 0].los_icu

    # Encode language as English proficiency or Limited English proficiency
    data['eng_prof'] = data['language'].apply(lambda x: "Limited" if x == '?' else "Proficient")

    # Create variable for receiving fluids, if fluid volume is not na
    data['fluids_overall'] = data['fluids_volume'].apply(lambda x: 1. if x > 0 else 0.)

    # Encode absolute durations and offsets into hours
    data['MV_time_abs_hours'] = data['MV_time_abs'] * 24
    data['VP_time_abs_hours'] = data['VP_time_abs'] * 24
    data['MV_init_offset_abs_hours'] = data['MV_init_offset_abs'] * 24
    data['RRT_init_offset_abs_hours'] = data['RRT_init_offset_abs'] * 24
    data['VP_init_offset_abs_hours'] = data['VP_init_offset_abs'] * 24

    # encode treatment according to elegibity window, hr_bound
    data['MV_elig']  = data['MV_init_offset_abs_hours'].apply(lambda x:  1 if (x < hr_bound) else 0)
    data['RRT_elig'] = data['RRT_init_offset_abs_hours'].apply(lambda x: 1 if (x < hr_bound) else 0)
    data['VP_elig']  = data['VP_init_offset_abs_hours'].apply(lambda x:  1 if (x < hr_bound) else 0)
        
    # Encode NA as 0, if missing means 0
    cols_na = ['major_surgery', 'insulin_yes', 'transfusion_yes', 'hypertension_present',
               'heart_failure_present', 'copd_present', 'asthma_present', 'cad_present',
               'ckd_stages', 'diabetes_types', 'connective_disease', 'pneumonia',
               'uti', 'biliary', 'skin']

    for c in cols_na:
        data[c] = data[c].fillna(0)

    # Encode diabetes and CKD 0 as "Absent"
    data['diabetes_types'] = data['diabetes_types'].apply(lambda x: "Absent" if x == 0 else x)
    data['ckd_stages'] = data['ckd_stages'].apply(lambda x: "Absent" if x == 0 else x)

    # End of the Operations that in the main analysis are being done in the table1 script


    # Get a column with the day when treatment was initiated
    # Among patients who were treated only, i.e, MV_elig == 1

    data['init_day'] = data.apply(lambda row: row[f'{treatment}_init_offset_abs_hours'] // 24 
                                  if row[f'{treatment}_elig'] == 1
                                  else np.nan,
                                  axis=1)

    hr_periods = ['6_24h', '24_48h', '48_72h', '72_96h']
    sf_periods = ['0_24h', '24_48h', '48_72h', '72_96h']

    sf_vars = ['sofa_max_0_24h', 'sofa_max_24_48h', 'sofa_max_48_72h', 'sofa_max_72_96h']

    # Get the day when the maximum SOFA score was reached, up to the cohort day
    sfs_look_for = sf_vars[:cohort_number]
    # get the column of SOFA with max value, and remove the prefix
    data['sofa_max_day'] = data[sfs_look_for].idxmax(axis=1).str.replace('sofa_max_', '')
    # get the index of the period, to map it to the hr_periods list
    data['sofa_max_day'] = data['sofa_max_day'].map(lambda x: 0
                                                    if pd.isnull(x)
                                                    else sf_periods.index(x))
    
    # create new variables depending on which day to consider
    # if no treatment -> day of max SOFA
    # if treatment -> day of treatment initiation

    # Variables that start at 6_24
    lb_vt = ['fluids', 'FiO2_mean',
             'resp_rate_mean', 'mbp_mean', 'temperature_mean',
             'spo2_mean', 'heart_rate_mean', 'po2_min', 'pco2_max', 'ph_min',
             'lactate_max', 'glucose_max', 'sodium_min', 'potassium_max',
             'cortisol_min', 'hemoglobin_min', 'fibrinogen_min', 'inr_max']

    for v in lb_vt:
        data[v] = data.apply(lambda row: row[v + '_' + hr_periods[row['sofa_max_day']]]
                                         if pd.isnull(row['init_day'])
                                         else row[v + '_' + hr_periods[int(row['init_day'])]],
                                         axis=1)
    
    # Variables that start at 0_24
    sf_vt = ['sofa_max', 'respiratory_max', 'coagulation_max', 'liver_max',
             'cardiovascular_max', 'cns_max', 'renal_max']
    
    for v in sf_vt:
        data[v] = data.apply(lambda row: row[v + '_' + sf_periods[row['sofa_max_day']]]
                                         if pd.isnull(row.init_day)
                                         else row[v + '_' + sf_periods[int(row['init_day'])]],
                                         axis=1)
    
    # Dictionary with Lower limit, Upper Limit, Normal Range for each of the labs
    lab_ranges = {'po2_min': [0, 90, 1000],
                  'pco2_max': [0, 40, 200],
                  'ph_min': [5, 7.35, 10],
                  'lactate_max': [0, 1.05, 30],
                  'glucose_max': [0, 95, 2000],
                  'sodium_min': [0, 140, 160],
                  'potassium_max': [0, 3.5, 9.9],
                  'cortisol_min': [0, 20, 70],
                  'fibrinogen_min': [0, 200, 1000],
                  'inr_max': [0, 1.1, 10],
                  'resp_rate_mean': [0, 15, 50],
                  'heart_rate_mean': [0, 90, 250],
                  'mbp_mean': [0, 85, 200],
                  'temperature_mean': [32, 36.5, 45],
                  'spo2_mean': [0, 95, 100]
    }

    # Replace 

    for lab in lab_ranges.keys():
        data[lab] = np.where(data[lab] < lab_ranges[lab][0], 0, data[lab])
        data[lab] = np.where(data[lab] > lab_ranges[lab][2], 0, data[lab])
        data[lab] = np.where(data[lab] == 0, lab_ranges[lab][1], data[lab])
        data[lab] = data[lab].fillna(lab_ranges[lab][1])

    data['hemoglobin_min'] = data['hemoglobin_min'].apply(lambda x: 0 if x < 3 else x)
    data['hemoglobin_min'] = data['hemoglobin_min'].apply(lambda x: 0 if x > 30 else x)
    data['hemoglobin_min'] = data['hemoglobin_min'].fillna(0)
    data['hemoglobin_min'] = data.apply(lambda row: 12 if (row.hemoglobin_min == 0) \
                                                            & (row.sex_female == 1) \
                                                          else row.hemoglobin_min, axis=1)
    
    data['hemoglobin_min'] = data.apply(lambda row: 13.5 if (row.hemoglobin_min == 0) \
                                                              & (row.sex_female == 0) \
                                                            else row.hemoglobin_min, axis=1)
        
    # impute SOFA as 0 if missing using apply lambda
    sofa_cols = sf_vt + \
                ['SOFA_admit', 'respiratory_admit', 'cardiovascular_admit',
                 'cns_admit', 'renal_admit', 'liver_admit', 'coagulation_admit']
    
    for col in sofa_cols:
        data[col] = data[col].fillna(0)

    # encode Absent as 0
    data['ckd_stages'] = data['ckd_stages'].apply(lambda x: 0 if x == "Absent" else x).astype(float)
    data['diabetes_types'] = data['diabetes_types'].apply(lambda x: 0 if x == "Absent" else x)
    # transform CKD stage into a categorical variable
    data['ckd_stages'] = data.ckd_stages.apply(lambda x: 1 if x > 2 else 0)

    # Replace missing values in fluids by 0
    data['fluids'] = data['fluids'].fillna(0)

    # replace not nan values by 1
    com_cols = ['hypertension_present', 'heart_failure_present', 'copd_present',
                'asthma_present', 'cad_present', 'connective_disease']

    for col in com_cols:
        data[col] = data[col].apply(lambda x: 0 if x != 1 else 1)

    # encode race_white into dummy
    data['race_nonwhite'] =  data['race_white'].apply(lambda x: 0 if x == "White" else 1)

    # encode racial-ethnic group into dummy, with white as reference
    race_vars = ['race_black', 'race_hisp', 'race_asian', 'race_other']
    race_names = ['Black', 'Hispanic', 'Asian', 'Other']

    for rv, rn in zip(race_vars, race_names):
        data[rv] = data['race_group'].apply(lambda x: 1 if x == rn else 
                                                      0 if x == "White" else np.nan)
    
    # encode proficieny in english into dummy
    data['eng_prof'] = data['eng_prof'].apply(lambda x: 1 if x == "Proficient" else 0)

    # encode anchor_year_group as numeric
    map_dict = {"2008 - 2010": 0, "2011 - 2013": 1, "2014 - 2016": 2, "2017 - 2019": 3}
    data['anchor_year_group'] = data['anchor_year_group'].map(map_dict)

    data = data[
                ['admission_age', 'sex_female',  'eng_prof', 'private_insurance'] + \
                ['race_nonwhite', 'race_black', 'race_hisp', 'race_asian', 'race_other'] + \
                ['anchor_year_group', 'adm_elective', 'major_surgery'] + \
                ['charlson_comorbidity_index'] + \
                ['SOFA_admit', 'respiratory_admit', 'coagulation_admit','cardiovascular_admit',
                 'cns_admit', 'renal_admit', 'liver_admit'] + \
                com_cols + ['ckd_stages'] + \
                lb_vt + sf_vt + \
                ['MV_elig', 'RRT_elig','VP_elig'] + \
                 ['pneumonia', 'uti', 'biliary', 'skin']
    ]

    data.to_csv(f'data/main/clean/coh_{cohort_number}_{treatment}.csv', index=False)

# Main
cohorts = [1,2,3,4]
hr_bounds = [24, 48, 72, 96]
treatments= ['MV', 'RRT', 'VP']

for i, c in enumerate(cohorts):
    print(f"Processing cohort {c}...")

    for t in treatments:
        print(f"Processing treatment {t}...")
        clean_data(c, hr_bounds[i], t)
