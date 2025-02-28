#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: February 27, 2025
# @Description: Download data from Flywheel. This first step is intentionally cumbersome (i.e., not setup to run in batch).
#               You should carefully check your MRI acquisitions on Flywheel before and after downloading to your server to
#               to avoid any downstream errors as a result of download issues.
# @Param: JOB_NAME (positional argument #1) - required job name string (e.g., "00-download")

umask 002  # modify permissions so downstream steps inherit correct file permissions

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

subject="sub-${new_subid}"

# logging setup
mkdir -p "${SLURM_LOG_DIR}/subjects"
log_file="${SLURM_LOG_DIR}/subjects/${subject}_processing.log"
processed_file="${SLURM_LOG_DIR}/00-processed_subjects.txt"

# start logging
echo "($(date)) [INFO] Starting Flywheel data download for subject ${fw_subid}" | tee -a "${log_file}"

# check if this subject was already downloaded
if [ -f "${processed_file}" ]; then
  if grep -q "^${subject_id}$" "${processed_file}"; then
	echo "($(date)) [INFO] Subject ${fw_subid} already downloaded, skipping" | tee -a "${log_file}"
    exit 0
  fi
fi

module load python/3.9.0

#===========================================
# (1) DOWNLOAD FILES VIA FLYWHEEL CLI
#===========================================

echo "($(date)) [INFO] Now starting MRI file download" | tee -a "${log_file}"

python3 "${SCRIPTS_DIR}"/"${JOB_NAME}"/fw-downloader.py \
  --fw_subject_id "${fw_subid}" \
  --fw_session_id "${fw_seshid}" \
  --fw_group_id "${FW_GROUP_ID}" \
  --fw_project_id "${FW_PROJECT_ID}" \
  --fw_instance_url "${FW_URL}" \
  --fw_api_key_file "${FW_CLI_API_KEY_FILE}
echo "($(date)) [INFO] Flywheel download complete" | tee -a "${log_file}"

echo "${fw_subid}" >> "${processed_file}"
echo "($(date)) [INFO] Successfully completed Flywheel data download for subject ${fw_subid}" | tee -a "${log_file}"
