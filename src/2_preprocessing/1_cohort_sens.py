import pandas as pd
import numpy as np
import os
from utils import get_demography, print_demo

df0 = pd.read_csv('data/MIMIC_data.csv')
df0.ckd_stages = df0.ckd_stages.fillna(0)

print("\nNumbers for sensitivity analysis with lenient inclusion criteria")

print(f"\n{len(df0)} stays in the ICU")

# Remove patients without sepsis
df1 = df0[df0.sepsis3 == True]
print(f"Removed {len(df0) - len(df1)} stays without sepsis")
demo1 = print_demo(get_demography(df1))
print(f"{len(df1)} sepsis stays \n({demo1})\n")

# Remove patiens without Full Code
df2 = df1[df1.is_full_code_admission == 1]
print(f"Removed {len(df1) - len(df2)} stays without Full Code (admission)")
demo2 = print_demo(get_demography(df2))
print(f"{len(df2)} stays with sepsis and Full Code \n({demo2})\n")

# Remove patients with no english proficiency data entered, this used to be race filter
df3 = df2[df2.language.notna()]
print(f"Removed {len(df2) - len(df3)} patients with no english proficiency information")
demo3 = print_demo(get_demography(df3))
print(f"{len(df3)} ICU stays with sepsis, full code, and language data \n({demo3})\n")

# Remove patients with CKD stage > 3
df4 = df3[(df3.ckd_stages <= 3)]
print(f"Removed {len(df3) - len(df4)} stays with CKD stage > 3")
demo4 = print_demo(get_demography(df4))
print(f"{len(df4)} stays with sepsis, full code, language data, and 1 day <= ICU LoS, and no CKD stage >3 \n({demo4})\n")


# Create 4 new cohorts, iterating, removing patients with LoS < 2 day , 3 days, 4 days, 5 days
for los_min in range(2, 6):
    # Remove patients with LoS < {los_min} days
    print(f"\nRamification Starts for Cohort {los_min-1}\n")
    df5 = df4[df4.los_icu >= los_min]
    print(f"Removed {len(df4) - len(df5)} stays with LoS < {los_min} days")
    demo5 = print_demo(get_demography(df5))
    print(f"{len(df5)} stays with sepsis, {los_min} days <= ICU LoS \n({demo5})\n")

    # Remove patients with recurrent stays
    df6 = df5.sort_values(by=["subject_id", "hadm_id", "hospstay_seq","icustay_seq"], ascending=True) \
            .groupby('subject_id') \
            .apply(lambda group: group.iloc[0, 1:])

    print(f"Removed {len(df5) - len(df6)} recurrent stays")
    demo6 = print_demo(get_demography(df6))
    print(f"{len(df6)} stays with sepsis, {los_min} day <= ICU LoS , full code, language data \n({demo6})\n")

    df6.to_csv(f'data/sens/MIMIC_coh_{los_min-1}.csv')
    