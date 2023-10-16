import pandas as pd
import numpy as np
import os
from utils import get_demography, print_demo

df0 = pd.read_csv('data/MIMIC_data.csv')
df0.ckd_stages = df0.ckd_stages.fillna(0)
print("\nNumbers for main analysis with strict inclusion criteria")
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
# save df4
df4.to_csv('data/MIMIC_for_table1.csv')

hr_periods = ["6_24h", "24_48h", "48_72h", "72_96h"]

# Create 4 new cohorts, iterating, removing patients with LoS < 2 day , 3 days, 4 days, 5 days
for i, los_min in enumerate(range(2, 6)):
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
    print(f"{len(df6)} stays with sepsis, {los_min} day <= ICU LoS, full code, language data \n({demo6})\n")

    print(f"\nSub-Ramification Starts for Treatment-specific Elegibity Inclusion Criteria\n")

    # Remove patients that don't meet MV criteria
    MV_masks = []
    for j in range(i+1):
        MV_masks.append(df6[f"pf_{hr_periods[j]}"] <= 300)
        MV_masks.append(df6[f"pco2_min_{hr_periods[j]}"] >= 60)
        MV_masks.append(df6[f"resp_rate_mean_{hr_periods[j]}"] >= 20)

    # create a single mask that is an OR of all masks
    MV_mask = MV_masks[0]
    for m in MV_masks[1:]:
        MV_mask = MV_mask | m

    df7_MV = df6[MV_mask]
    print(f"Removed {len(df6) - len(df7_MV)} stays that don't meet MV criteria")

    demo7_MV = print_demo(get_demography(df7_MV))
    print(f"{len(df7_MV)} stays with all above and MV elegibility criteria met \n({demo7_MV})\n")

    df7_MV.to_csv(f'data/main/MIMIC_coh_{los_min-1}_MV.csv')

    # Remove patients that don't meet RRT criteria
    # impute missing weight_admit, depends on the sex
    # 77kg for sex_female == 1, 90kg for sex_female == 0
    df6.weight_admit = df6.weight_admit.fillna(-1)
    df6.weight_admit = df6.apply(lambda row: 77 if (row.weight_admit == -1) & \
                                                   (row.sex_female == 1) \
                                                else row.weight_admit, axis=1)
    df6.weight_admit = df6.apply(lambda row: 90 if (row.weight_admit == -1) & \
                                                   (row.sex_female == 0) \
                                                else row.weight_admit, axis=1)
    RRT_masks = []
    for j in range(i+1):
        # compute uo/weight
        df6[f"uo_weight_{hr_periods[j]}"] = df6[f"uo_{hr_periods[j]}"] / df6.weight_admit
        RRT_masks.append(df6[f"uo_weight_{hr_periods[j]}"] <= 12)
        RRT_masks.append(df6[f"potassium_min_{hr_periods[j]}"] >= 6.5)
        RRT_masks.append((df6[f"ph_max_{hr_periods[j]}"] <= 7.2) & (df6[f"bicarbonate_max_{hr_periods[j]}"] <= 12))

    # create a single mask that is an OR of all masks
    RRT_mask = RRT_masks[0]
    for m in RRT_masks[1:]:
        RRT_mask = RRT_mask | m

    df7_RRT = df6[RRT_mask]
    print(f"Removed {len(df6) - len(df7_RRT)} stays that don't meet RRT criteria")

    demo7_RRT = print_demo(get_demography(df7_RRT))
    print(f"{len(df7_RRT)} stays with all above and RRT elegibility criteria met \n({demo7_RRT})\n")

    df7_RRT.to_csv(f'data/main/MIMIC_coh_{los_min-1}_RRT.csv')
                                
    # Remove patients that don't meet VP criteria
    VP_masks = []
    for j in range(i+1):
        VP_masks.append(df6[f"mbp_mean_{hr_periods[j]}"] <= 65)
        VP_masks.append(df6[f"lactate_min_{hr_periods[j]}"] >= 2)

    # create a single mask that is an OR of all masks
    VP_mask = VP_masks[0]
    for m in VP_masks[1:]:
        VP_mask = VP_mask | m

    df7_VP = df6[VP_mask]
    print(f"Removed {len(df6) - len(df7_VP)} stays that don't meet VP criteria")

    demo7_VP = print_demo(get_demography(df7_VP))
    print(f"{len(df7_VP)} stays with all above and VP elegibility criteria met \n({demo7_VP})\n")
    
    df7_VP.to_csv(f'data/main/MIMIC_coh_{los_min-1}_VP.csv')
