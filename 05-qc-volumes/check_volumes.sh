#!/bin/bash
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: May 19, 2025
# @Description: QC Step 5 - Verify scan volume counts match expected values

JOB_NAME=$1

module load python/3.9.0
module load biology
module load fsl/5.0.10

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

  subject_id="${SUBJECT_ID}"
else
  echo "($(date)) [ERROR] SLURM_ARRAY_TASK_ID not set. This script must be run as a SLURM array job."
  exit 1
fi

subject="sub-${subject_id}"

# logging setup
processed_file="${SLURM_LOG_DIR}/${JOB_NAME}-processed_subjects.txt"

echo "($(date)) [INFO] =========================================="
echo "($(date)) [INFO] Processing subject: ${subject}"
echo "($(date)) [INFO] =========================================="

# Create timestamped output directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="${SLURM_LOG_DIR}/diagnostics/${TIMESTAMP}_${subject_id}"
mkdir -p "${OUTPUT_DIR}"

CSV_FILE="${OUTPUT_DIR}/scan_volumes_summary.csv"
echo "subject_id,scan_type,run_number,file_path,expected_volumes,actual_volumes,status" > "${CSV_FILE}"

# Function to check volumes and append to CSV
check_volumes() {
  _file="$1"
  _expected="$2"
  _scan_type="$3"
  _run="$4"
  _subid="$5"

  # Skip if file doesn't exist
  if [ ! -f "${_file}" ]; then
    echo "${_subid},${_scan_type},${_run},${_file},${_expected},FILE_NOT_FOUND,ERROR" >> "${CSV_FILE}"
    echo "[WARNING] File not found: ${_file}"
    return 1
  fi

  # Get actual volume count
  _actual=$(fslnvols ${_file})

  # Determine status
  if [ "${_actual}" -ne "${_expected}" ]; then
    _status="ERROR"
    echo "[ERROR] Volume mismatch in ${_file}: Expected ${_expected}, found ${_actual}"
  else
    _status="OK"
    echo "[INFO] Volume check passed for ${_file}: ${_actual} volumes"
  fi

  echo "${_subid},${_scan_type},${_run},${_file},${_expected},${_actual},${_status}" >> "${CSV_FILE}"

  return 0
}

echo "[INFO] Processing subject ${subject_id}"

# Check each BOLD run (pre-trimming)
for run_bold in "${run_numbers[@]}"; do
  bold_pattern="${RAW_DIR}/${subject}/func/${subject}_task-*_run-${run_bold}_dir-PA_bold.nii.gz"
  bold_files=( $bold_pattern )

  if [ ${#bold_files[@]} -eq 0 ]; then
    # No matching files found
    echo "${subject_id},BOLD,${run_bold},${bold_pattern},${EXPECTED_BOLD_VOLS},FILE_NOT_FOUND,ERROR" >> "${CSV_FILE}"
    echo "[WARNING] No BOLD file found for subject ${subject_id}, run ${run_bold}"
  elif [ ${#bold_files[@]} -gt 1 ]; then
    # Multiple matching files found (unusual case)
    echo "[WARNING] Multiple BOLD files found for subject ${subject_id}, run ${run_bold}. Checking all."
    for bold_file in "${bold_files[@]}"; do
      # Extract task ID from filename
      task_name=$(basename "$bold_file" | sed -n 's/.*_task-\([^_]*\)_.*/\1/p')
      check_volumes "${bold_file}" "${EXPECTED_BOLD_VOLS}" "BOLD-${task_name}" "${run_bold}" "${subject_id}"
    done
  else
    # One matching file found (normal case)
    bold_file="${bold_files[0]}"
    # Extract task ID from filename
    task_name=$(basename "$bold_file" | sed -n 's/.*_task-\([^_]*\)_.*/\1/p')
    check_volumes "${bold_file}" "${EXPECTED_BOLD_VOLS}" "BOLD-${task_name}" "${run_bold}" "${subject_id}"
  fi

  # Check corresponding fieldmap based on mapping
  run_fmap=${fmap_mapping[$run_bold]}
  fieldmap_file="${RAW_DIR}/${subject}/fmap/${subject}_run-${run_fmap}_dir-AP_epi.nii.gz"
  check_volumes "${fieldmap_file}" "${EXPECTED_FMAP_VOLS}" "FIELDMAP" "${run_fmap}" "${subject_id}"
done

# Check each BOLD run (post-trimming)
for run_bold in "${run_numbers[@]}"; do
  bold_pattern="${TRIM_DIR}/${subject}/func/${subject}_task-*_run-${run_bold}_dir-PA_bold.nii.gz"
  bold_files=( $bold_pattern )

  # Default task_name to new_task_id from settings if not found
  task_name="${new_task_id}"

  if [ ${#bold_files[@]} -eq 0 ]; then
    # No matching files found
    echo "${subject_id},BOLD,${run_bold},${bold_pattern},${EXPECTED_BOLD_VOLS_AFTER_TRIMMING},FILE_NOT_FOUND,ERROR" >> "${CSV_FILE}"
    echo "[WARNING] No BOLD file found for subject ${subject_id}, run ${run_bold}"
  elif [ ${#bold_files[@]} -gt 1 ]; then
    # Multiple matching files found (unusual case)
    echo "[WARNING] Multiple BOLD files found for subject ${subject_id}, run ${run_bold}. Checking all."
    for bold_file in "${bold_files[@]}"; do
      # Extract task ID from filename
      task_name=$(basename "$bold_file" | sed -n 's/.*_task-\([^_]*\)_.*/\1/p')
      check_volumes "${bold_file}" "${EXPECTED_BOLD_VOLS_AFTER_TRIMMING}" "BOLD-${task_name}" "${run_bold}" "${subject_id}"
    done
  else
    # One matching file found (normal case)
    bold_file="${bold_files[0]}"
    # Extract task ID from filename
    task_name=$(basename "$bold_file" | sed -n 's/.*_task-\([^_]*\)_.*/\1/p')
    check_volumes "${bold_file}" "${EXPECTED_BOLD_VOLS_AFTER_TRIMMING}" "BOLD-${task_name}" "${run_bold}" "${subject_id}"
  fi

  # Check corresponding fieldmap based on mapping
  run_fmap=${fmap_mapping[$run_bold]}
  fieldmap_file="${TRIM_DIR}/${subject}/fmap/${subject}_acq-${task_name}_run-${run_fmap}_dir-AP_epi.nii.gz"
  fmap_remain_vols=$((EXPECTED_FMAP_VOLS - n_dummy))
  check_volumes "${fieldmap_file}" "${fmap_remain_vols}" "FIELDMAP" "${run_fmap}" "${subject_id}"
done

echo "[INFO] Completed volume check for subject ${subject_id}"

# Generate summary report using Python script
python3 "${SCRIPTS_DIR}/toolbox/summarize_diagnostics.py" --csv "${CSV_FILE}" --output-dir "${OUTPUT_DIR}"

# Check if there were any errors in the CSV
error_count=$(grep -c ",ERROR$" "${CSV_FILE}" || true)

if [ "$error_count" -gt 0 ]; then
  echo "($(date)) [ERROR] Volume check failed for ${subject} with ${error_count} errors"
  echo "($(date)) [INFO] Results saved to: ${OUTPUT_DIR}"
  exit 1
else
  echo "($(date)) [SUCCESS] Volume check passed for ${subject}"
  echo "($(date)) [INFO] Results saved to: ${OUTPUT_DIR}"
  echo "${subject_id}" >> "${processed_file}"
  exit 0
fi
