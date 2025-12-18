#!/bin/sh

# Skip subjects file prompt since this step runs one subject at a time
export SKIP_SUBJECTS_PROMPT=true
source ./load_config.sh

STEP_NAME="02-dcm2niix"
JOB_NAME="fmriprep-workbench-2"
FW_SESHID=$1
NEW_SUBID=$2
SKIP_TAR_FLAG=$3

# create log dirs
mkdir -p ${SLURM_LOG_DIR}/${STEP_NAME}

array_opt="--array=0"

# echo slurm job params for inline validation
echo "($(date)) [INFO] - SLURM JOB PARAMETERS:"
echo "  --job-name: ${JOB_NAME}"
echo "  ${array_opt}"
echo "  --time: ${DCMNIIX_SLURM_TIME}"
echo "  --mem-per-cpu: ${SLURM_MEM}"
echo "  --cpus-per-task: ${SLURM_CPUS}"
echo "  --partition: ${SLURM_PARTITION}"
echo "  --output: ${SLURM_LOG_DIR}/${STEP_NAME}/%x_%A_%a.out"
echo "  --error: ${SLURM_LOG_DIR}/${STEP_NAME}/%x_%A_%a.err"
echo "  --mail-type: BEGIN,END,FAIL"
echo "  --mail-user: ${SLURM_EMAIL}"

# submit slurm job
sbatch \
    --job-name=${JOB_NAME} \
    ${array_opt} \
    --time=${DCMNIIX_SLURM_TIME} \
    --mem-per-cpu=${SLURM_MEM} \
    --cpus-per-task=${SLURM_CPUS} \
    --partition=${SLURM_PARTITION} \
    --output=${SLURM_LOG_DIR}/${STEP_NAME}/%x_%A_%a.out \
    --error=${SLURM_LOG_DIR}/${STEP_NAME}/%x_%A_%a.err \
    --mail-type=BEGIN,END,FAIL \
    --mail-user=${SLURM_EMAIL} \
    ./${STEP_NAME}/dcm2niix.sh ${STEP_NAME} ${FW_SESHID} ${NEW_SUBID} ${SKIP_TAR_FLAG}
