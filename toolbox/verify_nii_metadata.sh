#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: May 17, 2025
# @Description: Entry point to verify dcm2niix generated metadata in BIDS format.

source ./settings.sh

JOB_NAME=$1

if [ -z "${JOB_NAME}" ]; then
  echo "Error: Pipeline step name not provided" | tee -a "${log_file}"
  echo "Usage: $0 <step-name>" | tee -a "${log_file}"
  exit 1
fi

fw_seshid=$2
new_subid=$3

subject="sub-${new_subid}"

# logging setup
mkdir -p "${SLURM_LOG_DIR}/subjects"
log_file="${SLURM_LOG_DIR}/subjects/${subject}_processing.log"
processed_file="${SLURM_LOG_DIR}/03-processed_subjects.txt"

echo "($(date)) [INFO] Processing subject: ${subject}" | tee -a "${log_file}"

module load python/3.9.0

echo "($(date)) [INFO] Running header-based QC" | tee -a "${log_file}"

python3 "${SCRIPTS_DIR}/${JOB_NAME}/verify_nii_metadata.py" \
  --subid "${new_subid}" \
  --project_dir "${BASE_DIR}" \
  --config_path "${CONFIG_FILE}" \
  --log_out_dir "${SLURM_LOG_DIR}
