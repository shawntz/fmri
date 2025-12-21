#!/bin/bash
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: December 17, 2025
# @Description: Run FSL FEAT Level 2 (subject-level) GLM analysis
# @Param: JOB_NAME (positional argument #1) - required job name string
# @Param: MODEL_NAME (positional argument #2) - GLM model name
# @Param: NO_FEAT (optional flag) - pass '--no-feat' to only create FSF files without running FEAT

# Source configuration
source ../load_config.sh

JOB_NAME=$1
MODEL_NAME=$2
NO_FEAT_FLAG=""

# Check for --no-feat flag in arguments
for arg in "$@"; do
  if [ "$arg" = "--no-feat" ]; then
    NO_FEAT_FLAG="--nofeat"
    echo "($(date)) [INFO] No-feat mode enabled - will only create FSF files" | tee -a "${log_file}"
    break
  fi
done

if [ -z "${JOB_NAME}" ]; then
  echo "Error: Job name not provided" | tee -a "${log_file}"
  echo "Usage: $0 <job-name> <model-name> [--no-feat]" | tee -a "${log_file}"
  exit 1
fi

if [ -z "${MODEL_NAME}" ]; then
  echo "Error: Model name not provided" | tee -a "${log_file}"
  echo "Usage: $0 <job-name> <model-name> [--no-feat]" | tee -a "${log_file}"
  exit 1
fi

# Setup logging
mkdir -p "${SLURM_LOG_DIR}/fsl-glm"
log_file="${SLURM_LOG_DIR}/fsl-glm/${MODEL_NAME}_level2_processing.log"

echo "($(date)) [INFO] Starting FSL FEAT Level 2 analysis for model: ${MODEL_NAME}" | tee -a "${log_file}"

# Get study info
STUDY_ID=$(basename "$BASE_DIR")
BASE_DIR_PARENT=$(dirname "$BASE_DIR")

# Check if model directory exists
MODEL_DIR="${BASE_DIR}/model/level2/model-${MODEL_NAME}"
if [ ! -d "$MODEL_DIR" ]; then
    echo "Error: Model directory does not exist: $MODEL_DIR" | tee -a "${log_file}"
    echo "Please ensure level 1 analysis is complete" | tee -a "${log_file}"
    exit 1
fi

echo "($(date)) [INFO] Model directory: ${MODEL_DIR}" | tee -a "${log_file}"

# Load Python module
module load python/3.9.0

# Run the Python script
echo "($(date)) [INFO] Running level 2 FEAT analysis" | tee -a "${log_file}"

python3 "$(dirname "$0")/run_level2.py" \
  --email "${SLURM_USER_EMAIL}" \
  --account "${SLURM_ACCOUNT}" \
  --time "${SLURM_TIME_LIMIT}" \
  --nodes 1 \
  --mem ${SLURM_MEMORY_MB} \
  --studyid "${STUDY_ID}" \
  --basedir "${BASE_DIR_PARENT}" \
  --modelname "${MODEL_NAME}" \
  --outdir "${SLURM_LOG_DIR}/fsl-glm" \
  ${NO_FEAT_FLAG}

if [ $? -eq 0 ]; then
    echo "($(date)) [INFO] Successfully completed Level 2 FEAT analysis for model: ${MODEL_NAME}" | tee -a "${log_file}"
else
    echo "($(date)) [ERROR] Level 2 FEAT analysis failed for model: ${MODEL_NAME}" | tee -a "${log_file}"
    exit 1
fi
