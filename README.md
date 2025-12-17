<h2 align="center">SML fMRI Preprocessing Template<br />(<em>aka, meta fmriprep</em>)</h2>

    ███████╗███╗   ███╗██████╗ ██╗
    ██╔════╝████╗ ████║██╔══██╗██║
    █████╗  ██╔████╔██║██████╔╝██║
    ██╔══╝  ██║╚██╔╝██║██╔══██╗██║
    ██║     ██║ ╚═╝ ██║██║  ██║██║
    ╚═╝     ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝

    ██████╗ ██╗██████╗ ███████╗██╗     ██╗███╗   ██╗███████╗
    ██╔══██╗██║██╔══██╗██╔════╝██║     ██║████╗  ██║██╔════╝
    ██████╔╝██║██████╔╝█████╗  ██║     ██║██╔██╗ ██║█████╗
    ██╔═══╝ ██║██╔═══╝ ██╔══╝  ██║     ██║██║╚██╗██║██╔══╝
    ██║     ██║██║     ███████╗███████╗██║██║ ╚████║███████╗
    ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝

This repo is a work in progress intended to transform the [Stanford Memory Lab's](https://memorylab.stanford.edu/) (SML) internal fMRI preprocessing scripts into a generalizable workflow for consistency within and across lab projects.

As such, this repo is intended to be used as a **GitHub template** for setting up fMRI preprocessing pipelines that handle:

- [x] 1. automated transfer of scanner acquisitions from FlyWheel -> Server
- [x] 2. Raw -> BIDS format
- [x] 3. `dcm2niix` DICOM to NIfTI converter,
- [x] 4. dummy scan removal + setup files for fieldmap-based susceptibility distortion correction in fMRIPrep,
- [x] 5. Run fMRIPrep anatomical workflows only (if doing manual edits, otherwise skip to step 8)
- [ ] 6. Download Freesurfer output for manual surface editing
- [ ] 7. Reupload edited Freesurfer directories
- [ ] 8. Run remaining fMRIPrep steps
- [ ] 9. automated tools for HDF5 file management and compression out of the box (i.e., to limit lab inode usage on OAK storage)

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
- An interactive terminal user interface (TUI) launcher for triggering pipeline steps

## Getting Started

After creating your repository from this template:

1. Clone your new repository
2. Copy `config.template.yaml` to `config.yaml` and customize parameters
3. Modify paths and scan parameters for your study
4. Follow the `configuration guide` in the detailed documentation below

---

# SML fMRI Configuration Guide

## Overview
The preprocessing pipeline requires proper configuration of several parameters to handle your study's specific requirements. This guide explains how to set up the `config.yaml` file that controls the pipeline's behavior.

> [!IMPORTANT]
> ## Submitting Jobs to Slurm Workload Manager
>
> There are two approaches you can take to trigger each preprocessing step following proper configuration in the `config.yaml` file:
>
> 1) Use the provided TUI `launcher` executable, which provides an interactive popup window with more context and explanations + interactive parameter setting (as needed) for any given step.
>
> 2) Manually running each step's sidecar executable, which for each core step directory (e.g., `01-prepare`), there exists an associated sidecar executable (e.g., `01-run.sbatch`).
>
> Note: The provided `launcher` mentioned in point 1 above simply calls upon these sidecar executables; the added context and interactivity of this method may be more comfortable for users less familiar with running commands in the terminal.
>
> Thus, from the root of your project scripts directory, you can either call:

### graphical TUI `launcher` executable approach
```bash
./launch
```

#### `launcher` welcome screen:
![TUI Welcome Screen](screenshots/welcome_screen.png)

#### `launcher` workflow selector:
![TUI Workflow Selector](screenshots/workflow_selector.png)

#### `launcher` example parameter selector for the `fmriprep` step:
![TUI Example Parameter Selector Screen](screenshots/example_param.png)

##### or

### manually calling upon each sidecar executable
```bash
# example: running step 1
./01-run.sbatch

# example: running step 2
# here, --anat-only is an optional flag that is passed directly to fMRIPrep
# use this if you only want to run anatomical workflows:
./02-run.sbatch --anat-only
#
# otherwise, to run both anatomical and functional workflows, use this:
./02-run.sbatch
```

## Configuration Steps

### 1. Copy Configuration Template
```bash
cp config.template.yaml config.yaml
```

### 2. Modify Paths
- Set `BASE_DIR` to your study's root directory
- Ensure `RAW_DIR` points to your BIDS-formatted data
- Verify `TRIM_DIR` location for trimmed BIDS-compliant outputs that will later be used for fmriprep
- Set `WORKFLOW_LOG_DIR` for fMRIPrep workflow logs
- Set `TEMPLATEFLOW_HOST_HOME` for templateflow local cache
- Set `FMRIPREP_HOST_CACHE` for fmriprep local cache
- Set `FREESURFER_LICENSE` to the location of your `freesurfer` license

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

### 6. Specify Subject IDs
- Copy `all-subjects.template.txt` to `all-subjects.txt` and list all subject ids (just the numbers, not the "sub-" part)

### 7. Set Permissions
- Adjust `DIR_PERMISSIONS` and `FILE_PERMISSIONS` based on your system requirements

### 8. Setup General Slurm Job Manager Parameters

### 9. Setup `fMRIPrep` Pipeline Paths

### 10. Setup fMRIPrep-specific Slurm Parameters

### 11. Setup `fMRIPrep` Command Prompt

### 12. Miscellaneous Settings
- Enable `DEBUG` mode (for testing)

---

## Required Settings

### Path Configuration
```yaml
# ============================================================================
# (1) SETUP DIRECTORIES
# ============================================================================
directories:
  base_dir: '/my/project/dir'
  scripts_dir: '${BASE_DIR}/scripts'
  raw_dir: '${BASE_DIR}/bids'
  trim_dir: '${BASE_DIR}/bids_trimmed'
  workflow_log_dir: '${BASE_DIR}/logs/workflows'
  templateflow_host_home: '${HOME}/.cache/templateflow'
  fmriprep_host_cache: '${HOME}/.cache/fmriprep'
  freesurfer_license: '${HOME}/freesurfer.txt'
```

### User Configuration
```yaml
# ============================================================================
# (2) USER CONFIGURATION
# ============================================================================
user:
  email: 'hello@stanford.edu'
  username: 'johndoe'
  fw_group_id: 'pi'
  fw_project_id: 'amass'
```

### Study Parameters
```yaml
# ============================================================================
# (3) TASK/SCAN PARAMETERS
# ============================================================================
scan:
  task_id: 'SomeTaskName'
  new_task_id: 'cleanname'
  n_dummy: 5
  run_numbers:
    - '01'
    - '02'
    - '03'
    - '04'
    - '05'
    - '06'
    - '07'
    - '08'
```

### Data Validation
```yaml
# ============================================================================
# (4) DATA VALIDATION VALUES FOR UNIT TESTS
# ============================================================================
validation:
  expected_fmap_vols: 12
  expected_bold_vols: 220
  expected_bold_vols_after_trimming: 210
```

### Fieldmap (fmap) Mapping
```yaml
# ============================================================================
# (5) FIELDMAP <-> TASK BOLD MAPPING
# ============================================================================
# Each key represents a BOLD run number, and its value is the fieldmap number
# Example: here, each fmap covers two runs
fmap_mapping:
  '01': '01'  # TASK BOLD RUN 01 USES FMAP 01
  '02': '01'  # TASK BOLD RUN 02 USES FMAP 01
  '03': '02'  # TASK BOLD RUN 03 USES FMAP 02
  '04': '02'  # TASK BOLD RUN 04 USES FMAP 02
  '05': '03'
  '06': '03'
  '07': '04'
  '08': '04'
```

### Specifying Subject IDs
```yaml
# ============================================================================
# (6) SUBJECT IDS <-> PER PREPROC STEP MAPPING (OPTIONAL)
# ============================================================================
# By default, subjects will be pulled from the master 'all-subjects.txt' file
# However, if you want to specify different subject lists per pipeline step,
# you may do so here by uncommenting and configuring the mapping below:
#
# subjects_mapping:
#   '01-fw2server': '01-subjects.txt'
#   '02-raw2bids': '02-subjects.txt'
#
# Note: keep in mind that we've built in checks at the beginning of each pipeline
# step that skip a subject if there's already a record of them being preprocessed;
# thus, you shouldn't necessarily need separate 0x-subjects.txt files per step
# unless this extra layer of control is useful for your needs.
```

### Permissions
```yaml
# ============================================================================
# (7) DEFAULT PERMISSIONS
# ============================================================================
permissions:
  dir_permissions: '775'
  file_permissions: '775'
```

### Slurm Job Header Configurator
```yaml
# ============================================================================
# (8) SLURM JOB HEADER CONFIGURATOR (FOR GENERAL TASKS)
# ============================================================================
slurm:
  email: '${USER_EMAIL}'
  time: '2:00:00'
  dcmniix_time: '6:00:00'
  mem: '8G'
  cpus: '8'
  array_throttle: '10'
  log_dir: '${BASE_DIR}/logs/slurm'
  partition: 'hns,normal'
```

### fMRIPrep Settings
```yaml
# ============================================================================
# (9) PIPELINE SETTINGS
# ============================================================================
pipeline:
  fmriprep_version: '24.0.1'
  derivs_dir: '${TRIM_DIR}/derivatives/fmriprep-${FMRIPREP_VERSION}'
  singularity_image_dir: '${BASE_DIR}/singularity_images'
  singularity_image: 'fmriprep-${FMRIPREP_VERSION}.simg'
  heudiconv_image: 'heudiconv_latest.sif'

# ============================================================================
# (10) FMRIPREP SPECIFIC SLURM SETTINGS
# ============================================================================
fmriprep_slurm:
  job_name: 'fmriprep${FMRIPREP_VERSION//.}_${new_task_id}'
  array_size: '1'
  time: '48:00:00'
  cpus_per_task: '16'
  mem_per_cpu: '4G'

# ============================================================================
# (11) FMRIPREP SETTINGS
# ============================================================================
fmriprep:
  omp_threads: 8
  nthreads: 12
  mem_mb: 30000
  fd_spike_threshold: 0.9
  dvars_spike_threshold: 3.0
  output_spaces: 'MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5'
```

### Miscellaneous

```yaml
# ============================================================================
# (12) MISC SETTINGS
# ============================================================================
misc:
  debug: 0
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
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/people/douglas_photo_3.jpg?h=816b21b2&itok=52F62G61" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/douglas-miller" target="_blank">Douglas Miller, B.A.</a> <br> (Ph.D. Candidate) | `Core Contributor` <br> `Code Reviewer` <br> `Technical Reviewer` |
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/image/subbu_photo_0.jpeg?h=2a9f3bd2&itok=eukzENYx" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/subbulakshmi-s-phd" target="_blank">Subbulakshmi S, Ph.D.</a> <br> (Postdoc) | `Core Contributor` <br> `Code Reviewer` <br> `Technical Reviewer` |
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/image/img_1581_0.jpg?h=1f7c1d57&itok=V666sxOZ" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/mingjian-he-phd" target="_blank">Mingjian (Alex) He, Ph.D.</a> <br> (Postdoc) | `Core Contributor` <br> `Code Reviewer` <br> `Technical Reviewer` |
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/image/thumbnail_atrelle_0.jpg?h=8234d0a0&itok=lg9VP9wQ" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/ali-trelle-phd" target="_blank">Ali Trelle, Ph.D.</a> <br> (Instructor, SoM) | `Core Contributor` |
| <img src="https://memorylab.stanford.edu/sites/memorylab/files/styles/hs_medium_square_360x360/public/media/people/screen_shot_2019-07-23_at_9.19.36_pm_copy.png?h=5fbe367e&itok=N4uE8LH4" width="100" height="100"> | <a href="https://memorylab.stanford.edu/people/anthony-d-wagner-phd" target="_blank">Anthony Wagner, Ph.D.</a> <br> (PI) | `Lab Director` <br> `Conceptual Reviewer` |

### Want to Be Listed?
Make significant contributions to the project and get listed here! <br> See our [Contributing Guidelines](CONTRIBUTING.md) for how to get involved.

</div>

