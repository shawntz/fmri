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

fw_seshid=$2
new_subid=$3

echo "=================================================="
echo "Raw Data to BIDS"
echo "=================================================="
echo "User: $USER"
echo "Flywheel Group ID: $FW_GROUP_ID"
echo "Flywheel Project ID: $FW_PROJECT_ID"
echo "Flywheel Session ID: $fw_seshid"
echo "BIDS Subject ID: $new_subid"
echo "Experiment Type: $EXPERIMENT_TYPE"
echo "Config File: $CONFIG_FILE"
echo "Project Dir: $BASE_DIR"
echo "=================================================="

# check if scan-config.json file exists
if [ ! -f "$CONFIG_FILE" ] && [ "$CONFIG_FILE" != "None" ]; then
    echo "Warning: Scan config JSON file $CONFIG_FILE not found..."
fi

# set memory limit
ulimit -v $(( 16 * 1024 * 1024 ))  # 16GB memory limit

subject="sub-${new_subid}"

# logging setup
mkdir -p "${SLURM_LOG_DIR}/subjects"
log_file="${SLURM_LOG_DIR}/subjects/${subject}_processing.log"
processed_file="${SLURM_LOG_DIR}/02-processed_subjects.txt"

# start logging
echo "($(date)) [INFO] Starting processing for subject: ${subject}" | tee -a "${log_file}"

# check if this subject was already processed
if [ -f "${processed_file}" ]; then
  if grep -q "^${new_subid}$" "${processed_file}"; then
	echo "($(date)) [INFO] Subject ${subject} already processed, skipping" | tee -a "${log_file}"
    exit 0
  fi
fi

echo "($(date)) [INFO] Processing subject: ${subject}" | tee -a "${log_file}"

module load python/3.9.0

#===========================================
# (2) BIDSIFY RAW DATA FROM FLYWHEEL
#===========================================

echo "($(date)) [INFO] Now BIDSifying raw MRI files" | tee -a "${log_file}"

python3 "${SCRIPTS_DIR}"/"${JOB_NAME}"/bids-converter.py \
  --user "${USER}" \
  --subid "${new_subid}" \
  --exam_num "${fw_seshid}" \
  --project_dir "${BASE_DIR}" \
  --fw_group_id "${FW_GROUP_ID}" \
  --fw_project_id "${FW_PROJECT_ID}" \
  --task_id "${new_task_id}" \
  --experiment_type "${EXPERIMENT_TYPE}" \
  --config "${CONFIG_FILE}"
echo "($(date)) [INFO] Raw to BIDS directory conversion complete" | tee -a "${log_file}"

echo "${new_subid}" >> "${processed_file}"
echo "($(date)) [INFO] Successfully completed BIDSifying MRI files for subject: ${subject}" | tee -a "${log_file}"
