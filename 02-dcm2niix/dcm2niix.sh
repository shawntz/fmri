#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: May 9, 2025
# @Description: Trigger dcm2niix workflow.
# @Param: JOB_NAME (positional argument #1) - required job name string (e.g., "02-dcm2niix")
# @Param: fw_seshid (positional argument #2) - flywheel session ID
# @Param: new_subid (positional argument #3) - new subject ID
# @Param: skip_tar (optional flag) - pass '--skip-tar' to skip tar extraction (for manually configured dirs)
# @Note: Grouping is hardcoded to 'all' to avoid conflicts from manually merged sessions

source ./load_config.sh

JOB_NAME=$1

if [ -z "${JOB_NAME}" ]; then
  echo "Error: Pipeline step name not provided"
  echo "Usage: $0 <step-name> <fw_session_id> <new_subid> [--skip-tar]"
  exit 1
fi

fw_seshid=$2
new_subid=$3
# Hardcoded to 'all' to avoid grouping errors from manually merged sessions
grouping="all"
skip_tar_flag=""

# Check if any argument is --skip-tar
for arg in "$@"; do
  if [ "$arg" = "--skip-tar" ]; then
    skip_tar_flag="--skip-tar"
    break
  fi
done

subject="sub-${new_subid}"

# logging setup
mkdir -p "${SLURM_LOG_DIR}/subjects"
log_file="${SLURM_LOG_DIR}/subjects/${subject}_processing.log"
processed_file="${SLURM_LOG_DIR}/02-processed_subjects.txt"

# Log skip-tar mode after log_file is defined
if [ -n "${skip_tar_flag}" ]; then
  echo "($(date)) [INFO] Skip tar mode enabled" | tee -a "${log_file}"
fi

echo "($(date)) [INFO] Processing subject: ${subject}" | tee -a "${log_file}"

module load python/3.9.0

echo "($(date)) [INFO] Now converting raw dicom MRI files" | tee -a "${log_file}"

python3 "${SCRIPTS_DIR}"/"${JOB_NAME}"/dcm2niix.py \
  --user "${USER}" \
  --subid "${new_subid}" \
  --exam_num "${fw_seshid}" \
  --project_dir "${BASE_DIR}" \
  --fw_group_id "${FW_GROUP_ID}" \
  --fw_project_id "${FW_PROJECT_ID}" \
  --task_id "${new_task_id}" \
  --sing_image_path "${SINGULARITY_IMAGE_DIR}"/"${HEUDICONV_IMAGE}" \
  --scripts_dir "${SCRIPTS_DIR}"/${JOB_NAME} \
  --grouping "${grouping}" \
  ${skip_tar_flag}
echo "($(date)) [INFO] Raw dicom to BIDS conversion complete" | tee -a "${log_file}"

echo "${new_subid}" >> "${processed_file}"
echo "($(date)) [INFO] Successfully completed BIDSifying raw dicom MRI files for subject: ${subject}" | tee -a "${log_file}"
