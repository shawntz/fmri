#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: January 30, 2025
# @Description: Prepare bold/fmap data for fmriprep.
# @Param: JOB_NAME (positional argument #1) - required job name string (e.g., "02-fmriprep")

umask 002  # modify permissions so fslroi inherits correct permissions

# fslroi - extract region of interest (ROI) from an image. 
# You can a) take a 3D ROI from a 3D data set (or if it is 4D, 
# the same ROI is taken from each time point and a new 4D data set is created), 
# b) extract just some time points from a 4D data set, 
# or c) control time and space limits to the ROI. 
# 
# Note that the arguments are minimum index and size (not maximum index). 
# So to extract voxels 10 to 12 inclusive you would specify 10 and 3 (not 10 and 12).
#
# fslroi uses 0 indexing, so here if we have a scan with 220 volumes and we want to
# trim off the first 5 "lead-in" volumes, the two args we'd pass to fslroi would be:
# 5, 215 (since index == 5 is the starting volume, i.e., volume 6; and, 220 - 5 == 215
# is the number of volumes that we want to extract)

source ./settings.sh

JOB_NAME=$1
if [ -z "${JOB_NAME}" ]; then
  echo "Error: Pipeline step name not provided" | tee -a "${log_file}"
  echo "Usage: $0 <step-name>" | tee -a "${log_file}"
  exit 1
fi

# TEST: method to validate volume counts
validate_volumes() {
  _file="$1"
  _expected="$2"
  _desc="$3"
  _actual=$(fslnvols ${_file})
  
  if [ "${_actual}" -ne "${_expected}" ]; then
    echo "($(date)) [ERROR] Unexpected number of volumes in ${_desc}" | tee -a "${log_file}"
    echo "($(date)) [ERROR] Expected ${_expected} volumes but found ${_actual}" | tee -a "${log_file}"
    echo "($(date)) [INFO] Skipping to next BOLD run..." | tee -a "${log_file}"
    return 1
  else
    echo "($(date)) [INFO] Volume validation passed for ${_desc}: ${_actual} volumes" | tee -a "${log_file}"
    return 0
  fi
}

# UTIL: check whether given run is the first one using its fieldmap
is_first_run_for_fieldmap() {
  _current_run=$1
  _current_fmap=${fmap_mapping[$_current_run]}
  
  # search all runs to find first one that uses this fieldmap
  for run in "${!fmap_mapping[@]}"; do
    if [ "${fmap_mapping[$run]}" = "${_current_fmap}" ]; then
      # if found a run using this fieldmap, check if it's the current run
      if [ "$run" = "$_current_run" ]; then
        return 0  # true, this is the first run for this fieldmap
      else
        return 1  # false, we found an earlier run using this fieldmap
      fi
    fi
  done
  return 1
}

# set memory limit
ulimit -v $(( 16 * 1024 * 1024 ))  # 16GB memory limit

# determine which subjects file to use
#if [ -v subjects_mapping ] && [ ${#subjects_mapping[@]} -gt 0 ] && [ -v "subjects_mapping[$JOB_NAME]" ]; then
  # use step-specific subjects file from the mapping defined in settings.sh
#  SUBJECTS_FILE="${subjects_mapping[$JOB_NAME]}"
#  echo "($(date)) [INFO] Using step-specific subjects file: ${SUBJECTS_FILE}" | tee -a ${log_file}
#else
  # fall back to default all-subjects.txt
  #SUBJECTS_FILE="all-subjects.txt"
SUBJECTS_FILE="04-subjects.txt"
echo "($(date)) [INFO] No specific subjects file mapped for ${JOB_NAME}, using default: ${SUBJECTS_FILE}" | tee -a "${log_file}"
#fi

# get current subject ID from list
subject_id=$(sed -n "$((SLURM_ARRAY_TASK_ID))p" "${SUBJECTS_FILE}")

subject="sub-${subject_id}"

# logging setup
mkdir -p "${SLURM_LOG_DIR}/subjects"
log_file="${SLURM_LOG_DIR}/subjects/${subject}_processing.log"
processed_file="${SLURM_LOG_DIR}/04-processed_subjects.txt"

if [ -z "${subject_id}" ]; then
  echo "Error: No subject found at index $((SLURM_ARRAY_TASK_ID)) in ${SUBJECTS_FILE}" | tee -a "${log_file}"
  exit 1
fi

# start logging
echo "($(date)) [INFO] Starting processing for subject ${subject_id}" | tee -a "${log_file}"

# check if this subject was already processed
if [ -f "${processed_file}" ]; then
  if grep -q "^${subject_id}$" "${processed_file}"; then
	echo "($(date)) [INFO] Subject ${subject_id} already processed, skipping" | tee -a "${log_file}"
    exit 0
  fi
fi

echo "($(date)) [INFO] Processing subject ${subject_id}" | tee -a "${log_file}"

module load python/3.9.0
module load biology
module load fsl/5.0.10

# set permissions
echo "($(date)) [INFO] Setting directory permissions"
for dir in func fmap anat; do
  chmod "${DIR_PERMISSIONS}" "${RAW_DIR}"/"${subject}"/${dir}
  chmod "${DIR_PERMISSIONS}" "${RAW_DIR}"/"${subject}"/${dir}/*
done

echo "($(date)) [INFO] Making new bids_trimmed subject directories"
for dir in anat fmap func; do
    mkdir -p "${TRIM_DIR}"/"${subject}"/${dir}
done

# copy scans metadata
cp "${RAW_DIR}"/"${subject}"/"${subject}"_scans.tsv "${TRIM_DIR}"/"${subject}"/

# copy anatomical (T1w) images
cp "${RAW_DIR}"/"${subject}"/anat/"${subject}"_T1w.nii.gz "${TRIM_DIR}"/"${subject}"/anat/
cp "${RAW_DIR}"/"${subject}"/anat/"${subject}"_T1w.json "${TRIM_DIR}"/"${subject}"/anat/

for run_bold in "${run_numbers[@]}"; do
  echo "($(date)) [INFO] Processing run ${run_bold}" | tee -a "${log_file}"

  # get actual task ID from any BOLD file that matches the current run
  bold_file=$(ls "${RAW_DIR}/${subject}/func/"*run-${run_bold}_dir-PA_bold.nii.gz | head -n1)
  detected_task_id=$(basename "${bold_file}" | sed -E 's/.*_task-([^_]+)_run-.*/\1/')

	#===========================================
	# (1) TRIM DUMMY SCANS FROM TASK BOLD
	#===========================================
	echo "($(date)) [INFO] Trimming first ${n_dummy} dummy TRs from BOLD run ${run_bold}"

	old_bold="${RAW_DIR}/${subject}/func/${subject}_task-${detected_task_id}_run-${run_bold}_dir-PA_bold.nii.gz"
	new_bold="${TRIM_DIR}/${subject}/func/${subject}_task-${new_task_id}_run-${run_bold}_dir-PA_bold.nii.gz"

	# validate initial BOLD volumes
  echo "($(date)) [INFO] Validating BOLD volumes for run ${run_bold}"
  if ! validate_volumes "${old_bold}" "${EXPECTED_BOLD_VOLS}" "BOLD run ${run_bold}"; then
    continue
  fi

	# remove dummy scans from task BOLD image
	if ! fslroi "${old_bold}" "${new_bold}" "${n_dummy}" "${EXPECTED_BOLD_VOLS_AFTER_TRIMMING}"; then
    echo "($(date)) [ERROR] Failed to trim BOLD run ${run_bold}" | tee -a "${log_file}"
    continue
  fi

	# validate trimmed BOLD volumes
	if ! validate_volumes "${new_bold}" ${EXPECTED_BOLD_VOLS_AFTER_TRIMMING} "trimmed BOLD run ${run_bold}"; then
    continue
  fi

	# copy and update JSON sidecar files
	cp "${RAW_DIR}"/"${subject}"/func/"${subject}"_task-"${detected_task_id}"_run-"${run_bold}"_dir-PA_bold.json \
  "${TRIM_DIR}"/"${subject}"/func/"${subject}"_task-"${new_task_id}"_run-"${run_bold}"_dir-PA_bold.json


	#===========================================
	# (2) PROCESS FIELDMAP
	#===========================================
  echo "($(date)) [INFO] Processing fieldmap for run ${run_bold}"

	# look up correct fmap <-> bold mapping from config.sh
	run_fmap=${fmap_mapping[$run_bold]}

	# first, trim dummy scans from fieldmap epi
	fieldmap_input="${RAW_DIR}/${subject}/fmap/${subject}_run-${run_fmap}_dir-AP_epi.nii.gz"
  fieldmap_output="${TRIM_DIR}/${subject}/fmap/${subject}_acq-${new_task_id}_run-${run_fmap}_dir-AP_epi.nii.gz"

	# get fieldmap volumes
	fmap_total_vols=$(fslnvols "${fieldmap_input}")
	fmap_remain_vols=$((fmap_total_vols - n_dummy))

  # TODO:
  # if $fmap_total_vols -ne $EXPECTED_FMAP_VOLS; then
  ##throw error

  echo "($(date)) [INFO] Processing fieldmap for run ${run_bold} (first run using fieldmap ${fmap_mapping[$run_bold]})" | tee -a "${log_file}"

	if is_first_run_for_fieldmap "${run_bold}"; then
	  # validate untrimmed fieldmap volumes
	  echo "($(date)) [INFO] Validating fieldmap volumes for run ${run_fmap}"
    if ! validate_volumes "${fieldmap_input}" "${EXPECTED_FMAP_VOLS}" "fieldmap run ${run_fmap}"; then
      continue
    fi
	
		# calculate number of remaining volumes for fieldmap
		remain_fmap_vols=$((EXPECTED_FMAP_VOLS - n_dummy))
    echo "($(date)) [INFO] Will retain ${remain_fmap_vols} volumes after removing ${n_dummy} dummy scans" | tee -a "${log_file}"

		# trim off dummy scans from fieldmap
    if ! fslroi "${fieldmap_input}" "${fieldmap_output}" "${n_dummy}" "${remain_fmap_vols}"; then
      echo "($(date)) [ERROR] Failed to trim fieldmap for run ${run_fmap}" | tee -a "${log_file}"
      continue
    fi

		# validate trimmed fieldmap volumes
    validate_volumes "${fieldmap_output}" "${remain_fmap_vols}" "trimmed fieldmap run ${run_fmap}"

		# create synthetic opposite-phase encoding image from task BOLD
    echo "($(date)) [INFO] Creating synthetic PA image from BOLD run ${run_bold}"
		new_epi="${TRIM_DIR}/${subject}/fmap/${subject}_acq-${new_task_id}_run-${run_fmap}_dir-PA_epi.nii.gz"

		# extract volumes after dummy removal, matching fieldmap volume count
    if ! fslroi "${old_bold}" "${new_epi}" "${n_dummy}" "${remain_fmap_vols}"; then
      echo "[ERROR] Failed to create synthetic PA image for run ${run_bold}" | tee -a "${log_file}"
      continue
    fi

		# validate synthetic PA volumes
		if ! validate_volumes ${new_epi} ${remain_fmap_vols} "synthetic PA image for run ${run_fmap}"; then
		  echo "($(date)) [INFO] Volume validation complete for fieldmap set ${run_fmap}" | tee -a "${log_file}"
    fi

		# copy json files for fmap
		cp "${RAW_DIR}"/"${subject}"/func/"${subject}"_task-"${detected_task_id}"_run-"${run_bold}"_dir-PA_bold.json \
		"${TRIM_DIR}"/"${subject}"/fmap/"${subject}"_acq-"${new_task_id}"_run-"${run_fmap}"_dir-PA_epi.json

    cp "${RAW_DIR}"/"${subject}"/func/"${subject}"_task-"${detected_task_id}"_run-"${run_bold}"_dir-PA_bold.json \
		"${TRIM_DIR}"/"${subject}"/fmap/"${subject}"_acq-"${new_task_id}"_run-"${run_fmap}"_dir-AP_epi.json
  fi
	
  # set permissions
  chmod "${FILE_PERMISSIONS}" "${TRIM_DIR}"/"${subject}"/func/"${subject}"_task-"${new_task_id}"_run-"${run_bold}"_dir-PA_bold.nii.gz
  chmod "${FILE_PERMISSIONS}" "${TRIM_DIR}"/"${subject}"/func/"${subject}"_task-"${new_task_id}"_run-"${run_bold}"_dir-PA_bold.json
  chmod "${FILE_PERMISSIONS}" "${TRIM_DIR}"/"${subject}"/fmap/"${subject}"_acq-"${new_task_id}"_run-"${run_fmap}"_dir-PA_epi.nii.gz
  chmod "${FILE_PERMISSIONS}" "${TRIM_DIR}"/"${subject}"/fmap/"${subject}"_acq-"${new_task_id}"_run-"${run_fmap}"_dir-PA_epi.json
  chmod "${FILE_PERMISSIONS}" "${TRIM_DIR}"/"${subject}"/fmap/"${subject}"_acq-"${new_task_id}"_run-"${run_fmap}"_dir-AP_epi.nii.gz
  chmod "${FILE_PERMISSIONS}" "${TRIM_DIR}"/"${subject}"/fmap/"${subject}"_acq-"${new_task_id}"_run-"${run_fmap}"_dir-AP_epi.json

  # summary
  echo "......................................" | tee -a "${log_file}"
  echo "($(date)) [INFO] Final volume summary:" | tee -a "${log_file}"
  echo "  Original BOLD volumes: ${EXPECTED_BOLD_VOLS}" | tee -a "${log_file}"
  echo "  Retained BOLD volumes: ${EXPECTED_BOLD_VOLS_AFTER_TRIMMING}" | tee -a "${log_file}"
  echo "  Original fieldmap volumes: ${EXPECTED_FMAP_VOLS}" | tee -a "${log_file}"
  echo "  Retained fieldmap volumes: ${remain_fmap_vols}" | tee -a "${log_file}"
  echo "  Dummy volumes removed: ${n_dummy}" | tee -a "${log_file}"
  echo "......................................" | tee -a "${log_file}"
done


#===========================================
# (3) UPDATE FIELDMAP JSON METADATA
#===========================================

# convert fmap_mapping associative array to JSON string
fmap_to_json="{"
for key in "${!fmap_mapping[@]}"; do
  fmap_to_json+="\"$key\":\"${fmap_mapping[$key]}\","
done
# Remove the trailing comma and close the JSON object
fmap_to_json="${fmap_to_json%,}}"

echo "($(date)) [INFO] JSON mapping: $fmap_to_json"

# modify run numbers array format to a comma separated string
run_numbers_csv=$(IFS=,; echo "${run_numbers[*]}")

echo "($(date)) [INFO] Starting metadata update" | tee -a "${log_file}"

python3 "${SCRIPTS_DIR}"/"${JOB_NAME}"/update_fmap_metadata.py \
  --subid "${subject_id}" \
  --bids-dir "${TRIM_DIR}" \
  --task-id "${task_id}" \
  --new-task-id "${new_task_id}" \
  --fmap-mapping "${fmap_to_json}" \
  --runs "${run_numbers_csv}"
echo "($(date)) [INFO] Metadata update complete" | tee -a "${log_file}"

echo "${subject_id}" >> "${processed_file}"
echo "($(date)) [INFO] Successfully completed processing for subject ${subject_id}" | tee -a "${log_file}"
echo "($(date)) [INFO] -> DOUBLE CHECK FILES AND THEN PROCEED TO FMRIPREP!" | tee -a "${log_file}"
