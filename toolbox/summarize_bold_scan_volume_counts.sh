#!/bin/bash
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: May 19, 2025
# @Description: Diagnostic tool to compare actual vs expected volumes in scan files

module load python/3.9.0
module load biology
module load fsl/5.0.10

source ./settings.sh

OUTPUT_DIR="${SLURM_LOG_DIR}/diagnostics"
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

# Determine which subjects file to use
if [ -v subjects_mapping ] && [ ${#subjects_mapping[@]} -gt 0 ] && [ -v "subjects_mapping[$JOB_NAME]" ]; then
  SUBJECTS_FILE="${subjects_mapping[$JOB_NAME]}"
  echo "[INFO] Using step-specific subjects file: ${SUBJECTS_FILE}"
else
  SUBJECTS_FILE="all-subjects.txt"
  echo "[INFO] Using default subjects file: ${SUBJECTS_FILE}"
fi

while read -r subject_id; do
  subject="sub-${subject_id}"
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
    check_volumes "${fieldmap_file}" "${EXPECTED_FMAP_VOLS}" "FIELDMAP" "${run_fmap}" "${subject_id}"
  done

  echo "[INFO] Completed volume check for subject ${subject_id}"
done < "${SUBJECTS_FILE}"
