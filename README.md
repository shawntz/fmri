<h2 align="center">fMRIPrep Workbench<br />(<em>aka, the Stanford Memory Lab's fMRI Preproc/Analysis Toolbox</em>)</h2>

<p align="center">
  <a href="https://github.com/shawntz/fmri/releases"><img src="https://img.shields.io/github/v/release/shawntz/fmri?label=version" alt="Release Version"></a>
  <a href="https://github.com/shawntz/fmri/blob/main/LICENSE"><img src="https://img.shields.io/github/license/shawntz/fmri" alt="License"></a>
  <a href="https://fmriprep-workbench.readthedocs.io/"><img src="https://readthedocs.org/projects/fmriprep-workbench/badge/?version=latest" alt="Documentation Status"></a>
  <a href="https://github.com/shawntz/fmri/blob/main/CHANGELOG.md"><img src="https://img.shields.io/badge/changelog-available-blue" alt="Changelog"></a>
</p>
    
   ▄████████   ▄▄▄▄███▄▄▄▄      ▄████████  ▄█     ▄███████▄    ▄████████    ▄████████    ▄███████▄            
  ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ ███    ███    ███   ███    ███   ███    ███   ███    ███            
  ███    █▀  ███   ███   ███   ███    ███ ███▌   ███    ███   ███    ███   ███    █▀    ███    ███            
 ▄███▄▄▄     ███   ███   ███  ▄███▄▄▄▄██▀ ███▌   ███    ███  ▄███▄▄▄▄██▀  ▄███▄▄▄       ███    ███            
▀▀███▀▀▀     ███   ███   ███ ▀▀███▀▀▀▀▀   ███▌ ▀█████████▀  ▀▀███▀▀▀▀▀   ▀▀███▀▀▀     ▀█████████▀             
  ███        ███   ███   ███ ▀███████████ ███    ███        ▀███████████   ███    █▄    ███                   
  ███        ███   ███   ███   ███    ███ ███    ███          ███    ███   ███    ███   ███                   
  ███         ▀█   ███   █▀    ███    ███ █▀    ▄████▀        ███    ███   ██████████  ▄████▀                 
                               ███    ███                     ███    ███                                      
 ▄█     █▄   ▄██████▄     ▄████████    ▄█   ▄█▄ ▀█████████▄     ▄████████ ███▄▄▄▄    ▄████████    ▄█    █▄    
███     ███ ███    ███   ███    ███   ███ ▄███▀   ███    ███   ███    ███ ███▀▀▀██▄ ███    ███   ███    ███   
███     ███ ███    ███   ███    ███   ███▐██▀     ███    ███   ███    █▀  ███   ███ ███    █▀    ███    ███   
███     ███ ███    ███  ▄███▄▄▄▄██▀  ▄█████▀     ▄███▄▄▄██▀   ▄███▄▄▄     ███   ███ ███         ▄███▄▄▄▄███▄▄ 
███     ███ ███    ███ ▀▀███▀▀▀▀▀   ▀▀█████▄    ▀▀███▀▀▀██▄  ▀▀███▀▀▀     ███   ███ ███        ▀▀███▀▀▀▀███▀  
███     ███ ███    ███ ▀███████████   ███▐██▄     ███    ██▄   ███    █▄  ███   ███ ███    █▄    ███    ███   
███ ▄█▄ ███ ███    ███   ███    ███   ███ ▀███▄   ███    ███   ███    ███ ███   ███ ███    ███   ███    ███   
 ▀███▀███▀   ▀██████▀    ███    ███   ███   ▀█▀ ▄█████████▀    ██████████  ▀█   █▀  ████████▀    ███    █▀    
                         ███    ███   ▀                                                                       

This WIP repo transforms the [Stanford Memory Lab's](https://memorylab.stanford.edu/) (SML) internal fMRI preprocessing scripts into a generalizable toolbox for consistency within and across lab projects.

As such, this repo is intended to be used as a **GitHub template** for setting up fMRI preprocessing pipelines that handle:

- [x] 1. **FlyWheel → Server**: Automated transfer of scanner acquisitions from FlyWheel to server
- [x] 2. **DICOM → BIDS**: `dcm2niix` converter (converts raw DICOM to BIDS format via heudiconv)
- [x] 3. **Prep for fMRIPrep**: Dummy scan removal + fieldmap susceptibility distortion correction setup
- [x] 4. **QC Metadata**: Verify DICOM → NIfTI → BIDS metadata conversion
- [x] 5. **QC Volumes**: Verify number of volumes per scan file matches expected counts
- [x] 6. **fMRIPrep Anat-Only**: Run fMRIPrep anatomical workflows only (for manual FreeSurfer editing)
- [x] 7. **Download FreeSurfer**: Download FreeSurfer outputs for manual surface editing
- [x] 8. **Upload FreeSurfer**: Upload edited FreeSurfer outputs back to server (with automatic backup)
- [x] 9. **fMRIPrep Full**: Run full fMRIPrep workflows (anatomical + functional)
- [x] 10. **FSL GLM Setup**: Setup statistical model for FSL FEAT analysis
- [x] 11. **FSL Level 1**: Run Level 1 GLM analysis (individual runs)
- [x] 12. **FSL Level 2**: Run Level 2 GLM analysis (subject-level)
- [x] 13. **FSL Level 3**: Run Level 3 GLM analysis (group-level)
- [x] 14. **Tarball Utility**: Optimize inode usage by archiving sourcedata directories
- [ ] *Future:* Automated HDF5 file management and compression

> [!NOTE]
> - [x] indicates workflows that have been finished and validated
> - [ ] indicates workflows that are still under active development

## 📚 Documentation

Full documentation is available on [ReadTheDocs](https://fmriprep-workbench.readthedocs.io/).

For quick reference, see:
- [Installation Guide](docs/installation.md)
- [Configuration Guide](docs/configuration.md)
- [Usage Guide](docs/usage.md)
- [Workflows Guide](docs/workflows.md)
- [Changelog](CHANGELOG.md)
- [Release Process](RELEASING.md)
- [Contributing Guidelines](CONTRIBUTING.md)

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
- FSL FEAT statistical analysis
- FreeSurfer manual editing workflows

The template provides a standardized structure and validated scripts that you can build upon, while keeping your specific study parameters and paths separate in configuration files.

## What's Included

- Preprocessing scripts for handling fieldmaps and dummy scans
- Configuration templates and examples
- Documentation and usage guides
- Quality control utilities
- BIDS metadata management tools
- FSL FEAT statistical analysis pipeline (Level 1, 2, 3 GLM)
- FreeSurfer manual editing utilities (download/upload with safety features)
- An interactive terminal user interface (TUI) launcher for triggering pipeline steps

## Getting Started

After creating your repository from this template:

1. Clone your new repository
2. Copy `config.template.yaml` to `config.yaml` and customize parameters
3. Modify paths and scan parameters for your study
4. Copy `all-subjects.template.txt` to `all-subjects.txt` and add your subject IDs
5. Follow the [Configuration Guide](docs/configuration.md) for detailed setup instructions

---

# Quick Start Guide

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
# Step 1: FlyWheel download
./01-run.sbatch <fw_subject_id> <fw_session_id> <new_bids_subject_id>

# Step 2: dcm2niix BIDS conversion
./02-run.sbatch <fw_session_id> <new_bids_subject_id> [--skip-tar]

# Step 3: Prep for fMRIPrep
./03-run.sbatch

# Step 4: QC - verify metadata
./04-run.sbatch

# Step 5: QC - verify volume counts
./05-run.sbatch

# Step 6: fMRIPrep anatomical workflows only
./06-run.sbatch

# Step 7: Download FreeSurfer outputs for manual editing
./toolbox/download_freesurfer.sh --server <server> --user <user> --remote-dir <dir> --subjects <list>

# Step 8: Upload edited FreeSurfer outputs back to server
./toolbox/upload_freesurfer.sh --server <server> --user <user> --remote-dir <dir> --subjects <list>

# Step 9: fMRIPrep full workflows (anatomical + functional)
./07-run.sbatch

# Step 10: FSL GLM - Setup new statistical model
./08-fsl-glm/setup_glm.sh

# Step 11: FSL GLM - Run Level 1 analysis (individual runs)
./08-run.sbatch <model-name> [--no-feat]

# Step 12: FSL GLM - Run Level 2 analysis (subject-level)
./09-run.sbatch <model-name> [--no-feat]

# Step 13: FSL GLM - Run Level 3 analysis (group-level)
./10-run.sbatch <model-name> [--no-feat]

# Step 14: Tarball/Untar utility for sourcedata directories
./toolbox/tarball_sourcedata.sh [--tar-all|--tar-subjects|--untar-all|--untar-subjects] --sourcedata-dir <dir>
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

#### Subject ID Suffix Modifiers

Subject list files now support suffix modifiers for granular per-subject control. This allows you to maintain a single subject list while specifying different behavior for each subject.

**Syntax:** `subject_id:modifier1:modifier2:...`

**Supported Modifiers:**
- `step1`, `step2`, `step3`, `step4`, `step5`, `step6` - Only run specified step(s) for this subject
- `force` - Force rerun even if subject was already processed
- `skip` - Skip this subject entirely

**Examples:**
```text
101                # Standard subject ID, runs all steps normally
102:step4          # Only run step 4 (prep-fmriprep) for this subject
103:step4:step5    # Only run steps 4 and 5 for this subject
104:force          # Force rerun all steps for this subject
105:step5:force    # Only run step 5, force rerun
106:skip           # Skip this subject entirely
```

**Example Subject List File (e.g., `04-subjects.txt`):**
```text
101
102:step4
103:step4:force
104
105:skip
```

This feature allows the template to maintain a single subject list file while providing extensible, fine-grained control over how the pipeline handles different subjects.

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

---

## Toolbox Utilities

The `toolbox/` directory contains helpful utilities for managing your fMRI data:

### Sourcedata Tarball Utility

The `tarball_sourcedata.sh` script helps optimize inode usage on supercompute environments by archiving subject sourcedata directories into tar files.

**Features:**
- Tarball individual or all subject directories
- Extract tarballs back to sourcedata directories
- Support for comma-separated subject lists or subject list files
- Optional separate output directory for tar archives
- Automatic cleanup of original directories (with option to keep)
- Progress indicators and error handling

**Usage Examples:**

```bash
# Tarball all subjects in sourcedata directory
./toolbox/tarball_sourcedata.sh --tar-all --sourcedata-dir /path/to/sourcedata

# Tarball specific subjects (removes original directories by default)
./toolbox/tarball_sourcedata.sh --tar-subjects "001,002,003" --sourcedata-dir /path/to/sourcedata

# Tarball subjects from a file
./toolbox/tarball_sourcedata.sh --tar-subjects all-subjects.txt --sourcedata-dir /path/to/sourcedata

# Tarball but keep original directories
./toolbox/tarball_sourcedata.sh --tar-all --sourcedata-dir /path/to/sourcedata --keep-original

# Store tar files in a separate directory
./toolbox/tarball_sourcedata.sh --tar-all --sourcedata-dir /path/to/sourcedata --output-dir /path/to/tarballs

# Extract all tar files
./toolbox/tarball_sourcedata.sh --untar-all --sourcedata-dir /path/to/sourcedata

# Extract specific subjects
./toolbox/tarball_sourcedata.sh --untar-subjects "001,002" --sourcedata-dir /path/to/sourcedata

# Get help
./toolbox/tarball_sourcedata.sh --help
```

**Why use this utility?**
- Reduces inode usage significantly on shared supercompute environments
- Each subject's sourcedata directory may contain thousands of DICOM files
- Archiving into a single tar file per subject drastically reduces inode consumption (e.g., a directory tree with 5000 files using 5000+ inodes becomes a single tar file using 1 inode)
- Easy to extract subjects back when needed for reprocessing or analysis

### FreeSurfer Manual Editing Utilities

The `download_freesurfer.sh` and `upload_freesurfer.sh` scripts enable a complete workflow for manually editing FreeSurfer surface reconstructions.

**Features:**
- Download FreeSurfer outputs from remote server via rsync
- Upload edited surfaces back to server with automatic backups
- Interactive and non-interactive modes
- Support for individual subjects or batch downloads/uploads
- Multiple safety confirmations before destructive operations
- Automatic timestamped backups of original surfaces

**Usage Examples:**

```bash
# Download FreeSurfer outputs interactively
./toolbox/download_freesurfer.sh

# Download specific subjects non-interactively
./toolbox/download_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user mysunetid \
  --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
  --subjects sub-001,sub-002

# Upload edited outputs with automatic backup
./toolbox/upload_freesurfer.sh

# Upload specific subjects non-interactively
./toolbox/upload_freesurfer.sh \
  --server login.sherlock.stanford.edu \
  --user mysunetid \
  --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
  --subjects sub-001,sub-002
```

**Complete Workflow:**
1. Run fMRIPrep anatomical workflows only (Step 6): `./06-run.sbatch`
2. Download FreeSurfer outputs: `./toolbox/download_freesurfer.sh`
3. Edit surfaces locally using Freeview or other tools
4. Upload edited surfaces: `./toolbox/upload_freesurfer.sh`
5. Run full fMRIPrep workflows (Step 7): `./07-run.sbatch`

See `toolbox/FREESURFER_EDITING.md` for complete documentation including:
- When to perform manual edits
- Freeview editing instructions
- Common editing tasks (brainmask, white matter, surfaces)
- Troubleshooting guide
- Best practices

### Other Utilities

- `verify_nii_metadata.py` - Quality control for converted NIfTI metadata
- `dir_checksum_compare.py` - Compare directories using checksums
- `pull_fmriprep_reports.sh` - Download fMRIPrep HTML reports from server
- `summarize_bold_scan_volume_counts.sh` - Validate scan volumes match expected counts

---

> [!NOTE]
> ### Comments, suggestions, questions, issues?
>
> Please use the issues tab (<https://github.com/shawntz/fmriprep-workbench/issues>) to make note of any bugs, comments, suggestions, feedback, etc… all are welcomed and appreciated, thanks!
>
> -Shawn

---

See our [Contributing Guidelines](CONTRIBUTING.md) for how to get involved.
