#!/bin/sh

source ./settings.sh

JOB_NAME="04-prep-fmriprep"

# create log dirs
mkdir -p ${SLURM_LOG_DIR}/${JOB_NAME}

# check if running in debug mode
if [ "$DEBUG" = "1" ]; then
    echo "($(date)) [INFO] Running in DEBUG mode with single subject"
    array_opt="--array=0"
else
    echo "($(date)) [INFO] Running full array: ${SLURM_ARRAY_SIZE}%${SLURM_ARRAY_THROTTLE}"
    array_opt="--array=${SLURM_ARRAY_SIZE}%${SLURM_ARRAY_THROTTLE}"
fi

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
    ./${JOB_NAME}/prepare_fmri.sh ${JOB_NAME}
