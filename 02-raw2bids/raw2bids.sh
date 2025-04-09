#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: February 27, 2025
# @Description: Bidsify raw MRI acquisitions.
# @Param: JOB_NAME (positional argument #1) - required job name string (e.g., "00-fw2bids")

umask 002  # modify permissions so fslroi inherits correct permissions

source ./settings.sh

JOB_NAME=$1
if [ -z "${JOB_NAME}" ]; then
  echo "Error: Pipeline step name not provided" | tee -a "${log_file}"
  echo "Usage: $0 <step-name>" | tee -a "${log_file}"
  exit 1
fi

fw_subid=$2
fw_seshid=$3
new_subid=$4

echo "=================================================="
echo "Flywheel Download"
echo "=================================================="
echo "User: $USER"
echo "Flywheel Group ID: $FW_GROUP_ID"
echo "Flywheel Project ID: $FW_PROJECT_ID"
echo "Flywheel Subject ID: $fw_subid"
echo "Flywheel Session ID: $fw_seshid"
echo "BIDS Subject ID: $new_subid"
echo "Experiment Type: $EXPERIMENT_TYPE"
echo "Config File: $CONFIG_FILE"
echo "=================================================="

# check if scan-config.json file exists
if [ ! -f "$CONFIG_FILE" ] && [ "$CONFIG_FILE" != "None" ]; then
    echo "Warning: Scan config JSON file $CONFIG_FILE not found..."
fi

# set memory limit
ulimit -v $(( 16 * 1024 * 1024 ))  # 16GB memory limit

# determine which subjects file to use
if [ -v subjects_mapping ] && [ ${#subjects_mapping[@]} -gt 0 ] && [ -v "subjects_mapping[$JOB_NAME]" ]; then
  # use step-specific subjects file from the mapping defined in settings.sh
  SUBJECTS_FILE="${subjects_mapping[$JOB_NAME]}"
  echo "($(date)) [INFO] Using step-specific subjects file: ${SUBJECTS_FILE}" | tee -a ${log_file}
else
  # fall back to default all-subjects.txt
  SUBJECTS_FILE="all-subjects.txt"
  echo "($(date)) [INFO] No specific subjects file mapped for ${JOB_NAME}, using default: ${SUBJECTS_FILE}" | tee -a "${log_file}"
fi

# get current subject ID from list
subject_id=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" "${SUBJECTS_FILE}")
if [ -z "${subject_id}" ]; then
  echo "Error: No subject found at index $((SLURM_ARRAY_TASK_ID+1)) in ${SUBJECTS_FILE}" | tee -a "${log_file}"
  exit 1
fi
subject="sub-${subject_id}"

# logging setup
mkdir -p "${SLURM_LOG_DIR}/subjects"
log_file="${SLURM_LOG_DIR}/subjects/${subject}_processing.log"
processed_file="${SLURM_LOG_DIR}/00-processed_subjects.txt"

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

#===========================================
# (2) BIDSIFY RAW DATA FROM FLYWHEEL
#===========================================

echo "($(date)) [INFO] Now BIDSifying raw MRI files" | tee -a "${log_file}"

python3 "${SCRIPTS_DIR}"/"${JOB_NAME}"/bids-converter.py \
  --user "${USER}" \
  --fw_subject_id "${fw_subid}" \
  --fw_session_id "${fw_seshid}" \
  --project_dir "${project_dir}" \
  --fw_group_id "${FW_GROUP_ID}" \
  --fw_project_id "${FW_PROJECT_ID}" \
  --task_id "${new_task_id}"
echo "($(date)) [INFO] Raw to BIDS directory conversion complete" | tee -a "${log_file}"

echo "${subject_id}" >> "${processed_file}"
echo "($(date)) [INFO] Successfully completed BIDSifying MRI files for subject ${subject_id}" | tee -a "${log_file}"

# user=args.user,
#         subid=args.subid,
#         exam_num=args.exam_num,
#         age_type=args.age_type,
#         experiment_type=args.experiment_type,
#         config_file=args.config,
#         series_overrides=series_overrides,
#     )

--fw_subject_id "${fw_subid}" \
  --fw_session_id "${fw_seshid}" \
  --fw_group_id "${FW_GROUP_ID}" \
  --fw_project_id "${FW_PROJECT_ID}" \
