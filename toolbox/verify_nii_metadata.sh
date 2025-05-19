#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: May 17, 2025
# @Description: Entry point to verify dcm2niix generated metadata in BIDS format.

source ./settings.sh

new_subid=$1
subject="sub-${new_subid}"

echo "($(date)) [INFO] Processing subject: ${subject}"

module load python/3.9.0

echo "($(date)) [INFO] Running header-based QC"

python3 "${SCRIPTS_DIR}/${JOB_NAME}toolbox/verify_nii_metadata.py" \
  --subid "${new_subid}" \
  --project_dir "${BASE_DIR}" \
  --task_id "${new_task_id}" \
  --config_path "${CONFIG_FILE}" \
  --log_out_dir "${SLURM_LOG_DIR}"
