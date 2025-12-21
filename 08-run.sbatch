#!/bin/bash
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: December 17, 2025
# @Description: SLURM job submission wrapper for FSL FEAT Level 1 GLM analysis
# @Usage: ./08-run.sbatch <model-name> [--no-feat]

STEP_NAME="10-fsl-glm"
JOB_NAME="fmriprep-workbench-8"

# Source configuration
source ./load_config.sh

# Get model name from command line argument
MODEL_NAME=$1

if [ -z "$MODEL_NAME" ]; then
    echo "Error: Model name is required"
    echo "Usage: $0 <model-name> [--no-feat]"
    echo ""
    echo "If you haven't created a model yet, run: ./10-fsl-glm/setup_glm.sh"
    exit 1
fi

# Check for optional --no-feat flag
NO_FEAT_FLAG=""
if [ "$2" = "--no-feat" ]; then
    NO_FEAT_FLAG="--no-feat"
    echo "Note: Running in no-feat mode - will only create FSF files"
fi

# Create log directories
mkdir -p ${SLURM_LOG_DIR}/${STEP_NAME}
mkdir -p ${SLURM_LOG_DIR}/fsl-glm

echo "Submitting FSL FEAT Level 1 GLM analysis job for model: ${MODEL_NAME}"
echo "Job name: ${JOB_NAME}"
echo "Log directory: ${SLURM_LOG_DIR}/${STEP_NAME}"

# The run_level1_glm.sh script will handle creating and submitting the job array
# It integrates directly with run_level1.py which manages SLURM submission
bash ./${STEP_NAME}/run_level1_glm.sh "${JOB_NAME}" "${MODEL_NAME}" ${NO_FEAT_FLAG}

if [ $? -eq 0 ]; then
    echo "✓ Level 1 GLM analysis job submitted successfully"
    echo ""
    echo "Monitor job status with: squeue -u \$USER"
    echo "Check logs in: ${SLURM_LOG_DIR}/fsl-glm/"
else
    echo "✗ Error submitting Level 1 GLM analysis job"
    exit 1
fi
