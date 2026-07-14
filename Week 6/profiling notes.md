
# Profiling Notes

## 1. ABINIT

### Timing Summary

* **Path:** `abinit/v2/fullPEAK-scaling-07102026-152428/timing_summary.csv`

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `abinit_test_n1_nopeak` | `n1_nopeak` | 1 | 1 | No | **119** | 0 | 3294914 |
| `abinit_test_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **10** | 0 | 3294915 |
| `abinit_test_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **8** | 0 | 3294916 |
| `abinit_test_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **6** | 0 | 3294917 |
| `abinit_test_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **6** | 0 | 3294918 |
| `abinit_test_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **9** | 0 | 3294919 |
| `abinit_test_n1_peak` | `n1_peak` | 1 | 1 | Yes | **126** | 0 | 3294920 |

> **Scaling Note:** Perfect scaling down to 2 nodes (96 tasks), where it floors at 6 seconds. Adding more nodes (16 nodes / 768 tasks) starts to regress performance (9 seconds) due to communication overhead.
> **Overhead Note:** PEAK profiling overhead on 1 node is roughly **5.8%** (126s vs 119s).

### Top PEAK Profiling Hits (Single Node)

* **Path:** `.../test/single_node/n1_peak/peak_stats-p353460.csv` *(Top 5 by total time)*

| Function | Calls | Total Time (s) | Avg Time / Call (ms) | PEAK Overhead (s) |
| --- | --- | --- | --- | --- |
| `zgemm_` | 207,990 | **4.7613** | 0.0229 | 0.4258 |
| `ddot_` | 216,544 | **0.6383** | 0.0029 | 0.4433 |
| `zcopy_` | 131,022 | **0.6081** | 0.0046 | 0.2682 |
| `dznrm2_` | 116,280 | **0.5958** | 0.0051 | 0.2380 |
| `zdotc_` | 51,588 | **0.1846** | 0.0036 | 0.1056 |

---

## 2. DFTB+

### Timing Summary

* **Path:** `dftb/new_gen-scaling-07132026-145728/timing_summary.csv`

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `dftb_spinlock_n1_nopeak` | `n1_nopeak` | 1 | 1 | No | **120** | 0 | 3303873 |
| `dftb_spinlock_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **144** | 0 | 3303874 |
| `dftb_spinlock_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **220** | 0 | 3303875 |
| `dftb_spinlock_n1_peak` | `n1_peak` | 1 | 1 | Yes | **121** | 0 | 3303879 |
| `dftb_spinlock_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **2** | 1 (Fail) | 3303876 |
| `dftb_spinlock_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **3** | 1 (Fail) | 3303877 |
| `dftb_spinlock_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **3** | 1 (Fail) | 3303878 |

> **Scaling Note:** Performance severely degrades within a single node as tasks increase (120s to 220s). All multi-node scaling runs (N2, N8, N16) failed almost instantly with Exit Code 1.
> **Overhead Note:** PEAK profiling overhead on a single node is negligible at **0.8%** (121s vs 120s).

### Top PEAK Profiling Hits (Single Node)

* **Path:** `.../spinlock/single_node/n1_peak/peak_stats-p976087.csv` *(Top 5 by total time)*

| Function | Calls | Total Time (s) | Avg Time / Call (s) | PEAK Overhead (s) |
| --- | --- | --- | --- | --- |
| `dsyev_` | 4 | **94.1030** | 23.5258 | 0.0000 |
| `dgemm_` | 442 | **10.5098** | 0.0238 | 0.0007 |
| `dsymm_` | 4 | **10.0370** | 2.5092 | 0.0000 |
| `dlarrv_` | 4 | **0.1037** | 0.0259 | 0.0000 |
| `dcopy_` | 34,760 | **0.0280** | 0.0008 | 0.0541 |

---

## 3. GROMACS

### Timing Summary

* **Path:** `gromacs/2-scaling-07102026-221528/timing_summary.csv`

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `gromacs_benchMEM_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **213** | 0 | 3295859 |
| `gromacs_benchMEM_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **125** | 0 | 3295860 |
| `gromacs_benchMEM_n48_peak` | `n48_peak` | 1 | 48 | Yes | **126** | 0 | 3295864 |
| `gromacs_benchMEM_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **75** | 0 | 3295861 |
| `gromacs_benchMEM_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **37** | 0 | 3295862 |
| `gromacs_benchMEM_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **36** | 0 | 3295863 |

> **Overhead Note:** PEAK profiling overhead on 1 node (48 tasks) is negligible at **0.8%** (126s vs 125s).
> **Profiling Note:** GROMACS does not yield any PEAK telemetry hits.

---

## 4. LAMMPS

### Timing Summary

* **Path:** `lammps/5-scaling-07132026-225745/timing_summary.csv`

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `lammps_rhodo_n1_nopeak` | `n1_nopeak` | 1 | 1 | No | **32** | 0 | 3305579 |
| `lammps_rhodo_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **4** | 0 | 3305580 |
| `lammps_rhodo_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **4** | 0 | 3305581 |
| `lammps_rhodo_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **4** | 0 | 3305582 |
| `lammps_rhodo_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **4** | 0 | 3305583 |
| `lammps_rhodo_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **8** | 255 (Fail) | 3305584 |
| `lammps_rhodo_n1_peak` | `n1_peak` | 1 | 1 | Yes | **32** | 0 | 3305585 |

> **Scaling Note:** The workload scales immediately down to 4 seconds at 24 tasks and floors there. Multi-node runs do not improve performance, and the 16-node run failed with Exit Code 255.
> **Overhead Note:** 0% overhead detected on 1 node.
> **Profiling Note:** LAMMPS does not yield any PEAK telemetry hits.

---

## 5. Quantum Espresso (QE)

### Timing Summary

* **Path:** `qe/my_test_case_1-scaling-07132026-143411/timing_summary.csv`

| Job Name | Config | Nodes | Tasks | PEAK? | Elapsed (s) | Exit Code | Job ID |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `qe_tc_n1_nopeak` | `n1_nopeak` | 1 | 1 | No | **635** | 0 | 3303742 |
| `qe_tc_n24_nopeak` | `n24_nopeak` | 1 | 24 | No | **62** | 0 | 3303743 |
| `qe_tc_n48_nopeak` | `n48_nopeak` | 1 | 48 | No | **32** | 0 | 3303744 |
| `qe_tc_N2_nopeak` | `N2_nopeak` | 2 | 96 | No | **28** | 0 | 3303745 |
| `qe_tc_N8_nopeak` | `N8_nopeak` | 8 | 384 | No | **20** | 0 | 3303746 |
| `qe_tc_N16_nopeak` | `N16_nopeak` | 16 | 768 | No | **26** | 0 | 3303747 |
| `qe_tc_n1_peak` | `n1_peak` | 1 | 1 | Yes | **639** | 0 | 3303748 |

> **Scaling Note:** Excellent strong scaling down to 8 nodes (20s). Regresses slightly at 16 nodes (26s) due to communication overhead.
> **Overhead Note:** PEAK profiling overhead on 1 node is extremely low at **0.6%** (639s vs 635s).

### Top PEAK Profiling Hits (Single Node)

* **Path:** `.../tc/single_node/n1_peak/peak_stats-p1482505.csv` *(Top 5 by total time)*

| Function | Calls | Total Time (s) | Avg Time / Call (ms) | PEAK Overhead (s) |
| --- | --- | --- | --- | --- |
| `zgemm_` | 144,849 | **167.0428** | 1.1532 | 0.3505 |
| `zhegvx_` | 5,561 | **8.3936** | 1.5094 | 0.0135 |
| `zgemv_` | 1,184 | **3.7879** | 3.1993 | 0.0029 |
| `ddot_` | 57,984 | **0.3944** | 0.0068 | 0.1403 |
| `dcopy_` | 1,926 | **0.3241** | 0.1683 | 0.0047 |
