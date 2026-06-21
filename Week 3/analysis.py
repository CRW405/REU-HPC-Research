import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import sys
from pathlib import Path

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

    # Sort by total time (most time-consuming functions first)
    df = df.sort_values('total_s', ascending=False)

    # Create figure with subplots
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
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

    plt.tight_layout()
    output_path = statslog_path.replace('.csv', '_graphs.png')
    plt.savefig(output_path, dpi=150)
    print(f"Stats graphs saved to: {output_path}")

    # Print summary statistics
    print("\n=== Stats Log Summary ===")
    print(f"Total functions profiled: {len(df)}")
    print(f"Total profiled time: {df['total_s'].sum():.2f} seconds")
    print(f"Total exclusive time: {df['exclusive_s'].sum():.2f} seconds")
    print(f"Total overhead: {df['overhead_s'].sum():.4f} seconds")
    print(f"Total calls: {df['count'].sum()}")

    print("\n=== Top 10 Functions by Total Time ===")
    print(df[['function', 'total_s', 'exclusive_s', 'count']].head(10).to_string(index=False))

    return df

def main():
    if len(sys.argv) < 2:
        print("Usage: python peak_analyzer.py <memlog.csv> [statslog.csv]")
        print("Example: python peak_analyzer.py peak_memlog-p12345.csv peak_statslog-p12345.csv")
        sys.exit(1)

    memlog_path = sys.argv[1]
    statslog_path = sys.argv[2] if len(sys.argv) > 2 else None

    # Analyze memory log
    if Path(memlog_path).exists():
        analyze_memory_log(memlog_path)
    else:
        print(f"Error: Memory log not found: {memlog_path}")

    # Analyze stats log if provided
    if statslog_path and Path(statslog_path).exists():
        analyze_stats_log(statslog_path)
    elif statslog_path:
        print(f"Error: Stats log not found: {statslog_path}")

if __name__ == "__main__":
    main()
