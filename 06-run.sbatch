#!/bin/sh

source ./settings.sh

JOB_NAME="06-run-fmriprep"
ANAT_ONLY_FLAG=$1  # optional setting for anat-only processing

# create log dirs
mkdir -p ${SLURM_LOG_DIR}/${JOB_NAME}

# check if running in debug mode
if [ "$DEBUG" = "1" ]; then
    echo "($(date)) [INFO] Running in DEBUG mode with single subject"
    array_opt="--array=0"
else
    echo "($(date)) [INFO] Running full array: ${FMRIPREP_SLURM_ARRAY_SIZE}%${SLURM_ARRAY_THROTTLE}"
    array_opt="--array=${FMRIPREP_SLURM_ARRAY_SIZE}%${SLURM_ARRAY_THROTTLE}"
fi

# echo slurm job params for inline validation
echo "($(date)) [INFO] - SLURM JOB PARAMETERS:"
echo "  --job-name: ${FMRIPREP_SLURM_JOB_NAME}"
echo "  ${array_opt}"
echo "  --time: ${FMRIPREP_SLURM_TIME}"
echo "  --mem-per-cpu: ${FMRIPREP_SLURM_MEM_PER_CPU}"
echo "  --cpus-per-task: ${FMRIPREP_SLURM_CPUS_PER_TASK}"
echo "  --partition: ${SLURM_PARTITION}"
echo "  --output: ${SLURM_LOG_DIR}/${JOB_NAME}/%x_%A_%a.out"
echo "  --error: ${SLURM_LOG_DIR}/${JOB_NAME}/%x_%A_%a.err"
echo "  --mail-type: BEGIN,END,FAIL"
echo "  --mail-user: ${SLURM_EMAIL}"

cmd="sbatch \
    --job-name=${FMRIPREP_SLURM_JOB_NAME} \
    ${array_opt} \
    --time=${FMRIPREP_SLURM_TIME} \
    --mem-per-cpu=${FMRIPREP_SLURM_MEM_PER_CPU} \
    --cpus-per-task=${FMRIPREP_SLURM_CPUS_PER_TASK} \
    --partition=${SLURM_PARTITION} \
    --output=${SLURM_LOG_DIR}/${JOB_NAME}/%x_%A_%a.out \
    --error=${SLURM_LOG_DIR}/${JOB_NAME}/%x_%A_%a.err \
    --mail-type=BEGIN,END,FAIL \
    --mail-user=${SLURM_EMAIL} \
    ./${JOB_NAME}/run_fmriprep.sh ${JOB_NAME}"

# add anat-only flag if specified
# if [ ! -z "${ANAT_ONLY_FLAG}" ]; then
#     cmd="${cmd} --anat-only"
# fi
cmd="${cmd} --anat-only"

# submit job
echo "($(date)) [INFO] Submitting job with command:"
echo "${cmd}"
eval ${cmd}
