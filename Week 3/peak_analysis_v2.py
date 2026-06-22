import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import sys
from pathlib import Path
from collections import defaultdict

"""
Usage:

# Both files
python analysis.py peak_mem-p12345.csv peak_stats-p12345.csv

# Stats only (gets library analysis)
python analysis.py peak_stats-p12345.csv

# Memory only
python analysis.py peak_mem-p12345.csv

"""

# Library function signatures from PEAK source
BLAS_FUNCTIONS = {"caxpy_", "ccopy_", "cdotc_", "cdotu_", "cgbmv_", "cgemm_", "cgemm3m_", "cgemmtr_", "cgemv_", "cgerc_", "cgeru_", "chbmv_", "chemm_", "chemv_", "cher2_", "cher2k_", "cher_", "cherk_", "chpmv_", "chpr2_", "chpr_", "cscal_", "csrot_", "csscal_", "cswap_", "csymm_", "csyr2k_", "csyrk_", "ctbmv_", "ctbsv_", "ctpmv_", "ctpsv_", "ctrmm_", "ctrmv_", "ctrsm_", "ctrsv_", "dasum_", "daxpy_", "dcabs1_", "dcopy_", "ddot_", "dgbmv_", "dgemm_", "dgemmtr_", "dgemv_", "dger_", "drot_", "drotm_", "drotmg_", "dsbmv_", "dscal_", "dsdot_", "dspmv_", "dspr2_", "dspr_", "dswap_", "dsymm_", "dsymv_", "dsyr2_", "dsyr2k_", "dsyr_", "dsyrk_", "dtbmv_", "dtbsv_", "dtpmv_", "dtpsv_", "dtrmm_", "dtrmv_", "dtrsm_", "dtrsv_", "dzasum_", "icamax_", "idamax_", "isamax_", "izamax_", "sasum_", "saxpy_", "scabs1_", "scasum_", "scopy_", "sdot_", "sdsdot_", "sgbmv_", "sgemm_", "sgemmtr_", "sgemv_", "sger_", "srot_", "srotm_", "srotmg_", "ssbmv_", "sscal_", "sspmv_", "sspr2_", "sspr_", "sswap_", "ssymm_", "ssymv_", "ssyr2_", "ssyr2k_", "ssyr_", "ssyrk_", "stbmv_", "stbsv_", "stpmv_", "stpsv_", "strmm_", "strmv_", "strsm_", "strsv_", "zaxpy_", "zcopy_", "zdotc_", "zdotu_", "zdrot_", "zdscal_", "zgbmv_", "zgemm_", "zgemm3m_", "zgemmtr_", "zgemv_", "zgerc_", "zgeru_", "zhbmv_", "zhemm_", "zhemv_", "zher2_", "zher2k_", "zher_", "zherk_", "zhpmv_", "zhpr2_", "zhpr_", "zscal_", "zswap_", "zsymm_", "zsyr2k_", "zsyrk_", "ztbmv_", "ztbsv_", "ztpmv_", "ztpsv_", "ztrmm_", "ztrmv_", "ztrsm_", "ztrsv_", "srotg_", "drotg_", "crotg_", "zrotg_", "snrm2_", "dnrm2_", "scnrm2_", "dznrm2_", "crot_", "zrot_", "isamin_", "idamin_", "icamin_", "izamin_", "saxpby_", "daxpby_", "caxpby_", "zaxpby_"}

LAPACK_FUNCTIONS = {"cbbcsd_", "cbdsqr_", "cgbbrd_", "cgbcon_", "cgbequb_", "cgbequ_", "cgbrfs_", "cgbrfsx_", "cgbsv_", "cgbsvx_", "cgbsvxx_", "cgbtf2_", "cgbtrf_", "cgbtrs_", "cgebak_", "cgebal_", "cgebd2_", "cgebrd_", "cgecon_", "cgeequb_", "cgeequ_", "cgees_", "cgeesx_", "cgeev_", "cgeevx_", "cgehd2_", "cgehrd_", "cgejsv_", "cgelq2_", "cgelq_", "cgelqf_", "cgelqt3_", "cgelqt_", "cgelsd_", "cgels_", "cgelss_", "cgelst_", "cgelsy_", "cgemlq_", "cgemlqt_", "cgemqr_", "cgemqrt_", "cgeql2_", "cgeqlf_", "cgeqp3_", "cgeqp3rk_", "cgeqr2_", "cgeqr2p_", "cgeqr_", "cgeqrf_", "cgeqrfp_", "cgeqrt2_", "cgeqrt3_", "cgeqrt_", "cgerfs_", "cgerfsx_", "cgerq2_", "cgerqf_", "cgesc2_", "cgesdd_", "cgesvd_", "cgesvdq_", "cgesvdx_", "cgesv_", "cgesvj_", "cgesvx_", "cgesvxx_", "cgetc2_", "cgetf2_", "cgetrf2_", "cgetrf_", "cgetri_", "cgetrs_", "cgetsls_", "cgetsqrhrt_", "cggbak_", "cggbal_", "cgges3_", "cgges_", "cggesx_", "cggev3_", "cggev_", "cggevx_", "cggglm_", "cgghd3_", "cgghrd_", "cgglse_", "cggqrf_", "cggrqf_", "cggsvd3_", "cggsvp3_", "cgsvj0_", "cgsvj1_", "cgtcon_", "cgtrfs_", "cgtsv_", "cgtsvx_", "cgttrf_", "cgttrs_", "cgtts2_", "chb2st_kernels_", "chbev_2stage_", "chbevd_2stage_", "chbevd_", "chbev_", "chbevx_2stage_", "chbevx_", "chbgst_", "chbgvd_", "chbgv_", "chbgvx_", "chbtrd_", "checon_3_", "checon_", "checon_rook_", "cheequb_", "cheev_2stage_", "cheevd_2stage_", "cheevd_", "cheev_", "cheevr_2stage_", "cheevr_", "cheevx_2stage_", "cheevx_", "chegs2_", "chegst_", "chegv_2stage_", "chegvd_", "chegv_", "chegvx_", "cherfs_", "cherfsx_", "chesv_aa_2stage_", "chesv_aa_", "chesv_", "chesv_rk_", "chesv_rook_", "chesvx_", "chesvxx_", "cheswapr_", "chetd2_", "chetf2_", "chetf2_rk_", "chetf2_rook_", "chetrd_2stage_", "chetrd_", "chetrd_he2hb_", "chetrf_aa_2stage_", "chetrf_aa_", "chetrf_", "chetrf_rk_", "chetrf_rook_", "chetri2_", "chetri2x_", "chetri_3_", "chetri_3x_", "chetri_", "chetri_rook_", "chetrs2_", "chetrs_3_", "chetrs_aa_2stage_", "chetrs_aa_", "chetrs_", "chetrs_rook_", "chfrk_", "chgeqz_", "chla_transtype_", "chpcon_", "chpevd_", "chpev_", "chpevx_", "chpgst_", "chpgvd_", "chpgv_", "chpgvx_", "chprfs_", "chpsv_", "chpsvx_", "chptrd_", "chptrf_", "chptri_", "chptrs_", "chsein_", "chseqr_", "dpotrf_", "spotrf_", "zpotrf_", "cpotrf_", "dgesvd_", "sgesvd_", "zgesvd_", "cgesvd_", "dgetrf_", "sgetrf_", "zgetrf_", "cgetrf_"}

FFTW_FUNCTIONS = {"fftw_execute", "fftwf_execute", "fftwl_execute", "fftwq_execute", "fftw_plan_dft", "fftwf_plan_dft", "fftw_plan_dft_1d", "fftwf_plan_dft_1d", "fftw_plan_dft_2d", "fftwf_plan_dft_2d", "fftw_plan_dft_3d", "fftwf_plan_dft_3d", "fftw_plan_many_dft", "fftw_plan_dft_r2c", "fftwf_plan_dft_r2c", "fftw_plan_dft_r2c_1d", "fftwf_plan_dft_r2c_1d", "fftw_plan_dft_r2c_2d", "fftwf_plan_dft_r2c_2d", "fftw_plan_dft_r2c_3d", "fftwf_plan_dft_r2c_3d", "fftw_plan_dft_c2r", "fftw_plan_dft_c2r_1d", "fftw_plan_dft_c2r_2d", "fftw_plan_dft_c2r_3d", "fftw_destroy_plan", "fftwf_destroy_plan", "fftw_mpi_init", "fftw_mpi_plan_dft", "fftw_mpi_plan_dft_2d", "fftw_mpi_plan_dft_3d", "fftw_mpi_execute_dft", "dfftw_destroy_plan_", "dfftw_execute_", "dfftw_execute_dft_", "dfftw_execute_dft_r2c_", "dfftw_plan_dft_1d_", "dfftw_plan_dft_3d_", "dfftw_plan_dft_r2c_1d_", "dfftw_plan_dft_r2c_2d_"}

PBLAS_FUNCTIONS = {"pcagemv_", "pcahemv_", "pcamax_", "pcatrmv_", "pcaxpy_", "pccopy_", "pcdotc_", "pcdotu_", "pcdscal_", "pcgeadd_", "pcgemm_", "pcgemv_", "pcgerc_", "pcgeru_", "pchemm_", "pchemv_", "pcher2_", "pcher2k_", "pcher_", "pcherk_", "pcscal_", "pcswap_", "pcsymm_", "pcsyr2k_", "pcsyrk_", "pctradd_", "pctranc_", "pctranu_", "pctrmm_", "pctrmv_", "pctrsm_", "pctrsv_", "pdgemm_", "pdgemv_", "psgemm_", "psgemv_", "pzgemm_", "pzgemv_"}

SCALAPACK_FUNCTIONS = {"pdgetrf_", "psgetrf_", "pzgetrf_", "pcgetrf_", "pdpotrf_", "pspotrf_", "pzpotrf_", "pcpotrf_", "pdgesvd_", "psgesvd_", "pzgesvd_", "pcgesvd_", "pdgesv_", "psgesv_", "pzgesv_", "pcgesv_", "pdgeqrf_", "psgeqrf_", "pzgeqrf_", "pcgeqrf_"}

# BLAS Level categorization
BLAS_L1 = {"saxpy_", "daxpy_", "caxpy_", "zaxpy_", "scopy_", "dcopy_", "ccopy_", "zcopy_",
           "sscal_", "dscal_", "cscal_", "zscal_", "sswap_", "dswap_", "cswap_", "zswap_",
           "sdot_", "ddot_", "cdotc_", "zdotc_", "cdotu_", "zdotu_", "sasum_", "dasum_",
           "snrm2_", "dnrm2_", "scnrm2_", "dznrm2_", "isamax_", "idamax_", "icamax_", "izamax_"}

BLAS_L2 = {"sgemv_", "dgemv_", "cgemv_", "zgemv_", "sgbmv_", "dgbmv_", "cgbmv_", "zgbmv_",
           "ssymv_", "dsymv_", "chemv_", "zhemv_", "strmv_", "dtrmv_", "ctrmv_", "ztrmv_",
           "sger_", "dger_", "cgerc_", "zgerc_", "cgeru_", "zgeru_"}

BLAS_L3 = {"sgemm_", "dgemm_", "cgemm_", "zgemm_", "ssymm_", "dsymm_", "csymm_", "zsymm_",
           "chemm_", "zhemm_", "strmm_", "dtrmm_", "ctrmm_", "ztrmm_", "strsm_", "dtrsm_",
           "ctrsm_", "ztrsm_", "ssyrk_", "dsyrk_", "csyrk_", "zsyrk_", "cherk_", "zherk_",
           "ssyr2k_", "dsyr2k_", "csyr2k_", "zsyr2k_", "cher2k_", "zher2k_"}


def identify_library(function_name):
    """Identify which library a function belongs to."""
    if not function_name or not isinstance(function_name, str):
        return None

    func = function_name.strip()

    # Check each library
    if func in BLAS_FUNCTIONS:
        return 'BLAS'
    elif func in LAPACK_FUNCTIONS:
        return 'LAPACK'
    elif func in FFTW_FUNCTIONS or 'fftw' in func.lower():
        return 'FFTW'
    elif func in PBLAS_FUNCTIONS:
        return 'PBLAS'
    elif func in SCALAPACK_FUNCTIONS:
        return 'ScaLAPACK'

    return None


def categorize_blas(function_name):
    """Categorize BLAS function by level."""
    if function_name in BLAS_L1:
        return 'L1-Vector'
    elif function_name in BLAS_L2:
        return 'L2-Matrix-Vector'
    elif function_name in BLAS_L3:
        return 'L3-Matrix-Matrix'
    else:
        return 'Other'


def analyze_library_usage(df):
    """Analyze library usage from stats dataframe."""
    library_stats = defaultdict(lambda: {'count': 0, 'time': 0.0, 'functions': defaultdict(int)})
    blas_categories = defaultdict(int)

    for _, row in df.iterrows():
        lib = identify_library(row['function'])
        if lib:
            library_stats[lib]['count'] += row['count']
            library_stats[lib]['time'] += row['total_s']
            library_stats[lib]['functions'][row['function']] += row['count']

            # Categorize BLAS
            if lib == 'BLAS':
                category = categorize_blas(row['function'])
                blas_categories[category] += row['count']

    return dict(library_stats), dict(blas_categories)


def print_library_report(library_stats, blas_categories, output_path):
    """Generate text report of library usage."""
    report_path = output_path.replace('_graphs.png', '_library_report.txt')

    with open(report_path, 'w') as f:
        f.write("=" * 80 + "\n")
        f.write("PEAK LIBRARY USAGE ANALYSIS\n")
        f.write("=" * 80 + "\n\n")

        if not library_stats:
            f.write("No library functions detected in this profile.\n")
            return report_path

        # Overall summary
        total_calls = sum(stats['count'] for stats in library_stats.values())
        total_time = sum(stats['time'] for stats in library_stats.values())

        f.write("LIBRARY SUMMARY\n")
        f.write("-" * 80 + "\n")
        f.write(f"{'Library':<15} {'Calls':<12} {'% Calls':<10} {'Time (s)':<12} {'% Time':<10}\n")
        f.write("-" * 80 + "\n")

        for lib, stats in sorted(library_stats.items(), key=lambda x: x[1]['count'], reverse=True):
            pct_calls = (stats['count'] / total_calls * 100) if total_calls > 0 else 0
            pct_time = (stats['time'] / total_time * 100) if total_time > 0 else 0
            f.write(f"{lib:<15} {stats['count']:<12} {pct_calls:<10.2f} {stats['time']:<12.4f} {pct_time:<10.2f}\n")

        f.write("-" * 80 + "\n")
        f.write(f"{'TOTAL':<15} {total_calls:<12} {100.0:<10.2f} {total_time:<12.4f} {100.0:<10.2f}\n")
        f.write("\n")

        # BLAS breakdown
        if 'BLAS' in library_stats and blas_categories:
            f.write("\nBLAS OPERATION BREAKDOWN\n")
            f.write("-" * 80 + "\n")
            f.write(f"{'Category':<25} {'Calls':<12} {'Percentage':<10}\n")
            f.write("-" * 80 + "\n")
            blas_total = sum(blas_categories.values())
            for cat, count in sorted(blas_categories.items(), key=lambda x: x[1], reverse=True):
                pct = (count / blas_total * 100) if blas_total > 0 else 0
                f.write(f"{cat:<25} {count:<12} {pct:<10.2f}\n")
            f.write("\n")

        # Top functions per library
        f.write("\nTOP FUNCTIONS BY LIBRARY\n")
        f.write("=" * 80 + "\n")

        for lib, stats in sorted(library_stats.items()):
            f.write(f"\n{lib}\n")
            f.write("-" * 80 + "\n")
            f.write(f"{'Function':<40} {'Calls':<12} {'Percentage':<10}\n")
            f.write("-" * 80 + "\n")

            lib_total = stats['count']
            top_funcs = sorted(stats['functions'].items(), key=lambda x: x[1], reverse=True)[:20]

            for func, count in top_funcs:
                pct = (count / lib_total * 100) if lib_total > 0 else 0
                f.write(f"{func:<40} {count:<12} {pct:<10.2f}\n")

            if len(stats['functions']) > 20:
                f.write(f"... and {len(stats['functions']) - 20} more functions\n")

    print(f"Library usage report saved to: {report_path}")
    return report_path


def analyze_memory_log(memlog_path):
    """Analyze PEAK memory log CSV and create visualizations."""
    print(f"Loading memory log from: {memlog_path}")

    # Read memory log
    # Format: ts_ns,delta,current,tid,op
    # op: 1=alloc, 2=free, 3=realloc_old, 4=realloc_new
    df = pd.read_csv(memlog_path)

    # Convert timestamp to seconds for readability
    # FIX: Anchor timestamps to 0 by subtracting the start time
    start_ts = df['ts_ns'].min()
    df['time_s'] = (df['ts_ns'] - start_ts) / 1e9

    df['current_mb'] = df['current'] / 1e6
    df['delta_mb'] = df['delta'] / 1e6

    # Create figure with subplots
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle(f'PEAK Memory Analysis: {Path(memlog_path).name}', fontsize=16)

    # 1. Memory usage over time
    ax1 = axes[0, 0]
    ax1.plot(df['time_s'], df['current_mb'], linewidth=1)
    ax1.set_xlabel('Time (seconds)')
    ax1.set_ylabel('Current Memory (MB)')
    ax1.set_title('Memory Usage Over Time')
    ax1.grid(True, alpha=0.3)

    # 2. Allocation rate (allocations per second)
    ax2 = axes[0, 1]
    alloc_events = df[df['op'].isin([1, 4])]  # alloc and realloc_new
    if len(alloc_events) > 0:
        time_bins = np.linspace(0, df['time_s'].max(), 50)
        alloc_counts, _ = np.histogram(alloc_events['time_s'], bins=time_bins)
        bin_centers = (time_bins[:-1] + time_bins[1:]) / 2
        ax2.bar(bin_centers, alloc_counts, width=np.diff(time_bins), alpha=0.7, edgecolor='black')
        ax2.set_xlabel('Time (seconds)')
        ax2.set_ylabel('Allocations per Bin')
        ax2.set_title('Allocation Rate')
        ax2.grid(True, alpha=0.3)

    # 3. Memory delta distribution
    ax3 = axes[1, 0]
    ax3.hist(df['delta_mb'], bins=50, alpha=0.7, edgecolor='black')
    ax3.set_xlabel('Delta (MB)')
    ax3.set_ylabel('Frequency')
    ax3.set_title('Memory Allocation Size Distribution')
    ax3.grid(True, alpha=0.3)

    # 4. Per-thread memory activity
    ax4 = axes[1, 1]
    thread_activity = df.groupby('tid')['delta_mb'].sum().sort_values(ascending=False)
    ax4.bar(range(len(thread_activity)), thread_activity.values, alpha=0.7, edgecolor='black')
    ax4.set_xlabel('Thread Rank (by total allocation)')
    ax4.set_ylabel('Total Allocated (MB)')
    ax4.set_title('Per-Thread Allocation Activity')
    ax4.grid(True, alpha=0.3)

    plt.tight_layout()
    output_path = memlog_path.replace('.csv', '_graphs.png')
    plt.savefig(output_path, dpi=150)
    print(f"Memory graphs saved to: {output_path}")

    # Print summary statistics
    print("\n=== Memory Log Summary ===")
    print(f"Total events: {len(df)}")
    print(f"Peak memory: {df['current_mb'].max():.2f} MB")
    print(f"Total allocated: {df[df['delta'] > 0]['delta'].sum() / 1e6:.2f} MB")
    print(f"Total freed: {abs(df[df['delta'] < 0]['delta'].sum()) / 1e6:.2f} MB")
    print(f"Unique threads: {df['tid'].nunique()}")
    print(f"Duration: {df['time_s'].max():.2f} seconds")

    return df


def analyze_stats_log(statslog_path):
    """Analyze PEAK stats log CSV and create visualizations."""
    print(f"\nLoading stats log from: {statslog_path}")

    # Read stats log
    # Format: function,count,per_thread,per_rank,call_max_s,call_min_s,total_s,exclusive_s,thread_max_s,thread_min_s,overhead_s
    df = pd.read_csv(statslog_path)

    # Analyze library usage
    library_stats, blas_categories = analyze_library_usage(df)

    # Sort by total time (most time-consuming functions first)
    df = df.sort_values('total_s', ascending=False)

    # Create figure with subplots - now 3x2 to include library analysis
    fig, axes = plt.subplots(3, 2, figsize=(14, 15))
    fig.suptitle(f'PEAK Performance Analysis: {Path(statslog_path).name}', fontsize=16)

    # 1. Top functions by total time
    ax1 = axes[0, 0]
    top_n = min(15, len(df))
    ax1.barh(range(top_n), df['total_s'].head(top_n), alpha=0.7, edgecolor='black')
    ax1.set_yticks(range(top_n))
    ax1.set_yticklabels(df['function'].head(top_n), fontsize=8)
    ax1.set_xlabel('Total Time (seconds)')
    ax1.set_title(f'Top {top_n} Functions by Total Time')
    ax1.invert_yaxis()
    ax1.grid(True, alpha=0.3)

    # 2. Total vs Exclusive time
    ax2 = axes[0, 1]
    ax2.scatter(df['total_s'], df['exclusive_s'], alpha=0.6)
    ax2.plot([0, df['total_s'].max()], [0, df['total_s'].max()], 'r--', alpha=0.5, label='y=x (no children)')
    ax2.set_xlabel('Total Time (s)')
    ax2.set_ylabel('Exclusive Time (s)')
    ax2.set_title('Total vs Exclusive Time')
    ax2.legend()
    ax2.grid(True, alpha=0.3)

    # 3. Call count distribution
    ax3 = axes[1, 0]
    ax3.hist(df['count'], bins=30, alpha=0.7, edgecolor='black')
    ax3.set_xlabel('Call Count')
    ax3.set_ylabel('Number of Functions')
    ax3.set_title('Call Count Distribution')
    ax3.set_xscale('log')
    ax3.grid(True, alpha=0.3)

    # 4. Overhead analysis
    ax4 = axes[1, 1]
    overhead_pct = (df['overhead_s'] / df['total_s'] * 100).replace([np.inf, -np.inf], 0)
    ax4.barh(range(top_n), overhead_pct.head(top_n), alpha=0.7, edgecolor='black')
    ax4.set_yticks(range(top_n))
    ax4.set_yticklabels(df['function'].head(top_n), fontsize=8)
    ax4.set_xlabel('Overhead Percentage (%)')
    ax4.set_title(f'Top {top_n} Functions by Overhead %')
    ax4.invert_yaxis()
    ax4.grid(True, alpha=0.3)

    # 5. Library usage by call count
    ax5 = axes[2, 0]
    if library_stats:
        libs = list(library_stats.keys())
        calls = [library_stats[lib]['count'] for lib in libs]
        colors = plt.cm.Set3(range(len(libs)))
        ax5.pie(calls, labels=libs, autopct='%1.1f%%', colors=colors, startangle=90)
        ax5.set_title('Library Usage by Call Count')
    else:
        ax5.text(0.5, 0.5, 'No library functions detected', ha='center', va='center')
        ax5.set_title('Library Usage by Call Count')

    # 6. BLAS operation breakdown
    ax6 = axes[2, 1]
    if blas_categories:
        categories = list(blas_categories.keys())
        counts = list(blas_categories.values())
        colors = plt.cm.Pastel1(range(len(categories)))
        ax6.pie(counts, labels=categories, autopct='%1.1f%%', colors=colors, startangle=90)
        ax6.set_title('BLAS Operations Breakdown')
    else:
        ax6.text(0.5, 0.5, 'No BLAS functions detected', ha='center', va='center')
        ax6.set_title('BLAS Operations Breakdown')

    plt.tight_layout()
    output_path = statslog_path.replace('.csv', '_graphs.png')
    plt.savefig(output_path, dpi=150)
    print(f"Stats graphs saved to: {output_path}")

    # Generate library usage report
    if library_stats:
        print_library_report(library_stats, blas_categories, output_path)

    # Print summary statistics
    print("\n=== Stats Log Summary ===")
    print(f"Total functions profiled: {len(df)}")
    print(f"Total profiled time: {df['total_s'].sum():.2f} seconds")
    print(f"Total exclusive time: {df['exclusive_s'].sum():.2f} seconds")
    print(f"Total overhead: {df['overhead_s'].sum():.4f} seconds")
    print(f"Total calls: {df['count'].sum()}")

    print("\n=== Top 10 Functions by Total Time ===")
    print(df[['function', 'total_s', 'exclusive_s', 'count']].head(10).to_string(index=False))

    # Print library summary
    if library_stats:
        print("\n=== Library Usage Summary ===")
        total_lib_calls = sum(stats['count'] for stats in library_stats.values())
        total_lib_time = sum(stats['time'] for stats in library_stats.values())
        print(f"{'Library':<15} {'Calls':<12} {'% Calls':<10} {'Time (s)':<12}")
        print("-" * 55)
        for lib, stats in sorted(library_stats.items(), key=lambda x: x[1]['count'], reverse=True):
            pct = (stats['count'] / total_lib_calls * 100) if total_lib_calls > 0 else 0
            print(f"{lib:<15} {stats['count']:<12} {pct:<10.2f} {stats['time']:<12.4f}")

        if 'BLAS' in library_stats:
            print("\n=== BLAS Breakdown ===")
            blas_total = sum(blas_categories.values())
            for cat, count in sorted(blas_categories.items(), key=lambda x: x[1], reverse=True):
                pct = (count / blas_total * 100) if blas_total > 0 else 0
                print(f"  {cat:<20} {count:<12} {pct:.2f}%")

    return df


def main():
    if len(sys.argv) < 2:
        print("Usage: python analysis.py <memlog.csv> [statslog.csv]")
        print("       python analysis.py <statslog.csv>")
        print("Example: python analysis.py peak_mem-p12345.csv peak_stats-p12345.csv")
        sys.exit(1)

    # Determine which files we have based on naming patterns
    memlog_path = None
    statslog_path = None

    for arg in sys.argv[1:]:
        if 'mem' in arg.lower():
            memlog_path = arg
        elif 'stats' in arg.lower():
            statslog_path = arg
        else:
            # Try to guess based on what file exists
            if Path(arg).exists():
                # Could be either, check first
                statslog_path = arg

    # Analyze memory log
    if memlog_path and Path(memlog_path).exists():
        analyze_memory_log(memlog_path)
    elif memlog_path:
        print(f"Warning: Memory log not found: {memlog_path}")

    # Analyze stats log
    if statslog_path and Path(statslog_path).exists():
        analyze_stats_log(statslog_path)
    elif statslog_path:
        print(f"Error: Stats log not found: {statslog_path}")
    elif not memlog_path:
        print("Error: No valid input files provided")
        sys.exit(1)


if __name__ == "__main__":
    main()
