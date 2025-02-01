# SML fMRI Preprocessing Template

This repo is a work in progress intended to transform the [Stanford Memory Lab's](https://memorylab.stanford.edu/) (SML) internal fMRI preprocessing scripts into a generalizable workflow for consistency within and across lab projects.

As such, this repo is intended to be used as a **GitHub template** for setting up fMRI preprocessing pipelines that handle:

- [x] 1. dummy scan removal,
- [x] 2. fieldmap-based susceptibility distortion correction,
- [x] 3. fMRIPrep,
- [ ] 4. mask generation, and
- [ ] 5. model spec generation (level 1, level 2, and single trial GLM)

> [!NOTE]
> - [x] indicates workflows that have been finished and validated
> - [ ] indicates workflows that are still under active development

## Using this Template

1. Click the "Use this template" button at the top of this repository
2. Select "Create a new repository" 
3. Choose a name for your repository
4. Select whether you want it to be public or private
5. Click "Create repository from template"

This will create a new repository with all the files from this template, allowing you to customize it for your specific preprocessing needs while maintaining the core functionality for handling:

- Fieldmap-based distortion correction
- Dummy scan removal 
- BIDS-compliance
- JSON metadata management
- Quality control checks

The template provides a standardized structure and validated scripts that you can build upon, while keeping your specific study parameters and paths separate in configuration files.

## What's Included

- Preprocessing scripts for handling fieldmaps and dummy scans
- Configuration templates and examples
- Documentation and usage guides
- Quality control utilities
- BIDS metadata management tools

## Getting Started

After creating your repository from this template:

1. Clone your new repository
2. Copy `prepare.template.sh` to `prepare.sh` and customize parameters
3. Modify paths and scan parameters for your study
4. Follow the `configuration guide` in the detailed documentation below

---

# Configuration Guide

## Overview
The preprocessing pipeline requires proper configuration of several parameters to handle your study's specific requirements. This guide explains how to set up the `settings.sh` file that controls the pipeline's behavior.

> [!IMPORTANT]  
> ## Submitting Jobs to Slurm Workload Manager
>
> Each core step directory (e.g., `01-prepare`) contains an executable `submit_job.sbatch` script.
> Thus, from the root of your project scripts directory, you can call:

```bash
./01-prepare/submit_job.sbatch
```

## Configuration Steps

### 1. Copy Settings Template
```bash
cp settings.template.sh settings.sh
```

### 2. Modify Paths
- Set `BASE_DIR` to your study's root directory
- Ensure `RAW_DIR` points to your BIDS-formatted data
- Verify `TRIM_DIR` location for trimmed BIDS-compliant outputs that will later be used for fmriprep

### 3. Set Study Parameters
- Update `task_id` to match your BIDS task name
- Set `new_task_id` if task renaming is needed
- Modify `run_numbers` to match your scan sequence / number of task runs
- Adjust `n_dummy` based on your scanning protocol

### 4. Configure Validation Values
- Set `EXPECTED_FMAP_VOLS` to match your fieldmap acquisition
- Set `EXPECTED_BOLD_VOLS` to match your BOLD acquisition

### 5. Map Fieldmaps
- Update `fmap_mapping` to reflect your fieldmap/BOLD correspondence
- Ensure each BOLD run has a corresponding fieldmap entry

### 6. Set Permissions
- Adjust `DIR_PERMISSIONS` and `FILE_PERMISSIONS` based on your system requirements

---

## Required Settings

### Path Configuration
```bash
# ============================================================================
# (1) SETUP DIRECTORIES
# ============================================================================
BASE_DIR='/my/project/dir'           # ROOT DIR FOR THE STUDY
RAW_DIR="${BASE_DIR}/bids"           # RAW BIDS-COMPLIANT DATA LOCATION
TRIM_DIR="${BASE_DIR}/bids_trimmed"  # DESIRED DESTINATION FOR PROCESSED DATA
```

### Email Update Preference
```bash
# ============================================================================
# (2) USER EMAIL (for slurm report updates)
# ============================================================================
USER_EMAIL="hello@stanford.edu"
```

### Study Parameters 
```bash
# ============================================================================
# (3) TASK/SCAN PARAMETERS
# ============================================================================
task_id="SomeTaskName"   # ORIGINAL TASK NAME IN BIDS FORMAT
new_task_id="cleanname"  # NEW TASK NAME (IF RENAMING IS NEEDED), OTHERWISE SET SAME VALUE AS $task_id
n_dummy=5                # NUMBER OF "DUMMY" TRs to remove
run_numbers=("01" "02" "03" "04" "05" "06" "07" "08")  # ALL TASK BOLD RUN NUMBERS
```

### Data Validation
```bash
# ============================================================================
# (4) DATA VALIDATION VALUES FOR UNIT TESTS
# ============================================================================
EXPECTED_FMAP_VOLS=12   # EXPECTED NUMBER OF VOLUMES IN ORIGINAL FIELDMAP SCANS
EXPECTED_BOLD_VOLS=440  # EXPECTED NUMBER OF VOLUMES IN BOLD SCANS
```

### Fieldmap (fmap) Mapping
```bash
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
```

### Permissions
```bash
# ============================================================================
# (6) DEFAULT PERMISSIONS
# ============================================================================
DIR_PERMISSIONS=775   # DIRECTORY LEVEL
FILE_PERMISSIONS=775  # FILE LEVEL
```

### Slurm Job Header Configurator
```bash
# ============================================================================
# (7) SLURM JOB HEADER CONFIGURATOR
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
export SLURM_MEM="16GB"
export SLURM_CPUS="1"
export SLURM_ARRAY_SIZE="${array_range}"  # use computed range
export SLURM_ARRAY_THROTTLE="10"  # number of subjects to run concurrently
export SLURM_LOG_DIR="${BASE_DIR}/logs/slurm/"  # use BASE_DIR from main settings file
#
```

---

> [!TIP]
> ## Before running the pipeline:
> 1. Verify all paths exist and are accessible
> 2. Confirm volume counts match your acquisition protocol
> 3. Test the configuration on a single subject
> 4. Review logs for any configuration warnings


> [!CAUTION]
> ## Common Issues
> - Incorrect path specifications
> - Mismatched volume counts
> - Incorrect fieldmap mappings
> - Permission issues


> [!NOTE]  
> ### Comments, suggestions, questions, issues?
>
> Please use the issues tab (<https://github.com/shawntz/fmri/issues>) to make note of any bugs, comments, suggestions, feedback, etc… all are welcomed and appreciated, thanks!
> 
> cheers, 
> shawn

---

<div align="center">

## SML fMRI Dev Team
    
|    | Team Member | Role |
| :----------: |  :-------------: | :-------------: |
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/image/shawn_sf_ggb_2022_square_0.jpg?h=a11293b4&itok=XexnOeUL" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/shawn-schwartz-ms-ma" target="_blank">Shawn Schwartz, M.S., M.A.</a> <br> (Ph.D. Candidate) | `Lead Developer` <br> `Maintainer` <br> `Project Conception` | 
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/image/jintao_photo_0.jpg?h=5d522a5b&itok=hihL4GJO" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/jintao-sheng-phd" target="_blank">Jintao Sheng, Ph.D.</a> <br> (Postdoc) | `Core Developer` <br> `Project Conception` <br> `Technical Reviewer` | 
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/image/mostrecent_0.jpg?h=f926125a&itok=fiqkxKMx" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/haopei-yang-phd" target="_blank">Haopei Yang, Ph.D.</a> <br> (Postdoc) | `Core Developer` <br> `Project Conception` <br> `Technical Reviewer` | 
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/image/subbu_photo_0.jpeg?h=2a9f3bd2&itok=eukzENYx" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/subbulakshmi-s-phd" target="_blank">Subbulakshmi S, Ph.D.</a> <br> (Postdoc) | `Core Contributor` <br> `Code Reviewer` <br> `Technical Reviewer` | 
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/people/douglas_photo_3.jpg?h=816b21b2&itok=52F62G61" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/douglas-miller" target="_blank">Douglas Miller, B.A.</a> <br> (Ph.D. Candidate) | `Core Contributor` <br> `Code Reviewer` <br> `Technical Reviewer` | 
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/image/img_1581_0.jpg?h=1f7c1d57&itok=V666sxOZ" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/mingjian-he-phd" target="_blank">Mingjian (Alex) He, Ph.D.</a> <br> (Postdoc) | `Core Contributor` <br> `Code Reviewer` <br> `Technical Reviewer` | 
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/image/thumbnail_atrelle_0.jpg?h=8234d0a0&itok=lg9VP9wQ" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/ali-trelle-phd" target="_blank">Ali Trelle, Ph.D.</a> <br> (Instructor, SoM) | `Core Contributor` | 
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/people/screen_shot_2019-07-23_at_9.19.36_pm_copy.png?h=5fbe367e&itok=N4uE8LH4" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/anthony-d-wagner-phd" target="_blank">Anthony Wagner, Ph.D.</a> <br> (PI) | `Lab Director` <br> `Conceptual Reviewer` | 

### Want to Be Listed?
Make significant contributions to the project and get listed here! <br> See our [Contributing Guidelines](CONTRIBUTING.md) for how to get involved.

</div>

