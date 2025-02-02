#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: February 1, 2025
# @Description: Trigger fMRIPrep workflow.
# @Param: JOB_NAME (positional argument #1) - required job name string (e.g., "02-fmriprep")
# @Param: ANAT_ONLY_FLAG (positional argument #2) - optional setting to speed up freesurfer before manual surface editing

source ./settings.sh

JOB_NAME=$1
if [ -z "${JOB_NAME}" ]; then
    echo "Error: Pipeline step name not provided" | tee -a ${log_file}
    echo "Usage: $0 <step-name>" | tee -a ${log_file}
    exit 1
fi

ANAT_ONLY_FLAG=$2

# determine which subjects file to use
if [ -v subjects_mapping ] && [ ${#subjects_mapping[@]} -gt 0 ] && [ -v "subjects_mapping[$JOB_NAME]" ]; then
    # use step-specific subjects file from the mapping defined in settings.sh
    SUBJECTS_FILE="${subjects_mapping[$JOB_NAME]}"
    echo "($(date)) [INFO] Using step-specific subjects file: ${SUBJECTS_FILE}" | tee -a ${log_file}
else
    # fall back to default all-subjects.txt
    SUBJECTS_FILE="all-subjects.txt"
    echo "($(date)) [INFO] No specific subjects file mapped for ${JOB_NAME}, using default: ${SUBJECTS_FILE}" | tee -a ${log_file}
fi

# get current subject ID from list
subject_id=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" "${SUBJECTS_FILE}")
if [ -z "${subject_id}" ]; then
    echo "Error: No subject found at index $((SLURM_ARRAY_TASK_ID+1)) in ${SUBJECTS_FILE}" | tee -a ${log_file}
    exit 1
fi
subject="sub-${subject_id}"

# logging setup
mkdir -p "${SLURM_LOG_DIR}/subjects"
log_file="${SLURM_LOG_DIR}/subjects/${subject}_processing.log"
processed_file="${SLURM_LOG_DIR}/02-processed_subjects.txt"

# first clean up caches
rm -rf ${TEMPLATEFLOW_HOST_HOME}
rm -rf ${FMRIPREP_HOST_CACHE}

# setup dirs (if needed)
mkdir -p ${DERIVS_DIR}
mkdir -p ${TEMPLATEFLOW_HOST_HOME}
mkdir -p ${FMRIPREP_HOST_CACHE}
mkdir -p ${WORKFLOW_LOG_DIR}

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
    -B ${SCRATCH}:/work \
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

echo ${subject_id} >> ${processed_file}
echo "($(date)) [INFO] Finished task ${SLURM_ARRAY_TASK_ID} with exit code ${exitcode}" | tee -a ${log_file}
exit ${exitcode}
