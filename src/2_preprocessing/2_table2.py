from tableone import TableOne
import pandas as pd

def table_one(treatment, hr_bound):

    data = pd.read_csv(f'data/main/MIMIC_coh_1_{treatment}.csv')

    # Encode language as English proficiency or Limited English proficiency swapped with english prof part
    data['eng_prof'] = data['language'].apply(lambda x: "Limited" if x == '?' else "Proficient")

    # Groupby Variable, replaced race_white with eng_prof
    groupby = ['eng_prof']

    # Continuous Variables
    data['los_hosp_dead'] = data[data.mortality_in == 1].los_hospital
    data['los_hosp_surv'] = data[data.mortality_in == 0].los_hospital

    data['los_icu_dead'] = data[data.mortality_in == 1].los_icu
    data['los_icu_surv'] = data[data.mortality_in == 0].los_icu

    # Encode race_white as being white vs. non-white swapped with english prof part
    data['race_white'] = data.race_group.apply(lambda x: "White" if x == "White" else "Racial-Ethnic Group")

    # Create variable for receiving fluids, if fluid volume is not na
    data['fluids_overall'] = data['fluids_volume'].apply(lambda x: 1. if x > 0 else 0.)

    # Encode absolute durations and offsets into hours
    data['MV_time_abs_hours'] = data['MV_time_abs'] * 24
    data['VP_time_abs_hours'] = data['VP_time_abs'] * 24
    data['MV_init_offset_abs_hours'] = data['MV_init_offset_abs'] * 24
    data['RRT_init_offset_abs_hours'] = data['RRT_init_offset_abs'] * 24
    data['VP_init_offset_abs_hours'] = data['VP_init_offset_abs'] * 24

    # encode treatment according to elegibity window, hr_bound
    data[f'MV_elig']  = data['MV_init_offset_abs_hours'].apply(lambda x:  1 if (x < hr_bound) else 0)
    data[f'RRT_elig'] = data['RRT_init_offset_abs_hours'].apply(lambda x: 1 if (x < hr_bound) else 0)
    data[f'VP_elig']  = data['VP_init_offset_abs_hours'].apply(lambda x:  1 if (x < hr_bound) else 0)
        
    # Encode NA as 0, if missing means 0
    cols_na = ['major_surgery', 'insulin_yes', 'transfusion_yes', 'hypertension_present',
               'heart_failure_present', 'copd_present', 'asthma_present', 'cad_present',
               'ckd_stages', 'diabetes_types', 'connective_disease', 'pneumonia',
               'uti', 'biliary', 'skin']

    for c in cols_na:
        data[c] = data[c].fillna(0)

    # Encode diabetes and CKD 0 as "Absent"
    data['diabetes_types'] = data['diabetes_types'].apply(lambda x: "Absent" if x == 0 else x)
    # data['ckd_stages'] = data['ckd_stages'].apply(lambda x: "Absent" if x == 0 else x)
    
    # collapse CKD into binary -> CKD stage == 3 or CKD stage < 3
    data['ckd_stages'] = data['ckd_stages'].apply(lambda x: 3 if x == 3 else 0)

# Hashed eng_prof, unhashed race_group
    order = {
        "race_group": ["White", "Black", "Hispanic", "Asian", "Other"],
        "gender": ["F", "M"],
        #"eng_prof": ["Limited", "Proficient"],
        "insurance": ["Medicare", "Medicaid", "Other"],
        "adm_elective": [1, 0],
        "major_surgery": [1., 0.],
        "mortality_in": [1, 0],
        "MV_elig": [1, 0],
        "RRT_elig": [1, 0],
        "VP_elig": [1, 0],
        "hypertension_present": [1., 0.],
        "heart_failure_present": [1., 0.],
        "copd_present": [1., 0.],
        "asthma_present": [1., 0.],
        "cad_present": [1., 0.],
        "connective_disease": [1., 0.],
        "pneumonia": [1., 0.],
        "uti": [1., 0.],
        "biliary": [1., 0.],
        "skin": [1., 0.],
    }

# Changed eng_prof to race_group
    limit = {"gender": 1,
            "adm_elective": 1,
            "major_surgery": 1,
            "mortality_in": 1,
            "mortality_90": 1,
            "race_group": 1,
            "MV_elig": 1,
            "RRT_elig": 1,
            "VP_elig": 1,
            "mech_vent_overall": 1,
            "rrt_overall": 1,
            "vasopressor_overall": 1,
            "insulin_yes": 1,
            "transfusion_yes": 1,
            "fluids_overall": 1,
            "hypertension_present": 1,
            "heart_failure_present": 1,
            "copd_present": 1,
            "asthma_present": 1,
            "cad_present": 1,
            "connective_disease": 1,
            "pneumonia": 1,
            "uti": 1,
            "biliary": 1,
            "skin": 1,
            }

# Changed eng_prof to race_group    
    categ = ['gender',
             'insurance',
             'race_group',
             'adm_elective',
             'major_surgery',
             'mortality_in', 
             'MV_elig',
             'RRT_elig',
             'VP_elig',
             'hypertension_present',
             'heart_failure_present',
             'copd_present',
             'asthma_present',
             'cad_present',
             'ckd_stages',
             'diabetes_types',
             'connective_disease',
             'pneumonia',
             'uti',
             'biliary',
             'skin'
            ]

    nonnorm = ['admission_age', 
               'los_icu_dead',
               'los_icu_surv',
               'charlson_comorbidity_index',
               'SOFA_admit', 
               'MV_time_perc_of_stay',
               'MV_init_offset_abs_hours',
               'RRT_init_offset_abs_hours', 
               'VP_init_offset_abs_hours', 
               'VP_time_perc_of_stay'
            ]  

    labls = {
        'anchor_age': 'Age',
        'admission_age': 'Age',
        'gender': 'Sex ',
        'mortality_in': "In-Hospital Mortality",
        'eng_prof': "English Proficiency",
        'adm_elective': "Elective Admission",
        'major_surgery': "Major Surgery",
        'insurance': "Health Insurance",
        'race_group': "Race-Ethnicity Group",
        'MV_elig': "MV initiated until the cohort day",
        'RRT_elig': "RRT initiated until the cohort day",
        'VP_elig': "Vasopressor initiated until the cohort day",
        'hypertension_present': "Hypertension",
        'heart_failure_present': "Congestive Heart Failure",
        'copd_present': "COPD",
        'asthma_present': "Asthma",
        'cad_present': "Coronary Artery Disease",
        'ckd_stages': "CKD Stage",
        'diabetes_types': "Diabetes Type",
        'connective_disease': "Connective Tissue Disease",
        'pneumonia': "Pneumonia",
        'uti': "Urinary Tract Infection",
        'biliary': "Biliary Tract Infection",
        'skin': "Skin Infection",
        'los_icu_dead': "ICU LOS (days, if deceased)",
        'los_icu_surv': "ICU LOS (days, if survived)",
        'charlson_comorbidity_index': "Charlson Comorbidity Index",
        'SOFA_admit': "SOFA Score (admission)",
        'MV_time_abs': "MV Time (duration in the stay, hours)",
        'MV_time_perc_of_stay': "MV Time (duration in the stay, % of ICU LOS)",
        'MV_init_offset_abs': "MV Initiation (offset, hours)",
        'RRT_init_offset_abs': "RRT Initiation (offset, hours)",
        'VP_init_offset_abs': "Vasopressor Initiation (offset, hours)",
        'VP_time_abs': "Vasopressor Time (duration in the stay, hours)",
        'VP_time_perc_of_stay': "Vasopressor Time (duration in the stay, % of ICU LOS)",
        }
    
    decimals = {
        'admission_age': 0,
        'SOFA_admit': 0,
        'charlson_comorbidity_index': 0,
        'los_icu_dead': 2,
        'los_icu_surv': 2,
        'MV_time_perc_of_stay': 2,
        'VP_time_perc_of_stay': 2    
        }

    # Create a TableOne 
    table1_s = TableOne(data, columns=categ+nonnorm,
                        rename=labls, limit=limit, order=order, decimals=decimals,
                        groupby=groupby, categorical=categ, nonnormal=nonnorm,
                        missing=False, overall=False,
                        dip_test=True, normal_test=True, tukey_test=True, htest_name=True)

    table1_s.to_excel(f'results/table2/{treatment}.xlsx')


treatments = ["MV", "RRT", "VP"]

for i in range(len(treatments)):
    print(f"Processing treatment {treatments[i]}...")
    table_one(treatments[i], 24)

tables = []
# Read all tables and merge them with a loop
for i in range(len(treatments)):

    table = pd.read_excel(f'results/table2/{treatments[i]}.xlsx')

    tables.append(table)

# concatenate in a single table, but index just once
table1 = pd.concat(tables, axis=1)

table1.to_excel('results/table2/all.xlsx', index=False, header=False)
