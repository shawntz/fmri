#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: May 17, 2025
# @Description: QC Step 4 - Verify DICOM → NIfTI → BIDS metadata conversion

JOB_NAME=$1

source ./load_config.sh

# Get subject ID from SLURM array task ID
if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
  subject_line=$((SLURM_ARRAY_TASK_ID + 1))
  subject_entry=$(sed -n "${subject_line}p" "${SELECTED_SUBJECTS_FILE}")

  # Parse subject modifiers
  source ./toolbox/parse_subject_modifiers.sh
  parse_subject_modifiers "${subject_entry}" "${JOB_NAME}"

  # Check if should skip this subject
  if [ "${SHOULD_SKIP}" = true ]; then
    echo "($(date)) [INFO] Skipping subject ${SUBJECT_ID} due to skip modifier"
    exit 0
  fi

  new_subid="${SUBJECT_ID}"
else
  echo "($(date)) [ERROR] SLURM_ARRAY_TASK_ID not set. This script must be run as a SLURM array job."
  exit 1
fi

subject="sub-${new_subid}"

echo "($(date)) [INFO] =========================================="
echo "($(date)) [INFO] Processing subject: ${subject}"
echo "($(date)) [INFO] =========================================="

module load python/3.9.0

echo "($(date)) [INFO] Running header-based QC"

python3 "${SCRIPTS_DIR}/toolbox/verify_nii_metadata.py" \
  --subid "${new_subid}" \
  --project_dir "${BASE_DIR}" \
  --task_id "${task_id}" \
  --new_task_id "${new_task_id}" \
  --config_path "${CONFIG_FILE}" \
  --log_out_dir "${SLURM_LOG_DIR}"

if [ $? -eq 0 ]; then
  echo "($(date)) [SUCCESS] Metadata verification completed for ${subject}"
  echo "${new_subid}" >> ${JOB_NAME}-processed_subjects.txt
else
  echo "($(date)) [ERROR] Metadata verification failed for ${subject}"
  exit 1
fi
