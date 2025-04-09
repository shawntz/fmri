#!/bin/sh

source ./settings.sh

JOB_NAME="01-fw2server"
FW_SUBID=$1
FW_SESHID=$2
NEW_SUBID=$3

# create log dirs
mkdir -p ${SLURM_LOG_DIR}/${JOB_NAME}

array_opt="--array=0"

# echo slurm job params for inline validation
echo "($(date)) [INFO] - SLURM JOB PARAMETERS:"
echo "  --job-name: ${JOB_NAME}"
echo "  ${array_opt}"
echo "  --time: ${SLURM_TIME}"
echo "  --mem-per-cpu: ${SLURM_MEM}"
echo "  --cpus-per-task: ${SLURM_CPUS}"
echo "  --partition: ${SLURM_PARTITION}"
echo "  --output: ${SLURM_LOG_DIR}/${JOB_NAME}/%x_%A_%a.out"
echo "  --error: ${SLURM_LOG_DIR}/${JOB_NAME}/%x_%A_%a.err"
echo "  --mail-type: BEGIN,END,FAIL"
echo "  --mail-user: ${SLURM_EMAIL}"

# submit slurm job
sbatch \
    --job-name=${JOB_NAME} \
    ${array_opt} \
    --time=${SLURM_TIME} \
    --mem-per-cpu=${SLURM_MEM} \
    --cpus-per-task=${SLURM_CPUS} \
    --partition=${SLURM_PARTITION} \
    --output=${SLURM_LOG_DIR}/${JOB_NAME}/%x_%A_%a.out \
    --error=${SLURM_LOG_DIR}/${JOB_NAME}/%x_%A_%a.err \
    --mail-type=BEGIN,END,FAIL \
    --mail-user=${SLURM_EMAIL} \
    ./${JOB_NAME}/download.sh ${JOB_NAME} ${FW_SUBID} ${FW_SESHID} ${NEW_SUBID}
