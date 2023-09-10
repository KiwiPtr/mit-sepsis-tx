# mit-sepsis-tx

Likelihood of Receiving a Treatment, across Race-Ethnicity for Septic Patients in the ICU

The goal of this project is to investigate disparities between races in critically ill sepsis patients in regard to likelihood of receiving one of three life-sustaining treatmens, i.e. renal replacement therapy (RRT), vasopressor use (VP), or mechanical ventilation (MV) in cohorts curated from MIMIC IV (2008-2019).

## How to run this project

### 1. Clone this repository

Run the following command in your terminal.

```sh
git clone https://github.com/joamats/mit-sepsis-tx.git
```

### 2. Install required Packages

Run the following command:

```sh
pip install -r src/setup/requirements.txt
```

### 3. Fetch the data

MIMIC data can be found in [PhysioNet](https://physionet.org/), a repository of freely-available medical research data, managed by the MIT Laboratory for Computational Physiology. Due to its sensitive nature, credentialing is required to access both datasets.

Documentation for MIMIC-IV's can be found [here](https://mimic.mit.edu/).

#### Integration with Google Cloud Platform (GCP)

In this section, we explain how to set up GCP and your environment in order to run SQL queries through GCP right from your local Python setting. Follow these steps:

1) Create a Google account if you don't have one and go to [Google Cloud Platform](https://console.cloud.google.com/bigquery)
2) Enable the [BigQuery API](https://console.cloud.google.com/apis/api/bigquery.googleapis.com)
3) Create a [Service Account](https://console.cloud.google.com/iam-admin/serviceaccounts), where you can download your JSON keys
4) Place your JSON keys in the parent folder (for example) of your project
5) Create a .env file with the command `cp env.example env `
6) Update your .env file with your ***JSON keys*** path and the ***id*** of your project in BigQuery

#### MIMIC-IV

After getting credentialing at PhysioNet, you must sign the data use agreement and connect the database with GCP, either asking for permission or uploading the data to your project.

Having all the necessary tables for the cohort generation query in your project (you have to run all the auxillary queries manually on BigQuery), run the following command to fetch the data as a dataframe that will be saved as CSV in your local project. Make sure you have all required files and folders.

```sh
python3 src/py_scripts/get_data.py --sql "src/sql_queries/main.sql" --destination "data/MIMIC_data.csv"
```

And transform into a ready to use dataframe by running all scripts in 2_preprocessing sequentially.

The ICD-9 to ICD-10 translation based on this [GitHub Repo](https://github.com/AtlasCUMC/ICD10-ICD9-codes-conversion).

### 4. Run the analyses

Run the scripts in 3_models.

### Random notes

Locations where Race variables are mentioned
config
1-Both confounders files in config
queries
2-Main sql file line 346 to 370
preprocessing
3-cohort_main line 23 to 27
4-cohort_sens line 25 to 29
5-table1 line 4 to 12, 48, 190 to 200
6-table2 line 8 to 12, 56, 149
7-clean_data_1coh line 124 to 133, 144
8-clean_data_1coh line 119 to 128, 139
9-clean_data_sens line 11 to 12, 165 to 174, 185
10-utils line 12 to 13
models
11-parallel logreg_cv_all_coh_races line 8, 38 to 74, 104
12-parallel logreg_cv_all_coh line 22, 40 to 63, 93
13-parallel xgb_cv_all_coh_races line 9, 28, 45 to 84, 114
14-parallel xgb_cv_all_coh line 28, 51 to 74, 104
15-sens logreg_cv_all_coh_races line 7, 15, 20 to 55, 99
16-sens logreg_cv_all_coh line 20 to 43, 66, 87
17-sens utils, none
18-sens parallel xgb_cv_all_coh_races line 8, 24 to 32, 44 to 63, 107
19-sens parallel xgb_cv_all_coh line 29 to 52, 98
20-models_audit, none
plots
21-all_races line 16 to 17, 40 to 44, 62, 73, 84 to 85
22-white_nonwhite line 48, 

files with races in the name breakdown the cohort to all different race types whereas other ones just use white vs non-white
probably modify these ones to get what we need and somehow exclude other files