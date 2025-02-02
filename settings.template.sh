#!/bin/bash
# ============================================================================
# FMRI Preprocessing Configuration Settings
# ============================================================================
# 
# This file contains all configurable parameters for the fMRI preprocessing 
# pipeline, including paths, scan parameters, and data validation settings.
#
# USAGE:
# 1. Copy this template to 'settings.sh'
# 2. Modify the variables below according to your study's requirements
# 3. Source this file in your preprocessing scripts: source ./settings.sh
#    (Note: the default behavior in all scripts here is already configured to source
#     ./settings.sh for you, so no need to make any edits to source file headers.)
#
# IMPORTANT NOTES (PLEASE READ):
# - All paths should be absolute paths
# - Do not use spaces in path names
# - Validate all parameters before running the pipeline
# - Keep this file in version control but exclude any files with sensitive info
#
# FIELDMAP <-> TASK BOLD MAPPING ARRAY INSTRUCTIONS:
# The fmap_mapping array defines which fieldmap corresponds to which BOLD runs.
# In the example below, fieldmap 01 covers BOLD runs 01 and 02, fieldmap 02 covers
# runs 03 and 04, etc. Modify according to your acquisition sequence.
#
# ============================================================================
#
# ============================================================================
# (1) SETUP DIRECTORIES
# ============================================================================
BASE_DIR="/my/project/dir"           # ROOT DIR FOR THE STUDY
SCRIPTS_DIR="${BASE_DIR}/scripts"    # PATH OF CLONED FMRI REPO
RAW_DIR="${BASE_DIR}/bids"           # RAW BIDS-COMPLIANT DATA LOCATION
TRIM_DIR="${BASE_DIR}/bids_trimmed"  # DESIRED DESTINATION FOR PROCESSED DATA
WORKFLOW_LOG_DIR="${BASE_DIR}/workflows/log"
TEMPLATEFLOW_HOST_HOME="${HOME}/.cache/templateflow"
FMRIPREP_HOST_CACHE="${HOME}/.cache/fmriprep"
FREESURFER_LICENSE="${HOME}/freesurfer.txt"
#
# ============================================================================
# (2) USER EMAIL (for slurm report updates)
# ============================================================================
USER_EMAIL="hello@stanford.edu"
#
# ============================================================================
# (3) TASK/SCAN PARAMETERS
# ============================================================================
task_id="SomeTaskName"   # ORIGINAL TASK NAME IN BIDS FORMAT
new_task_id="cleanname"  # NEW TASK NAME (IF RENAMING IS NEEDED), OTHERWISE SET SAME VALUE AS $task_id
n_dummy=5                # NUMBER OF "DUMMY" TRs to remove
run_numbers=("01" "02" "03" "04" "05" "06" "07" "08")  # ALL TASK BOLD RUN NUMBERS
#
# ============================================================================
# (4) DATA VALIDATION VALUES FOR UNIT TESTS
# ============================================================================
EXPECTED_FMAP_VOLS=12   # EXPECTED NUMBER OF VOLUMES IN ORIGINAL FIELDMAP SCANS
EXPECTED_BOLD_VOLS=220  # EXPECTED NUMBER OF VOLUMES IN BOLD SCANS
#
# ============================================================================
# (5) FIELDMAP <-> TASK BOLD MAPPING
# ============================================================================
# example: here, each fmap covers two runs, 
#  so define the mapping as such:
declare -A fmap_mapping=(
    ["01"]="01"  # TASK BOLD RUN 01 USES FMAP 01
    ["02"]="01"  # TASK BOLD RUN 02 USES FMAP 01
    ["03"]="02"  # TASK BOLD RUN 03 USES FMAP 02
    ["04"]="02"  # TASK BOLD RUN 04 USES FMAP 02
    ["05"]="03"  # ...
    ["06"]="03"
    ["07"]="04"
    ["08"]="04"
)
#
# ============================================================================
# (6) DEFAULT PERMISSIONS
# ============================================================================
DIR_PERMISSIONS=775   # DIRECTORY LEVEL
FILE_PERMISSIONS=775  # FILE LEVEL
#
# ============================================================================
# (7) SLURM JOB HEADER CONFIGURATOR (FOR GENERAL TASKS)
# ============================================================================
# count number of subjects
num_subjects=$(wc -l < subjects.txt)
echo "($(date)) [INFO] Found ${num_subjects} subjects"
#
# compute array size (0 to num_subjects-1 since array indices start at 0)
array_range="0-$((num_subjects-1))"
#
export SLURM_EMAIL="${USER_EMAIL}"
export SLURM_TIME="2:00:00"
export SLURM_MEM="8G"  # memory alloc per cpu
export SLURM_CPUS="8"
export SLURM_ARRAY_SIZE="${array_range}"  # use computed range
export SLURM_ARRAY_THROTTLE="10"  # number of subjects to run concurrently
export SLURM_LOG_DIR="${BASE_DIR}/logs/slurm"  # use BASE_DIR from main settings file
export SLURM_PARTITION="hns,normal"  # compute resource preferences order
#
# ============================================================================
# (8) PIPELINE SETTINGS
# ============================================================================
FMRIPREP_VERSION="24.0.1"
DERIVS_DIR="${TRIM_DIR}/derivatives/fmriprep-${FMRIPREP_VERSION}"
SINGULARITY_IMAGE_DIR="${BASE_DIR}/singularity_images"
SINGULARITY_IMAGE="fmriprep-${FMRIPREP_VERSION}.simg"
#
# ============================================================================
# (9) FMRIPREP SPECIFIC SLURM SETTINGS
# ============================================================================
FMRIPREP_SLURM_JOB_NAME="fmriprep${FMRIPREP_VERSION//.}_${new_task_id}"
FMRIPREP_SLURM_ARRAY_SIZE=1
FMRIPREP_SLURM_TIME="48:00:00"
FMRIPREP_SLURM_CPUS_PER_TASK=16
FMRIPREP_SLURM_MEM_PER_CPU=4
#
# ============================================================================
# (10) FMRIPREP SETTINGS 
# ============================================================================
FMRIPREP_OMP_THREADS=8
FMRIPREP_NTHREADS=12
FMRIPREP_MEM_MB=30000
FMRIPREP_FD_SPIKE_THRESHOLD=0.9
FMRIPREP_DVARS_SPIKE_THRESHOLD=3.0
FMRIPREP_OUTPUT_SPACES="MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5"
# ============================================================================
# (11) MISC SETTINGS 
# ============================================================================
# Debug mode (0=off, 1=on)
DEBUG=0
#