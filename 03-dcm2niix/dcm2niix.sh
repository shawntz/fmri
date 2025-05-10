#!/bin/sh
# @Author: Shawn Schwartz - Stanford Memory Lab
# @Date: May 9, 2025
# @Description: Trigger dcm2niix workflow.
# @Param: JOB_NAME (positional argument #1) - required job name string (e.g., "03-dcm2niix")

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
processed_file="${SLURM_LOG_DIR}/04-processed_subjects.txt"

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
  --scripts_dir "${SCRIPTS_DIR}
echo "($(date)) [INFO] Raw dicom to BIDS conversion complete" | tee -a "${log_file}"

echo "${new_subid}" >> "${processed_file}"
echo "($(date)) [INFO] Successfully completed BIDSifying raw dicom MRI files for subject: ${subject}" | tee -a "${log_file}"
