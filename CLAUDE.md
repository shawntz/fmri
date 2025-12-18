# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a template repository for fMRI preprocessing pipelines that handles the full workflow from scanner acquisition downloads to fMRIPrep execution. The pipeline is designed for Stanford Memory Lab but is generalizable to any fMRI study using fieldmap-based distortion correction.

The codebase is primarily Bash shell scripts orchestrated via Slurm job manager, with Python utilities for data validation and conversion tasks.

## Core Architecture

### Pipeline Structure

The preprocessing workflow is organized into numbered directories (01-07) representing sequential pipeline steps:

1. **01-fw2server**: Download scanner acquisitions from Flywheel to server
2. **02-dcm2niix**: Convert DICOM to NIfTI in BIDS format using heudiconv
3. **03-prep-fmriprep**: Remove dummy scans, configure fieldmap susceptibility distortion correction (SDC)
4. **QC Step 4**: Verify DICOM → NIfTI → BIDS metadata conversion (via toolbox)
5. **QC Step 5**: Verify scan volume counts match expected values (via toolbox)
6. **06-run-fmriprep**: Run fMRIPrep anatomical workflows only (optional, for manual FreeSurfer editing)
7. **07-run-fmriprep**: Run full fMRIPrep workflows (anatomical + functional)

Each step directory contains the core processing script. The root directory contains `XX-run.sbatch` files that serve as Slurm job submission wrappers for each step.

### Configuration System

**Central Configuration**: `settings.sh` (created from `settings.template.sh`)

This file controls all pipeline behavior including:
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

**Settings Sourcing**: All scripts source `./settings.sh` at the top to inherit configuration.

**Modular Utilities**: The `toolbox/` directory contains reusable QC and diagnostic scripts.

## Running the Pipeline

### Interactive TUI Launcher (Recommended)

```bash
./launch
```

This Python-based TUI provides an interactive menu for selecting pipeline steps, setting parameters, and confirming execution. It's more user-friendly than manual sbatch submission.

### Manual Execution

```bash
# Example: Run step 1 (FlyWheel download)
./01-run.sbatch <fw_subject_id> <fw_session_id> <new_bids_subject_id>

# Example: Run step 2 (dcm2niix conversion)
./02-run.sbatch

# Example: Run step 3 (prep for fMRIPrep)
./03-run.sbatch

# Example: QC - verify metadata
./toolbox/verify_nii_metadata.sh

# Example: QC - verify scan volumes
./toolbox/summarize_bold_scan_volume_counts.sh

# Example: Run fMRIPrep (anatomical only)
./06-run.sbatch

# Example: Run fMRIPrep (full workflows)
./07-run.sbatch
```

### fMRIPrep Execution Details

- **Step 6** (`06-run-fmriprep`): Runs fMRIPrep with `--anat-only` flag. Use this when you plan to manually edit Freesurfer surfaces before functional preprocessing.
- **Step 7** (`07-run-fmriprep`): Runs full fMRIPrep (anatomical + functional workflows). Skip step 6 if not doing manual edits.

Both steps use subject lists (default: `06-subjects.txt` for step 6, `all-subjects.txt` for step 7) and respect subject modifiers.

fMRIPrep is executed via Singularity/Apptainer container specified by `SINGULARITY_IMAGE` in settings.

## Critical Configuration Requirements

Before running any pipeline step, you MUST configure `settings.sh`:

1. Copy template: `cp settings.template.sh settings.sh`
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

Located in `toolbox/`, these are standalone utilities for QC and data management:

**Quality Control**:
- `verify_nii_metadata.py` / `verify_nii_metadata.sh`: Validate BIDS metadata in NIfTI JSON sidecars
- `summarize_bold_scan_volume_counts.sh`: Check scan volumes match expected counts, generates timestamped diagnostic reports
- `summarize_diagnostics.py`: Generate summary reports from diagnostic CSV files

**Data Management**:
- `tarball_sourcedata.sh`: Archive sourcedata directories to reduce inode usage on supercompute clusters
  - Supports tarball/untar operations for all subjects or specific subject lists
  - Useful when dealing with thousands of DICOM files per subject
- `pull_fmriprep_reports.sh`: Download fMRIPrep HTML reports from server
- `dir_checksum_compare.py`: Compare directories using checksums

**Parsing Utilities**:
- `parse_subject_modifiers.sh`: Parse subject ID suffix modifiers (sourced by pipeline scripts)

## Development Commands

### Testing Configuration

```bash
# Validate settings.sh loads without errors
source ./settings.sh

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

The `02-dcm2niix` step uses heudiconv with a custom heuristic (`dcm_heuristic.py`). If you manually merged scans from multiple acquisition sessions with different study identifiers, use the `all` grouping strategy to bypass the study identifier check:

```bash
./02-dcm2niix/dcm2niix.sh 02-dcm2niix <fw_session_id> <subject_id> all
```

Default grouping is `studyUID` which will fail on conflicting study identifiers.

### Subject ID Modifiers

When you need fine-grained control over which subjects run in which steps:
- Use modifiers in subject list files instead of creating separate lists
- Example: `103:step4:step5` only runs steps 4 and 5 for subject 103
- The `force` modifier reruns a subject even if marked as processed
- The `skip` modifier completely skips a subject

### Singularity/Apptainer Images

fMRIPrep and heudiconv are run via Singularity/Apptainer containers. Ensure images exist at paths specified in `settings.sh`:
- `${SINGULARITY_IMAGE_DIR}/${SINGULARITY_IMAGE}` for fMRIPrep
- `${SINGULARITY_IMAGE_DIR}/${HEUDICONV_IMAGE}` for dcm2niix conversion

### Templateflow and Caching

fMRIPrep requires templateflow templates. The pipeline uses:
- `TEMPLATEFLOW_HOST_HOME`: Host cache directory (e.g., `~/.cache/templateflow`)
- `FMRIPREP_HOST_CACHE`: fMRIPrep-specific cache (e.g., `~/.cache/fmriprep`)
- Both are mounted into the container at runtime

### Freesurfer License

A valid Freesurfer license file is required for fMRIPrep. Set `FREESURFER_LICENSE` in settings.sh to the path of your license file.

## Common Workflows

**Starting a new study**:
1. Create repository from template
2. Configure `settings.sh` with study-specific parameters
3. Create `all-subjects.txt` with subject IDs
4. Test on single subject before batch processing
5. Run pipeline steps sequentially (1 → 2 → 3 → QC → 6/7)

**Rerunning specific subjects**:
1. Add subject IDs with `:force` modifier to subject list
2. Rerun the desired step

**Manual Freesurfer editing workflow**:
1. Run step 6 (anatomical only)
2. Download Freesurfer outputs for manual editing
3. Re-upload edited Freesurfer directories
4. Run step 7 (full workflows) using edited surfaces

**Optimizing inode usage**:
1. After DICOM conversion, tarball sourcedata directories
2. Use `toolbox/tarball_sourcedata.sh --tar-all --sourcedata-dir <path>`
3. Extract when needed with `--untar-subjects`
