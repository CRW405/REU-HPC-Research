import io
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 1. Load the provided dataset
raw_data = """job_name,test_case,config,nodes,ntasks,peak_enabled,start_time,end_time,elapsed_seconds,exit_code,slurm_job_id
abinit_test0_N8_nopeak,test0,N8_nopeak,8,384,false,2026-06-29 19:09:10,2026-06-29 19:09:16,6,0,3257197
abinit_test1_N8_nopeak,test1,N8_nopeak,8,384,false,2026-06-29 19:14:15,2026-06-29 19:14:20,5,0,3257207
abinit_test0_N8_peak,test0,N8_peak,8,384,true,2026-06-29 19:14:15,2026-06-29 19:22:03,468,0,3257206
abinit_test2_N8_nopeak,test2,N8_nopeak,8,384,false,2026-06-29 19:24:26,2026-06-29 19:24:31,5,0,3257230
abinit_test1_N8_peak,test1,N8_peak,8,384,true,2026-06-29 19:19:22,2026-06-29 19:24:34,312,0,3257221
abinit_test2_N8_peak,test2,N8_peak,8,384,true,2026-06-29 19:39:37,2026-06-29 19:45:06,329,0,3257280
abinit_test4_N8_nopeak,test4,N8_nopeak,8,384,false,2026-06-29 21:56:46,2026-06-29 21:56:52,6,0,3257646
abinit_test3_N8_nopeak,test3,N8_nopeak,8,384,false,2026-06-29 21:56:46,2026-06-29 21:56:55,9,0,3257644
abinit_test4_N8_peak,test4,N8_peak,8,384,true,2026-06-29 21:56:46,2026-06-29 22:03:49,423,0,3257193
abinit_test3_N8_peak,test3,N8_peak,8,384,true,2026-06-29 21:56:46,2026-06-29 22:04:21,455,0,3257645
abinit_test1_N4_nopeak,test1,N4_nopeak,4,192,false,2026-06-29 22:06:55,2026-06-29 22:07:00,5,0,3257671
abinit_test0_N4_nopeak,test0,N4_nopeak,4,192,false,2026-06-29 22:06:55,2026-06-29 22:07:00,5,0,3257669
abinit_test2_N4_nopeak,test2,N4_nopeak,4,192,false,2026-06-29 22:06:55,2026-06-29 22:07:00,5,0,3257673
abinit_test3_N4_nopeak,test3,N4_nopeak,4,192,false,2026-06-29 22:12:01,2026-06-29 22:12:05,4,0,3257681
abinit_test4_N4_nopeak,test4,N4_nopeak,4,192,false,2026-06-29 22:12:01,2026-06-29 22:12:05,4,0,3257683
abinit_test1_N4_peak,test1,N4_peak,4,192,true,2026-06-29 22:06:55,2026-06-29 22:12:44,349,0,3257672
abinit_test0_N4_peak,test0,N4_peak,4,192,true,2026-06-29 22:06:55,2026-06-29 22:15:05,490,0,3257670
abinit_test3_N4_peak,test3,N4_peak,4,192,true,2026-06-29 22:12:01,2026-06-29 22:18:10,369,0,3257682
abinit_test4_N4_peak,test4,N4_peak,4,192,true,2026-06-29 22:12:01,2026-06-29 22:18:26,385,0,3257663
abinit_test2_N4_peak,test2,N4_peak,4,192,true,2026-06-29 22:12:01,2026-06-29 22:18:32,391,0,3257680
abinit_test2_N2_nopeak,test2,N2_nopeak,2,96,false,2026-06-29 22:22:10,2026-06-29 22:22:14,4,0,3257706
abinit_test1_N2_nopeak,test1,N2_nopeak,2,96,false,2026-06-29 22:22:10,2026-06-29 22:22:14,4,0,3257704
abinit_test0_N2_nopeak,test0,N2_nopeak,2,96,false,2026-06-29 22:22:10,2026-06-29 22:22:14,4,0,3257702
abinit_test4_N2_nopeak,test4,N2_nopeak,2,96,false,2026-06-29 22:27:14,2026-06-29 22:27:18,4,0,3257721
abinit_test3_N2_nopeak,test3,N2_nopeak,2,96,false,2026-06-29 22:27:14,2026-06-29 22:27:18,4,0,3257719
abinit_test1_N2_peak,test1,N2_peak,2,96,true,2026-06-29 22:22:10,2026-06-29 22:27:56,346,0,3257705
abinit_test0_N2_peak,test0,N2_peak,2,96,true,2026-06-29 22:22:10,2026-06-29 22:32:17,607,0,3257703
abinit_test3_N2_peak,test3,N2_peak,2,96,true,2026-06-29 22:27:14,2026-06-29 22:32:52,338,0,3257720
abinit_test4_N2_peak,test4,N2_peak,2,96,true,2026-06-29 22:27:14,2026-06-29 22:33:05,351,0,3257699
abinit_test2_N2_peak,test2,N2_peak,2,96,true,2026-06-29 22:27:14,2026-06-29 22:33:44,390,0,3257718
abinit_test1_n8_nopeak,test1,n8_nopeak,1,8,false,2026-06-29 22:37:23,2026-06-29 22:37:26,3,0,3257736
abinit_test2_n8_nopeak,test2,n8_nopeak,1,8,false,2026-06-29 22:37:23,2026-06-29 22:37:26,3,0,3257738
abinit_test0_n8_nopeak,test0,n8_nopeak,1,8,false,2026-06-29 22:37:23,2026-06-29 22:37:26,3,0,3257734
abinit_test1_n8_peak,test1,n8_peak,1,8,true,2026-06-29 22:37:23,2026-06-29 22:41:55,272,0,3257737
abinit_test4_n8_nopeak,test4,n8_nopeak,1,8,false,2026-06-29 22:42:26,2026-06-29 22:42:30,4,0,3257755
abinit_test3_n8_nopeak,test3,n8_nopeak,1,8,false,2026-06-29 22:42:26,2026-06-29 22:42:30,4,0,3257753
abinit_test0_n8_peak,test0,n8_peak,1,8,true,2026-06-29 22:37:23,2026-06-29 22:44:26,423,0,3257735
abinit_test2_n8_peak,test2,n8_peak,1,8,true,2026-06-29 22:42:26,2026-06-29 22:47:58,332,0,3257752
abinit_test3_n8_peak,test3,n8_peak,1,8,true,2026-06-29 22:42:26,2026-06-29 22:49:03,397,0,3257754
abinit_test4_n8_peak,test4,n8_peak,1,8,true,2026-06-29 22:47:30,2026-06-29 22:54:08,398,0,3257730
abinit_test0_N16_nopeak,test0,N16_nopeak,16,768,false,2026-06-30 00:43:37,2026-06-30 00:43:43,6,0,3257942
abinit_test1_N16_nopeak,test1,N16_nopeak,16,768,false,2026-06-30 00:48:40,2026-06-30 00:50:55,135,0,3257958
abinit_test2_N16_nopeak,test2,N16_nopeak,16,768,false,2026-06-30 00:58:46,2026-06-30 01:01:05,139,0,3257981
abinit_test0_N16_peak,test0,N16_peak,16,768,true,2026-06-30 00:43:37,2026-06-30 01:01:07,1050,0,3257943
abinit_test1_N16_peak,test1,N16_peak,16,768,true,2026-06-30 00:53:43,2026-06-30 01:08:43,900,0,3257971
abinit_test3_N16_nopeak,test3,N16_nopeak,16,768,false,2026-06-30 01:08:52,2026-06-30 01:08:58,6,0,3258023
abinit_test4_N16_nopeak,test4,N16_nopeak,16,768,false,2026-06-30 01:13:54,2026-06-30 01:14:00,6,0,3258036
abinit_test2_N16_peak,test2,N16_peak,16,768,true,2026-06-30 01:08:52,2026-06-30 01:26:37,1065,0,3258022
abinit_test3_N16_peak,test3,N16_peak,16,768,true,2026-06-30 01:13:54,2026-06-30 01:30:27,993,0,3258035
abinit_test4_N16_peak,test4,N16_peak,16,768,true,2026-06-30 01:18:56,2026-06-30 01:33:22,866,0,3257775
abinit_test0_n48_nopeak,test0,n48_nopeak,1,48,false,2026-06-30 09:49:27,2026-06-30 09:49:32,5,0,3259016
abinit_test0_n48_peak,test0,n48_peak,1,48,true,2026-06-30 09:54:30,2026-06-30 10:00:49,379,0,3259037
abinit_test1_n48_nopeak,test1,n48_nopeak,1,48,false,2026-06-30 10:04:35,2026-06-30 10:04:39,4,0,3259062
abinit_test2_n48_nopeak,test2,n48_nopeak,1,48,false,2026-06-30 10:04:35,2026-06-30 10:04:39,4,0,3259064
abinit_test1_n48_peak,test1,n48_peak,1,48,true,2026-06-30 10:04:35,2026-06-30 10:09:13,278,0,3259063
abinit_test3_n48_nopeak,test3,n48_nopeak,1,48,false,2026-06-30 10:09:36,2026-06-30 10:09:40,4,0,3259084
abinit_test4_n48_nopeak,test4,n48_nopeak,1,48,false,2026-06-30 10:09:36,2026-06-30 10:09:41,5,0,3259086
abinit_test4_n48_peak,test4,n48_peak,1,48,true,2026-06-30 10:09:36,2026-06-30 10:14:52,316,0,3258062
abinit_test2_n48_peak,test2,n48_peak,1,48,true,2026-06-30 10:09:36,2026-06-30 10:15:07,331,0,3259083
abinit_test3_n48_peak,test3,n48_peak,1,48,true,2026-06-30 10:09:36,2026-06-30 10:15:16,340,0,3259085"""

df = pd.read_csv(io.StringIO(raw_data))

# 2. Add an explicit 'Scaling Label' to easily separate multi-node vs single-node layouts
def extract_scale_label(row):
    if row['nodes'] > 1:
        return f"{row['nodes']} Nodes ({row['ntasks']} Cores)"
    else:
        return f"1 Node ({row['ntasks']} Cores)"

df['Scaling Setup'] = df.apply(extract_scale_label, axis=1)

# Sort scaling setups logically by compute volume size
sort_order = [
    "1 Node (8 Cores)", "1 Node (48 Cores)",
    "2 Nodes (96 Cores)", "4 Nodes (192 Cores)",
    "8 Nodes (384 Cores)", "16 Nodes (768 Cores)"
]
df['Scaling Setup'] = pd.Categorical(df['Scaling Setup'], categories=sort_order, ordered=True)
df['peak_enabled'] = df['peak_enabled'].map({True: 'PEAK Active', False: 'Baseline (No PEAK)'})

# 3. Create a Custom Grid Layout splitting Baseline vs PEAK by Row
sns.set_theme(style="whitegrid", context="talk")

# 2 rows (Row 0: Baseline, Row 1: PEAK Active) x 6 columns for our 6 setups
fig, axes = plt.subplots(nrows=2, ncols=6, figsize=(24, 10), sharex=False, sharey=False)

# Map our sorted configurations out horizontally across all 6 columns
unique_setups = sort_order

for col_idx, setup in enumerate(unique_setups):
    subset = df[df['Scaling Setup'] == setup]

    # --- ROW 0: Baseline (No PEAK) ---
    ax_base = axes[0, col_idx]
    base_data = subset[subset['peak_enabled'] == 'Baseline (No PEAK)']
    sns.barplot(
        data=base_data, x="test_case", y="elapsed_seconds",
        ax=ax_base, color=sns.color_palette("muted")[0], edgecolor="black"
    )
    # Clean up titles so they don't crowd the top row
    ax_base.set_title(f"{setup.split(' (')[0]}\n({setup.split(' (')[1].replace(')', '')})", pad=12, fontsize=11, weight="bold")
    ax_base.set_xlabel("", labelpad=0)
    ax_base.set_ylabel("", labelpad=0)
    ax_base.tick_params(axis='both', labelsize=10)

    # --- ROW 1: PEAK Active ---
    ax_peak = axes[1, col_idx]
    peak_data = subset[subset['peak_enabled'] == 'PEAK Active']
    sns.barplot(
        data=peak_data, x="test_case", y="elapsed_seconds",
        ax=ax_peak, color=sns.color_palette("muted")[1], edgecolor="black"
    )
    ax_peak.set_xlabel("", labelpad=0)
    ax_peak.set_ylabel("", labelpad=0)
    ax_peak.tick_params(axis='both', labelsize=10)

# 4. Final Refinements and Tight Margin Tuning
fig.supxlabel("Test Case ID", fontsize=14, weight="bold", y=0.02)
fig.supylabel("Execution Time (Seconds, Linear Scale)", fontsize=14, weight="bold", x=0.01)

# Recreate a custom clean legend proxy for the two distinct row treatments
from matplotlib.patches import Patch
legend_elements = [
    Patch(facecolor=sns.color_palette("muted")[0], edgecolor='black', label='Baseline (No PEAK) [Top Row]'),
    Patch(facecolor=sns.color_palette("muted")[1], edgecolor='black', label='PEAK Active [Bottom Row]')
]
fig.legend(handles=legend_elements, title="Profiling State", loc="upper right", bbox_to_anchor=(0.99, 0.96), fontsize=11, title_fontsize=12)

# Master layout padding to guarantee absolutely zero overlapping text
plt.subplots_adjust(
    top=0.82,      # Clearance for main super-title
    bottom=0.12,   # Clearance for X-axis title
    left=0.05,     # Clearance for Y-axis title
    right=0.99,
    hspace=0.35,   # High vertical gap allows the titles/labels room to breathe
    wspace=0.30    # Horizontal separation gap between the 6 columns
)

fig.suptitle("ABINIT Profiling Overhead Analysis\nLinear Runtime Comparison Separated by Profiling State",
             fontsize=18, weight="bold", x=0.5, y=0.94)

# Save output figures locally
output_img = "abinit_overhead_trends.png"
plt.savefig(output_img, dpi=300, bbox_inches="tight")
print(f"==> Visualization plot saved successfully as: {output_img}")
