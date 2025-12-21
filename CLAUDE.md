# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a template repository for fMRI preprocessing pipelines that handles the full workflow from scanner acquisition downloads to fMRIPrep execution. The pipeline is designed for Stanford Memory Lab but is generalizable to any fMRI study using fieldmap-based distortion correction.

The codebase is primarily Bash shell scripts orchestrated via Slurm job manager, with Python utilities for data validation and conversion tasks.

## Core Architecture

### Pipeline Structure

The preprocessing workflow consists of 14 steps organized as follows:

**Steps 1-6: Initial Preprocessing**
1. **01-fw2server**: Download scanner acquisitions from Flywheel to server
2. **02-dcm2niix**: Convert DICOM to NIfTI in BIDS format using heudiconv
3. **03-prep-fmriprep**: Remove dummy scans, configure fieldmap susceptibility distortion correction (SDC)
4. **04-qc-metadata**: Verify DICOM → NIfTI → BIDS metadata conversion
5. **05-qc-volumes**: Verify scan volume counts match expected values
6. **06-run-fmriprep**: Run fMRIPrep anatomical workflows only (optional, for manual FreeSurfer editing)

**Steps 7-8: FreeSurfer Manual Editing (Toolbox Utilities)**
7. **toolbox/download_freesurfer.sh**: Download FreeSurfer outputs for manual editing
8. **toolbox/upload_freesurfer.sh**: Upload edited FreeSurfer outputs back to server

**Step 9: Full fMRIPrep**
9. **07-run-fmriprep**: Run full fMRIPrep workflows (anatomical + functional)

**Steps 10-13: FSL GLM Statistical Analysis**
10. **08-fsl-glm/setup_glm.sh**: Setup new statistical model
11. **08-run.sbatch**: FSL GLM Level 1 analysis (individual runs)
12. **09-run.sbatch**: FSL GLM Level 2 analysis (subject-level)
13. **10-run.sbatch**: FSL GLM Level 3 analysis (group-level)

**Step 14: Data Management Utility**
14. **toolbox/tarball_sourcedata.sh**: Tarball/untar utility for sourcedata directories

Each numbered step that has its own directory (1-6, 9) includes both a directory (e.g., `01-fw2server/`) containing the core processing script and a corresponding `XX-run.sbatch` file in the root directory that serves as the Slurm job submission wrapper. Steps 7-8 and 14 are standalone toolbox utilities. Steps 10-13 share the `08-fsl-glm/` directory for statistical model setup; their execution is driven by three separate Slurm wrappers: `08-run.sbatch` for Step 11 (Level 1), `09-run.sbatch` for Step 12 (Level 2), and `10-run.sbatch` for Step 13 (Level 3).

### FSL GLM Statistical Analysis

After completing fMRIPrep preprocessing, you can perform statistical analysis using FSL FEAT. The `08-fsl-glm` directory contains a complete pipeline for creating and executing GLM analysis:

**Level 1 (Individual Runs)**: First-level analysis examining each task run separately
**Level 2 (Subject-Level)**: Second-level analysis combining runs within subjects
**Level 3 (Group-Level)**: Third-level analysis performing group statistics

The FSL GLM pipeline:
- Creates `.fsf` files for each analysis level
- Runs FSL FEAT on generated `.fsf` files
- Uses SLURM job arrays for parallel processing (or falls back to joblib/serial if SLURM unavailable)
- Integrates with the fmriprep-workbench configuration system

See `08-fsl-glm/README.md` for detailed usage instructions.

### Configuration System

**Central Configuration**: `config.yaml` (created from `config.template.yaml`)

This YAML file controls all pipeline behavior including:
- Directory paths (BASE_DIR, RAW_DIR, TRIM_DIR, etc.)
- Study parameters (task names, run numbers, dummy scan count)
- Data validation values (expected volume counts)
- Fieldmap-to-BOLD mapping (declares which fieldmap covers which runs)
- Subject ID lists and per-step mappings
- Slurm job parameters (time, memory, CPU allocation)
- fMRIPrep-specific settings (version, output spaces, resource allocation)

**Subject List Files**: `all-subjects.txt` (from `all-subjects.template.txt`) or step-specific files like `06-subjects.txt`

Subject list files support suffix modifiers for granular control:
- Syntax: `subject_id:modifier1:modifier2`
- Modifiers: `step1-6` (run only specific steps), `force` (rerun even if processed), `skip` (skip subject)
- Example: `102:step4:force` runs only step 4 and forces rerun
- Parsing handled by `toolbox/parse_subject_modifiers.sh`

### Key Design Patterns

**Slurm Array Jobs**: Most steps use Slurm array jobs to process multiple subjects in parallel. The array index maps to line numbers in subject list files.

**Skip Logic**: Each step checks `XX-processed_subjects.txt` files to avoid reprocessing. The `force` modifier overrides this.

**Settings Loading**: All scripts source `./load_config.sh` which parses the YAML configuration and exports environment variables.

**Modular Utilities**: The `toolbox/` directory contains reusable QC and diagnostic scripts.

## Running the Pipeline

### Interactive TUI Launcher (Recommended)

```bash
./launch
```

This Python-based TUI provides an interactive menu for selecting pipeline steps, setting parameters, and confirming execution. It's more user-friendly than manual sbatch submission.

### Manual Execution

```bash
# Step 1: Download from FlyWheel -> Server
./01-run.sbatch <fw_subject_id> <fw_session_id> <new_bids_subject_id>

# Step 2: Run dcm2niix (DICOM -> BIDS format conversion)
./02-run.sbatch <fw_session_id> <new_bids_subject_id> [--skip-tar]

# Step 3: Prep for fMRIPrep (remove dummy scans, update fmap JSON, config SDC)
./03-run.sbatch

# Step 4: QC - Verify dcm -> nii -> bids metadata
./04-run.sbatch

# Step 5: QC - Verify number of volumes per scan file
./05-run.sbatch

# Step 6: Run fMRIPrep anatomical workflows only (for manual edits)
./06-run.sbatch

# Step 7: Download FreeSurfer outputs for manual editing
./toolbox/download_freesurfer.sh --server <server> --user <user> --remote-dir <dir> --subjects <list>

# Step 8: Upload edited FreeSurfer outputs back to server
./toolbox/upload_freesurfer.sh --server <server> --user <user> --remote-dir <dir> --subjects <list>

# Step 9: Run remaining fMRIPrep steps (full anatomical + functional workflows)
./07-run.sbatch

# Step 10: FSL GLM - Setup new statistical model
./launch  # Select option 10
# Or run directly:
./08-fsl-glm/setup_glm.sh

# Step 11: FSL GLM - Run Level 1 analysis (individual runs)
./08-run.sbatch <model-name>
# Or with --no-feat to only create FSF files:
./08-run.sbatch <model-name> --no-feat

# Step 12: FSL GLM - Run Level 2 analysis (subject-level)
./09-run.sbatch <model-name>

# Step 13: FSL GLM - Run Level 3 analysis (group-level)
./10-run.sbatch <model-name>

# Step 14: Tarball/Untar utility for sourcedata directories
./toolbox/tarball_sourcedata.sh [--tar-all|--tar-subjects|--untar-all|--untar-subjects] --sourcedata-dir <dir>
```

### fMRIPrep Execution Details

- **Step 6** (`06-run.sbatch` / `06-run-fmriprep/`): Runs fMRIPrep with `--anat-only` flag. Use this when you plan to manually edit FreeSurfer surfaces before functional preprocessing.
- **Step 9** (`07-run.sbatch` / `07-run-fmriprep/`): Runs full fMRIPrep (anatomical + functional workflows). Skip step 6 if not doing manual edits.

Both steps use subject lists (default: `06-subjects.txt` for step 6, `all-subjects.txt` for step 9) and respect subject modifiers.

fMRIPrep is executed via Singularity/Apptainer container specified by `SINGULARITY_IMAGE` in config.yaml.

## Critical Configuration Requirements

Before running any pipeline step, you MUST configure `config.yaml`:

1. Copy template: `cp config.template.yaml config.yaml`
2. Set all directory paths (BASE_DIR, RAW_DIR, TRIM_DIR, etc.)
3. Configure study parameters (task_id, run_numbers, n_dummy)
4. Set expected volume counts for validation (EXPECTED_FMAP_VOLS, EXPECTED_BOLD_VOLS, EXPECTED_BOLD_VOLS_AFTER_TRIMMING)
5. Define fieldmap-to-BOLD mapping in the `fmap_mapping` associative array
6. Create subject list: `cp all-subjects.template.txt all-subjects.txt` and populate with subject IDs
7. Configure Slurm and fMRIPrep parameters

**Fieldmap Mapping Example**:
```bash
declare -A fmap_mapping=(
    ["01"]="01"  # BOLD run 01 uses fieldmap 01
    ["02"]="01"  # BOLD run 02 uses fieldmap 01
    ["03"]="02"  # BOLD run 03 uses fieldmap 02
    ["04"]="02"  # BOLD run 04 uses fieldmap 02
)
```

This mapping determines which fieldmap is used for susceptibility distortion correction for each BOLD run.

## Toolbox Utilities

Located in `toolbox/`, these are shared utilities used by pipeline steps and available for standalone use:

**Quality Control**:
- `verify_nii_metadata.py`: Validate BIDS metadata in NIfTI JSON sidecars (called by step 4)
- `summarize_diagnostics.py`: Generate summary reports from diagnostic CSV files (called by step 5)
- `parse_subject_modifiers.sh`: Parse subject ID suffix modifiers (sourced by all steps)

**Data Management**:
- `tarball_sourcedata.sh`: Archive sourcedata directories to reduce inode usage on supercompute clusters
  - Supports tarball/untar operations for all subjects or specific subject lists
  - Useful when dealing with thousands of DICOM files per subject
- `pull_fmriprep_reports.sh`: Download fMRIPrep HTML reports from server
- `dir_checksum_compare.py`: Compare directories using checksums

**FreeSurfer Manual Editing**:
- `download_freesurfer.sh`: Download FreeSurfer outputs from remote server for manual surface editing
  - Interactive and non-interactive modes
  - Supports downloading all subjects or specific subject lists
  - Uses rsync for efficient transfer
  - Default download location: `~/freesurfer_edits`

- `upload_freesurfer.sh`: Upload edited FreeSurfer outputs back to server
  - Automatic timestamped backups of original surfaces before upload
  - Multiple safety confirmations to prevent accidental data loss
  - Verifies local files exist before uploading
  - Supports uploading all subjects or specific subject lists
  - Provides revert instructions after upload

See `toolbox/FREESURFER_EDITING.md` for complete workflow documentation.

**Parsing Utilities**:
- `parse_subject_modifiers.sh`: Parse subject ID suffix modifiers (sourced by pipeline scripts)

## Development Commands

### Testing Configuration

```bash
# Validate config.yaml loads without errors
source ./load_config.sh

# Check subject count
wc -l < all-subjects.txt

# Test subject modifier parsing
source ./toolbox/parse_subject_modifiers.sh
parse_subject_modifiers "102:step4:force" "03-prep-fmriprep"
echo "Subject ID: ${SUBJECT_ID}"
echo "Modifiers: ${SUBJECT_MODIFIERS[*]}"
echo "Should skip: ${SHOULD_SKIP}"
echo "Should force: ${SHOULD_FORCE}"
```

### Checking Logs

```bash
# Check Slurm job logs
ls ${BASE_DIR}/logs/slurm/<step-name>/

# Check subject-specific processing logs
ls ${BASE_DIR}/logs/slurm/subjects/

# Check fMRIPrep workflow logs
ls ${BASE_DIR}/logs/workflows/

# Check diagnostic reports
ls logs/diagnostics/
```

### Monitoring Jobs

```bash
# Check job queue
squeue -u $USER

# Check specific job
squeue -j <job_id>

# Cancel job
scancel <job_id>
```

## Important Notes

### DICOM Conversion (Step 2)

The `02-dcm2niix` step uses heudiconv with a custom heuristic (`dcm_heuristic.py`). The grouping strategy is hardcoded to `all` to avoid conflicts from manually merged scans with different study identifiers. This is the more permissive option that bypasses the 'Conflicting study identifiers found' assertion.

```bash
# Basic usage
./02-run.sbatch <fw_session_id> <subject_id>

# Skip tar extraction for manually configured directories
./02-run.sbatch <fw_session_id> <subject_id> --skip-tar
```

### Subject ID Modifiers

When you need fine-grained control over which subjects run in which steps:
- Use modifiers in subject list files instead of creating separate lists
- Example: `103:step4:step5` only runs steps 4 and 5 for subject 103
- The `force` modifier reruns a subject even if marked as processed
- The `skip` modifier completely skips a subject

### Singularity/Apptainer Images

fMRIPrep and heudiconv are run via Singularity/Apptainer containers. Ensure images exist at paths specified in `config.yaml`:
- `${SINGULARITY_IMAGE_DIR}/${SINGULARITY_IMAGE}` for fMRIPrep
- `${SINGULARITY_IMAGE_DIR}/${HEUDICONV_IMAGE}` for dcm2niix conversion

### Templateflow and Caching

fMRIPrep requires templateflow templates. The pipeline uses:
- `TEMPLATEFLOW_HOST_HOME`: Host cache directory (e.g., `~/.cache/templateflow`)
- `FMRIPREP_HOST_CACHE`: fMRIPrep-specific cache (e.g., `~/.cache/fmriprep`)
- Both are mounted into the container at runtime

### FreeSurfer License

A valid FreeSurfer license file is required for fMRIPrep. Set `directories.freesurfer_license` in config.yaml to the path of your license file.

## Common Workflows

**Starting a new study**:
1. Create repository from template
2. Configure `config.yaml` with study-specific parameters
3. Create `all-subjects.txt` with subject IDs
4. Test on single subject before batch processing
5. Run pipeline steps sequentially (1 → 2 → 3 → 4 → 5 → 6/9)
   - Use step 6 only if planning manual FreeSurfer edits (steps 7-8), otherwise skip to step 9

**Rerunning specific subjects**:
1. Add subject IDs with `:force` modifier to subject list
2. Rerun the desired step

**Manual FreeSurfer editing workflow**:
1. Run step 6 (anatomical only): `./06-run.sbatch`
2. Download FreeSurfer outputs for manual editing (step 7):
   ```bash
   ./launch  # Select option 7
   # Or run directly:
   ./toolbox/download_freesurfer.sh \
     --server login.sherlock.stanford.edu \
     --user mysunetid \
     --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
     --subjects sub-001,sub-002
   ```
3. Edit surfaces locally using Freeview or other tools:
   ```bash
   cd ~/freesurfer_edits/sub-001
   freeview -v mri/T1.mgz -v mri/brainmask.mgz \
     -f surf/lh.white:edgecolor=blue \
     -f surf/lh.pial:edgecolor=red \
     -f surf/rh.white:edgecolor=blue \
     -f surf/rh.pial:edgecolor=red
   # Make edits to brainmask, white matter, or surfaces
   # Rerun FreeSurfer if needed after brainmask/WM edits:
   recon-all -autorecon2-cp -autorecon3 -s sub-001 -sd ~/freesurfer_edits
   ```
4. Upload edited FreeSurfer outputs back to server (step 8, with automatic backup):
   ```bash
   ./launch  # Select option 8
   # Or run directly:
   ./toolbox/upload_freesurfer.sh \
     --server login.sherlock.stanford.edu \
     --user mysunetid \
     --remote-dir /oak/stanford/groups/mylab/projects/mystudy \
     --subjects sub-001,sub-002
   ```
5. Run step 9 (full workflows) which will use edited surfaces: `./07-run.sbatch`

**Important FreeSurfer Editing Notes**:
- Only edit after Step 6 (anatomical-only fMRIPrep) completes
- Backups are automatically created on server as `{subject}.backup.{timestamp}`
- Download location defaults to `~/freesurfer_edits/` but can be customized
- Use `--no-backup` flag cautiously (not recommended)
- Common edits: brainmask (skull stripping), white matter, pial/white surfaces
- After brainmask or WM edits, rerun `recon-all -autorecon2-cp -autorecon3`
- Surface edits are typically final and don't require reprocessing

**Optimizing inode usage**:
1. After DICOM conversion, tarball sourcedata directories
2. Use `toolbox/tarball_sourcedata.sh --tar-all --sourcedata-dir <path>`
3. Extract when needed with `--untar-subjects`

**FSL GLM statistical analysis workflow**:
1. Complete fMRIPrep preprocessing (steps 1-9, or steps 1-6 + 9 if skipping manual FreeSurfer edits)
2. Setup GLM model (step 10) with `./launch` (option 10) or `./08-fsl-glm/setup_glm.sh`
3. Configure model parameters in `BASE_DIR/model/level1/model-<modelname>/`:
   - Edit `model_params.json` for analysis parameters
   - Edit `condition_key.json` to define experimental conditions
   - Edit `task_contrasts.json` (optional) to define contrasts
   - Edit `confounds.json` (optional) to select motion/confound regressors
4. Create EV (explanatory variable) timing files in onset directories
5. Run Level 1 analysis (step 11): `./08-run.sbatch <model-name>`
6. After Level 1 completes, run Level 2 (step 12): `./09-run.sbatch <model-name>`
7. After Level 2 completes, run Level 3 (step 13): `./10-run.sbatch <model-name>`
8. View results in `.feat` and `.gfeat` directories

Note: The `--no-feat` flag can be used to only create FSF files without running FEAT, useful for checking design matrices before full analysis.

See `08-fsl-glm/README.md` for complete documentation.
