#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: February 1, 2025
# @Description: Trigger fMRIPrep workflow.
# @Params: ANAT_ONLY_FLAG (positional argument #1) - optional setting to speed up freesurfer before manual surface editing

source ./settings.sh

ANAT_ONLY_FLAG=$1

# get subject ID from array task ID
subject_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" 02-subjects.txt)
subject="sub-${subject_id}"

# logging setup
mkdir -p "${SLURM_LOG_DIR}/subjects"
log_file="${SLURM_LOG_DIR}/subjects/${subject}_processing.log"
processed_file="${SLURM_LOG_DIR}/02-processed_subjects.txt"

# setup dirs (if needed)
mkdir -p ${DERIVS_DIR}
mkdir -p ${TEMPLATEFLOW_HOST_HOME}
mkdir -p ${FMRIPREP_HOST_CACHE}

# clean up caches
rm -rf ${TEMPLATEFLOW_HOST_HOME}
rm -rf ${FMRIPREP_HOST_CACHE}

# set environment vars
export FS_LICENSE=${FREESURFER_LICENSE}
export APPTAINERENV_TEMPLATEFLOW_HOME="/templateflow"

# check if this subject was already processed
if [ -f "${processed_file}" ]; then
    if grep -q "^${subject_id}$" ${processed_file}; then
		echo "($(date)) [INFO] Subject ${subject_id} has already undergone fMRIPrep, skipping" | tee -a ${log_file}
        exit 0
    fi
fi

echo "($(date)) [INFO] Triggering fMRIPrep for subject ${subject_id}" | tee -a ${log_file}

# config singularity command
SINGULARITY_CMD="singularity run --cleanenv \
    -B ${TRIM_DIR}:/data \
    -B ${TEMPLATEFLOW_HOST_HOME}:${APPTAINERENV_TEMPLATEFLOW_HOME} \
    -B ${L_SCRATCH}:/work \
    ${SINGULARITY_IMAGE_DIR}/${SINGULARITY_IMAGE}"

# base fMRIPrep command
cmd="${SINGULARITY_CMD} ${TRIM_DIR} ${DERIVS_DIR} participant \
    --participant-label ${subject} -w /work/ -vv \
    --omp-nthreads ${FMRIPREP_OMP_THREADS} \
    --nthreads ${FMRIPREP_NTHREADS} \
    --mem_mb ${FMRIPREP_MEM_MB} \
    --skip_bids_validation \
    --fs-license-file ${FS_LICENSE} \
    --skull-strip-t1w force \
    --dummy-scans 0 \
    --fd-spike-threshold ${FMRIPREP_FD_SPIKE_THRESHOLD} \
    --dvars-spike-threshold ${FMRIPREP_DVARS_SPIKE_THRESHOLD} \
    --output-spaces ${FMRIPREP_OUTPUT_SPACES}"

# add anat-only flag if specified
if [ "${ANAT_ONLY_FLAG}" = "--anat-only" ]; then
    cmd="${cmd} --anat-only"
    echo "($(date)) [INFO] Running anatomical processing only" | tee -a ${log_file}
fi

# execute and log
echo "($(date)) [INFO] Running task ${SLURM_ARRAY_TASK_ID}" | tee -a ${log_file}
echo "($(date)) [INFO] Command: ${cmd}" | tee -a ${log_file}

eval ${cmd}
exitcode=$?

echo -e "${subject}\t${SLURM_ARRAY_TASK_ID}\t${exitcode}" \
    >> ${WORKFLOW_LOG_DIR}/${SLURM_JOB_NAME}.${SLURM_ARRAY_JOB_ID}.tsv

echo "($(date)) [INFO] Finished task ${SLURM_ARRAY_TASK_ID} with exit code ${exitcode}" | tee -a ${log_file}
exit ${exitcode}
