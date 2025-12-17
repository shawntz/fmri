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
BASE_DIR='/oak/stanford/groups/awagner/yaams-haams/fmri'     # ROOT DIR FOR THE STUDY
SCRIPTS_DIR="${BASE_DIR}/scripts"    # PATH OF CLONED FMRI REPO
RAW_DIR="${BASE_DIR}/bids"           # RAW BIDS-COMPLIANT DATA LOCATION
TRIM_DIR="${BASE_DIR}/bids_trimmed"  # DESIRED DESTINATION FOR PROCESSED DATA
WORKFLOW_LOG_DIR="${BASE_DIR}/logs/workflows"
TEMPLATEFLOW_HOST_HOME="${HOME}/.cache/templateflow"
FMRIPREP_HOST_CACHE="${HOME}/.cache/fmriprep"
FREESURFER_LICENSE="${HOME}/freesurfer.txt"
#
# ============================================================================
# (2) USER EMAIL (for slurm report updates)
# ============================================================================
USER_EMAIL="stschwartz@stanford.edu"
USER="shawnsch"
FW_GROUP_ID="awagner"
FW_PROJECT_ID="amass"
#
# ============================================================================
# (3) TASK/SCAN PARAMETERS
# ============================================================================
FW_CLI_API_KEY_FILE="${HOME}/flywheel_api_key.txt"
FW_URL="cni.flywheel.io"
CONFIG_FILE="scan-config.json"
EXPERIMENT_TYPE="advanced" # CHOOSE BETWEEN 'basic' AND 'advanced' within `scan-config.json`
task_id="GoalAttnMemTest"  # ORIGINAL TASK NAME IN BIDS FORMAT
new_task_id="amass"        # NEW TASK NAME (IF RENAMING IS NEEDED), OTHERWISE SET SAME VALUE AS $task_id
n_dummy=5                  # NUMBER OF "DUMMY" TRs to remove
run_numbers=("01" "02" "03" "04" "05" "06" "07" "08")  # ALL TASK BOLD RUN NUMBERS
#
# ============================================================================
# (4) DATA VALIDATION VALUES FOR UNIT TESTS
# ============================================================================
EXPECTED_FMAP_VOLS=12   # EXPECTED NUMBER OF VOLUMES IN ORIGINAL FIELDMAP SCANS
EXPECTED_BOLD_VOLS=220  # EXPECTED NUMBER OF VOLUMES IN ORIGINAL TASK BOLD SCANS
EXPECTED_BOLD_VOLS_AFTER_TRIMMING=215  # EXPECTED SIZE OF TRIMMED TASK VOLUMES AFTER ACCOUNTING FOR LEAD-IN
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
# (6) SUBJECT IDS <-> PER PREPROC STEP MAPPING
# ============================================================================
# by default, subjects will be pulled from the master `all-subjects.txt` file
# however, if you want to specify different subject lists per pipeline step,
# you may do so here by following this general template:
#
# declare -A subjects_mapping=(
#     ["01-fw2server"]="01-subjects.txt"  # PREPROC STEP 01 USES "01-subjects.txt"
#     ["02-raw2bids"]="02-subjects.txt"
# )
#
# note: keep in mind that we've built in checks at the beginning of each pipeline
# step that skip a subject if there's already a record of them being preprocessed;
# thus, you shouldn't necessarily need separate 0x-subjects.txt files per step
# unless this extra layer of control is useful for your needs.
#
# ============================================================================
# (7) DEFAULT PERMISSIONS
# ============================================================================
DIR_PERMISSIONS=775   # DIRECTORY LEVEL
FILE_PERMISSIONS=775  # FILE LEVEL
#
# ============================================================================
# (8) SLURM JOB HEADER CONFIGURATOR (FOR GENERAL TASKS)
# ============================================================================
# interactive prompt to choose which subjects file to use
select_subjects_file() {
    local step_num=""
    local subjects_file="all-subjects.txt"
    local custom_file=""
    
    # SKIP_SUBJECTS_PROMPT can be set by scripts that don't need the subjects file prompt
    # For example, single-subject steps like 01-run.sbatch and 03-run.sbatch
    local skip_prompt=false
    if [[ "${SKIP_SUBJECTS_PROMPT:-}" == "true" ]]; then
        skip_prompt=true
    fi
    
    # only prompt if being sourced in an interactive shell and not from single-subject steps
    if [[ -t 0 ]] && [[ "$skip_prompt" == false ]]; then
        echo "Select subjects file to use:"
        echo "1) Use all-subjects.txt (default)"
        echo "2) Use step-specific subjects file (e.g., 04-subjects.txt)"
        read -p "Enter choice [1/2]: " choice
        
        if [[ "$choice" == "2" ]]; then
            read -p "Enter step number (e.g., 04): " step_num
            custom_file="${step_num}-subjects.txt"
            
            if [[ -f "$custom_file" ]]; then
                subjects_file="$custom_file"
                echo "Using $subjects_file"
            else
                echo "Warning: $custom_file not found. Falling back to all-subjects.txt"
            fi
        fi
    fi
    
    # calculate number of subjects based on selected file
    if [[ -f "$subjects_file" ]]; then
        num_subjects=$(wc -l < "$subjects_file")
        if [[ "$skip_prompt" == false ]]; then
            echo "($(date)) [INFO] Found ${num_subjects} total subjects in $subjects_file"
        fi
        array_range="0-$((num_subjects))"
    else
        if [[ "$skip_prompt" == false ]]; then
            echo "($(date)) [WARNING] $subjects_file not found, defaulting to single subject"
        fi
        num_subjects=1
        array_range="0"
    fi

    export SELECTED_SUBJECTS_FILE="$subjects_file"
    export SLURM_ARRAY_SIZE="${array_range}"
}

# Run the function to set up the variables
select_subjects_file

export SLURM_EMAIL="${USER_EMAIL}"
export SLURM_TIME="2:00:00"
export DCMNIIX_SLURM_TIME="12:00:00"
export SLURM_MEM="4G"  # memory alloc per cpu
export SLURM_CPUS="8"
export SLURM_ARRAY_THROTTLE="10"  # number of subjects to run concurrently
export SLURM_LOG_DIR="${BASE_DIR}/logs"  # use BASE_DIR from main settings file
export SLURM_PARTITION="awagner,hns,normal"  # compute resource preferences order
#
# ============================================================================
# (9) PIPELINE SETTINGS
# ============================================================================
FMRIPREP_VERSION="24.0.1"
DERIVS_DIR="${TRIM_DIR}/derivatives/fmriprep-${FMRIPREP_VERSION}"
SINGULARITY_IMAGE_DIR="${BASE_DIR}/singularity_images"
SINGULARITY_IMAGE="fmriprep-${FMRIPREP_VERSION}.simg"
HEUDICONV_IMAGE="heudiconv_latest.sif"
#
# ============================================================================
# (10) FMRIPREP SPECIFIC SLURM SETTINGS
# ============================================================================
FMRIPREP_SLURM_JOB_NAME="fmriprep${FMRIPREP_VERSION//.}_${new_task_id}"
# FMRIPREP_SLURM_ARRAY_SIZE=1
FMRIPREP_SLURM_ARRAY_SIZE=$SLURM_ARRAY_SIZE
FMRIPREP_SLURM_TIME="48:00:00"
FMRIPREP_SLURM_CPUS_PER_TASK="16"
FMRIPREP_SLURM_MEM_PER_CPU="4G"
#
# ============================================================================
# (11) FMRIPREP SETTINGS
# ============================================================================
FMRIPREP_OMP_THREADS=8
FMRIPREP_NTHREADS=12
FMRIPREP_MEM_MB=30000
FMRIPREP_FD_SPIKE_THRESHOLD=0.9
FMRIPREP_DVARS_SPIKE_THRESHOLD=3.0
FMRIPREP_OUTPUT_SPACES="MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5"
#
# ============================================================================
# (12) MISC SETTINGS
# ============================================================================
# Debug mode (0=off, 1=on)
DEBUG=0
#
