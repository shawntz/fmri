#!/bin/sh
#
#SBATCH --job-name=01_prepare
#SBATCH --time=${SLURM_TIME}
#SBATCH --mem=${SLURM_MEM}
#SBATCH --cpus-per-task=${SLURM_CPUS}
#SBATCH --array=${SLURM_ARRAY_SIZE}%${SLURM_ARRAY_THROTTLE}
#SBATCH --output=${SLURM_LOG_DIR}/01_prepare/%x_%A_%a.out
#SBATCH --error=${SLURM_LOG_DIR}/01_prepare/%x_%A_%a.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=${SLURM_EMAIL}

JOB_NAME="01_prepare"

source ./../settings.sh

# create log dirs
mkdir -p ${SLURM_LOG_DIR}/${JOB_NAME}

# check if running in debug mode
if [ "$DEBUG" = "1" ]; then
    echo "Running in DEBUG mode with single subject"
    array_opt="--array=0"
else
    echo "Running full array: ${SLURM_ARRAY_SIZE}%${SLURM_ARRAY_THROTTLE}"
    array_opt="--array=${SLURM_ARRAY_SIZE}%${SLURM_ARRAY_THROTTLE}"
fi

# submit slurm job
sbatch \
    --job-name=${JOB_NAME} \
    ${array_opt} \
    --time=${SLURM_TIME} \
    --mem=${SLURM_MEM} \
    --cpus-per-task=${SLURM_CPUS} \
    --output=${SLURM_LOG_DIR}/%x_%A_%a.out \
    --error=${SLURM_LOG_DIR}/%x_%A_%a.err \
    --mail-type=BEGIN,END,FAIL \
    --mail-user=${SLURM_EMAIL} \
    prepare_fmri.sh
