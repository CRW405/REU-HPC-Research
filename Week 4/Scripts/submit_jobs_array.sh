#!/bin/bash
#===============================================================================
# SLURM Job Array Submission Script
#
# Submits job arrays with configurable concurrency limits
#
# Usage:
#   ./submit_jobs.sh <output_dir> [options]
#
# Options:
#   --max-concurrent N    Maximum concurrent tasks (default: 20)
#   --dry-run            Show what would be submitted without submitting
#   --help               Show this help message
#===============================================================================

#===============================================================================
# ARGUMENT PARSING
#===============================================================================

OUTPUT_DIR=""
MAX_CONCURRENT=20
DRY_RUN=false
SHOW_HELP=false

# First positional argument is output directory
if [ $# -eq 0 ]; then
    SHOW_HELP=true
else
    OUTPUT_DIR="$1"
    shift
fi

# Parse remaining options
while [[ $# -gt 0 ]]; do
    case $1 in
        --max-concurrent)
            MAX_CONCURRENT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            SHOW_HELP=true
            shift
            ;;
    esac
done

if [ "$SHOW_HELP" = true ]; then
    head -n 15 "$0" | tail -n +2 | sed 's/^#//'
    exit 0
fi

#===============================================================================
# VALIDATION
#===============================================================================

if [ -z "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory required"
    echo "Usage: $0 <output_dir> [--max-concurrent N] [--dry-run]"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory does not exist: $OUTPUT_DIR"
    exit 1
fi

JOB_ARRAY_SCRIPT="${OUTPUT_DIR}/job_array.slurm"
MANIFEST="${OUTPUT_DIR}/job_manifest.csv"

if [ ! -f "$JOB_ARRAY_SCRIPT" ]; then
    echo "ERROR: Job array script not found: $JOB_ARRAY_SCRIPT"
    echo "Did you run generate_jobs.sh first?"
    exit 1
fi

if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: Job manifest not found: $MANIFEST"
    exit 1
fi

#===============================================================================
# DETERMINE TASK COUNT
#===============================================================================

# Count lines in manifest (excluding header)
TOTAL_TASKS=$(tail -n +2 "$MANIFEST" | wc -l)

if [ $TOTAL_TASKS -eq 0 ]; then
    echo "ERROR: No tasks found in manifest"
    exit 1
fi

#===============================================================================
# DISPLAY SUBMISSION INFO
#===============================================================================

echo "==============================================================================="
echo "SLURM Job Array Submission"
echo "==============================================================================="
echo "Output directory: ${OUTPUT_DIR}"
echo "Job array script: ${JOB_ARRAY_SCRIPT}"
echo "Job manifest: ${MANIFEST}"
echo "Total tasks: ${TOTAL_TASKS}"
echo "Max concurrent: ${MAX_CONCURRENT}"
echo ""

# Show first few tasks as preview
echo "Task Preview (first 5):"
echo "-------------------------------------------------------------------------------"
head -n 6 "$MANIFEST" | column -t -s ','
echo "..."
echo ""

#===============================================================================
# CONSTRUCT SBATCH COMMAND
#===============================================================================

ARRAY_SPEC="0-$((TOTAL_TASKS - 1))"
if [ $MAX_CONCURRENT -gt 0 ]; then
    ARRAY_SPEC="${ARRAY_SPEC}%${MAX_CONCURRENT}"
fi

SBATCH_CMD="sbatch --array=${ARRAY_SPEC} ${JOB_ARRAY_SCRIPT}"

echo "Submission command:"
echo "  ${SBATCH_CMD}"
echo ""

#===============================================================================
# SUBMIT OR DRY RUN
#===============================================================================

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN: Would submit job array but not actually submitting"
    echo ""
    echo "To submit for real, run:"
    echo "  $0 $OUTPUT_DIR --max-concurrent $MAX_CONCURRENT"
    exit 0
fi

# Prompt for confirmation if large job
if [ $TOTAL_TASKS -gt 50 ]; then
    echo "WARNING: You are about to submit ${TOTAL_TASKS} tasks"
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Submission cancelled"
        exit 0
    fi
fi

# Submit the job
echo "Submitting job array..."
SUBMIT_OUTPUT=$(${SBATCH_CMD} 2>&1)
SUBMIT_EXIT=$?

if [ $SUBMIT_EXIT -ne 0 ]; then
    echo "ERROR: Job submission failed!"
    echo "${SUBMIT_OUTPUT}"
    exit 1
fi

echo "${SUBMIT_OUTPUT}"

# Extract job ID
JOB_ID=$(echo "$SUBMIT_OUTPUT" | grep -oP 'Submitted batch job \K\d+')

if [ -z "$JOB_ID" ]; then
    echo "WARNING: Could not extract job ID from output"
    JOB_ID="unknown"
fi

#===============================================================================
# POST-SUBMISSION INFO
#===============================================================================

echo ""
echo "==============================================================================="
echo "Job Array Submitted Successfully!"
echo "==============================================================================="
echo "Job ID: ${JOB_ID}"
echo "Tasks: ${TOTAL_TASKS} (max ${MAX_CONCURRENT} concurrent)"
echo ""
echo "Monitor your jobs:"
echo "  squeue -u \$USER"
echo "  squeue -j ${JOB_ID}"
echo ""
echo "Check specific task status:"
echo "  sacct -j ${JOB_ID}"
echo "  sacct -j ${JOB_ID}.0    # Task 0"
echo "  sacct -j ${JOB_ID}.1    # Task 1"
echo ""
echo "View output logs:"
echo "  ls ${OUTPUT_DIR}/logs/"
echo "  tail -f ${OUTPUT_DIR}/logs/job_${JOB_ID}_*.out"
echo ""
echo "Cancel all tasks:"
echo "  scancel ${JOB_ID}"
echo ""
echo "Cancel specific task:"
echo "  scancel ${JOB_ID}_0    # Cancel task 0"
echo ""
echo "View timing summary (after completion):"
echo "  column -t -s, ${OUTPUT_DIR}/timing_summary.csv | less -S"
echo "==============================================================================="

# Save job ID for reference
echo "${JOB_ID}" > "${OUTPUT_DIR}/job_id.txt"
echo "Job ID saved to: ${OUTPUT_DIR}/job_id.txt"
