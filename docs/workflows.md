# Workflows

This document provides detailed information about each preprocessing workflow
in the fMRIPrep Workbench template.

!!! note "v0.2.0+ Pipeline Expansion"

    The pipeline has been expanded to 14 steps, including dedicated FreeSurfer editing utilities (steps 7-8), FSL FEAT statistical analysis (steps 10-13), and data management tools (step 14).

## Pipeline Overview

The preprocessing and analysis pipeline is organized into 14 steps, covering data acquisition through statistical analysis:

```text
Steps 1-5: Data Acquisition & QC
FlyWheel -> dcm2niix -> Prep -> QC Meta -> QC Vols

Steps 6-9: fMRIPrep Processing (with optional FreeSurfer editing)
fMRIPrep Anat -> FS Download -> FS Upload -> fMRIPrep Full
   (Step 6)       (Step 7)      (Step 8)      (Step 9)

Steps 10-13: FSL FEAT Statistical Analysis
GLM Setup -> Level 1 -> Level 2 -> Level 3
 (Step 10)   (Step 11)  (Step 12)  (Step 13)

Step 14: Data Management
Tarball Utility
```

### Pipeline Steps Summary

| Step | Directory/Script | SLURM Job Name | Description |
|------|------------------|----------------|-------------|
| 1    | `01-fw2server` | `fmriprep-workbench-1` | Download scanner acquisitions from FlyWheel |
| 2    | `02-dcm2niix` | `fmriprep-workbench-2` | Convert DICOM to NIfTI in BIDS format |
| 3    | `03-prep-fmriprep` | `fmriprep-workbench-3` | Remove dummy scans, configure fieldmap SDC |
| 4    | `04-qc-metadata` | `fmriprep-workbench-4` | Verify DICOM to NIfTI to BIDS metadata conversion |
| 5    | `05-qc-volumes` | `fmriprep-workbench-5` | Verify scan volume counts match expected values |
| 6    | `06-run-fmriprep` | `fmriprep-workbench-6` | Run fMRIPrep anatomical workflows only (optional) |
| 7    | `toolbox/download_freesurfer.sh` | N/A | Download FreeSurfer outputs for manual editing (optional) |
| 8    | `toolbox/upload_freesurfer.sh` | N/A | Upload edited FreeSurfer outputs (optional) |
| 9    | `09-run-fmriprep` | `fmriprep-workbench-9` | Run full fMRIPrep workflows (anatomical + functional) |
| 10   | `10-fsl-glm/setup_glm.sh` | N/A | Setup FSL FEAT statistical model |
| 11   | `10-fsl-glm/` (`08-run.sbatch`) | `fmriprep-workbench-11` | Run FSL Level 1 analysis (individual runs) |
| 12   | `10-fsl-glm/` (`09-run.sbatch`) | `fmriprep-workbench-12` | Run FSL Level 2 analysis (subject-level) |
| 13   | `10-fsl-glm/` (`10-run.sbatch`) | `fmriprep-workbench-13` | Run FSL Level 3 analysis (group-level) |
| 14   | `toolbox/tarball_sourcedata.sh` | N/A | Optimize inode usage by archiving sourcedata |

## Workflow Details

### 1. FlyWheel Transfer (01-fw2server)

**Purpose:** Automated transfer of scanner acquisitions from FlyWheel to server

**Script:** `01-fw2server/download.sh`

**Inputs:**
- FlyWheel project ID and session information
- FlyWheel API credentials

**Outputs:**
- Raw DICOM files on server storage

**Configuration (config.yaml):**

```yaml
user:
  fw_group_id: 'pi'
  fw_project_id: 'projectname'

scan:
  fw_cli_api_key_file: '~/flywheel_api_key.txt'
  fw_url: 'cni.flywheel.io'
```

### 2. DICOM to NIfTI Conversion (02-dcm2niix)

**Purpose:** Convert DICOM files to NIfTI format using heudiconv/dcm2niix

**Script:** `02-dcm2niix/dcm2niix.sh`

**Inputs:**
- Raw DICOM files

**Outputs:**
- BIDS-formatted NIfTI files (.nii.gz)
- JSON metadata sidecar files

**BIDS Structure:**

```text
bids/
├── dataset_description.json
├── participants.tsv
└── sub-<subject_id>/
    ├── anat/
    │   └── sub-<subject_id>_T1w.nii.gz
    ├── func/
    │   ├── sub-<subject_id>_task-<task>_run-01_bold.nii.gz
    │   └── sub-<subject_id>_task-<task>_run-01_bold.json
    └── fmap/
        └── sub-<subject_id>_dir-AP_epi.nii.gz
```

**Features:**
- Automatic metadata extraction
- BIDS naming conventions
- Compressed output (gzip)

### 3. Prep for fMRIPrep (03-prep-fmriprep)

**Purpose:** Prepare data for fMRIPrep processing

**Script:** `03-prep-fmriprep/prepare_fmri.sh`

**Key Operations:**

#### a. Dummy Scan Removal

Remove initial dummy TRs (specified by `n_dummy` in config):

```yaml
# In config.yaml
scan:
  n_dummy: 5
```

#### b. Fieldmap Setup

Configure fieldmap-based susceptibility distortion correction:

- Map fieldmaps to BOLD runs via `fmap_mapping`
- Update IntendedFor fields in JSON metadata
- Validate fieldmap parameters

#### c. Data Validation

- Check expected volume counts
- Verify BIDS compliance
- Validate JSON metadata

**Outputs:**
- Trimmed BOLD files (without dummy scans)
- Updated JSON metadata with IntendedFor fields
- Validated BIDS structure

### 4. QC Metadata Verification (04-qc-metadata)

**Purpose:** Verify DICOM to NIfTI to BIDS metadata conversion

**Script:** `04-qc-metadata/verify_metadata.sh`

!!! note "v0.2.0 Change"

    This QC step was previously available only via the toolbox (`toolbox/verify_nii_metadata.sh`). It is now a dedicated pipeline step with its own sbatch wrapper for consistent SLURM job management.

**Validations Performed:**
- JSON sidecar file existence
- Required BIDS metadata fields
- Echo time and repetition time values
- Phase encoding direction consistency
- IntendedFor field correctness in fieldmap metadata

**Outputs:**
- Validation reports
- Error logs for any failed checks

### 5. QC Volume Verification (05-qc-volumes)

**Purpose:** Verify scan volume counts match expected values

**Script:** `05-qc-volumes/check_volumes.sh`

!!! note "v0.2.0 Change"

    This QC step was previously available only via the toolbox (`toolbox/summarize_bold_scan_volume_counts.sh`). It is now a dedicated pipeline step with its own sbatch wrapper.

**Validations Performed:**
- Fieldmap volume counts against `validation.expected_fmap_vols`
- BOLD volume counts against `validation.expected_bold_vols`
- Trimmed BOLD volumes against `validation.expected_bold_vols_after_trimming`

**Configuration (config.yaml):**

```yaml
validation:
  expected_fmap_vols: 12
  expected_bold_vols: 220
  expected_bold_vols_after_trimming: 215
```

**Outputs:**
- Timestamped diagnostic reports
- Summary CSV files for batch review

### 6. fMRIPrep Anatomical (06-run-fmriprep)

**Purpose:** Run fMRIPrep anatomical workflows only (with `--anat-only` flag)

**Script:** `06-run-fmriprep/run_fmriprep.sh`

**Use Case:** When manual FreeSurfer surface editing is needed before
functional preprocessing

**Inputs:**
- BIDS-formatted anatomical data
- FreeSurfer license

**Outputs:**
- FreeSurfer segmentation
- Anatomical preprocessing outputs
- Quality control reports

**Configuration (config.yaml):**

```yaml
fmriprep:
  output_spaces: 'MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5'

pipeline:
  fmriprep_version: '24.0.1'
```

**Execution:**

```bash
./06-run.sbatch
```

!!! note

    Step 6 automatically passes the `--anat-only` flag to fMRIPrep. Skip this step if you do not need manual FreeSurfer editing.

### 7. fMRIPrep Complete (09-run-fmriprep)

**Purpose:** Run complete fMRIPrep preprocessing (anatomical + functional)

**Script:** `09-run-fmriprep/run_fmriprep.sh`

**Inputs:**
- BIDS-formatted data (anatomical and functional)
- FreeSurfer outputs (if using edited surfaces from step 6)
- Fieldmap data

**Outputs:**
- Preprocessed BOLD data in configured output spaces
- Confound regressors (motion, CompCor, FD, DVARS)
- HTML quality reports
- Anatomical-functional co-registration

**Processing Steps:**

1. Skull stripping
2. Brain tissue segmentation
3. Spatial normalization
4. Surface reconstruction (if not using existing from step 6)
5. BOLD preprocessing:

   - Slice timing correction
   - Motion correction
   - Susceptibility distortion correction (using fieldmaps)
   - Co-registration to anatomical
   - Normalization to template space
   - Resampling to target resolution

6. Confound estimation:

   - Motion parameters
   - CompCor components
   - Framewise displacement
   - DVARS

**Quality Metrics (config.yaml):**

```yaml
fmriprep:
  fd_spike_threshold: 0.9
  dvars_spike_threshold: 3.0
```

**Execution:**

```bash
./07-run.sbatch
```

## Data Organization

### Output Structure

```text
derivatives/fmriprep-<version>/
├── dataset_description.json
└── sub-<subject_id>/
    ├── sub-<subject_id>.html          # QC report
    ├── anat/
    │   ├── sub-<subject_id>_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz
    │   └── sub-<subject_id>_space-MNI152NLin2009cAsym_label-GM_probseg.nii.gz
    ├── func/
    │   ├── sub-<subject_id>_task-<task>_run-01_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
    │   └── sub-<subject_id>_task-<task>_run-01_desc-confounds_timeseries.tsv
    └── figures/
        └── sub-<subject_id>_task-<task>_run-01_desc-carpetplot_bold.svg
```

## Workflow Customization

### Per-Subject Control

Use subject ID modifiers for fine-grained control:

```text
# Run only specific steps
101:step4
102:step4:step5

# Force reprocessing
103:force
104:step5:force

# Skip subjects
105:skip
```

### Resource Configuration

Adjust resources per workflow type in `config.yaml`:

**General Workflows (Steps 1-5):**

```yaml
slurm:
  cpus: 8
  mem: '4G'
  time: '2:00:00'
```

**fMRIPrep Workflows (Steps 6-7):**

```yaml
fmriprep_slurm:
  cpus_per_task: 16
  mem_per_cpu: '4G'
  time: '48:00:00'
```

## Advanced Topics

### Parallel Processing

Control concurrent job execution:

```yaml
slurm:
  array_throttle: 10  # Process up to 10 subjects simultaneously
```

### Output Spaces

Configure target output spaces:

```yaml
fmriprep:
  output_spaces: 'MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5'
```

### Manual FreeSurfer Editing Workflow

For subjects requiring manual editing:

1. Run step 6 (anatomical only): `./06-run.sbatch`
2. Download FreeSurfer outputs for manual editing
3. Perform manual edits (e.g., skull strip correction, white matter surface)
4. Re-upload edited FreeSurfer directory to `derivatives/freesurfer/`
5. Run step 7 (full workflows): `./07-run.sbatch`

### Skipping Steps

If you do not need manual FreeSurfer editing:

- Skip step 6 entirely
- Run step 7 directly after QC steps (4-5): `./07-run.sbatch`

## Best Practices

1. **Validate Each Step**

   Review outputs after each workflow before proceeding to the next

2. **Monitor Resource Usage**

   Adjust SLURM parameters based on actual usage (check with `sacct`)

3. **Document Deviations**

   Keep track of any manual interventions or parameter changes

4. **Regular Backups**

   Backup critical intermediate outputs (e.g., FreeSurfer directories)

5. **Version Control**

   Track fMRIPrep version and parameter changes for reproducibility

6. **Review QC Reports**

   Always review fMRIPrep HTML reports after step 7 completes

## Next Steps

- Return to [Usage](usage.md) for execution instructions
- See [Configuration](configuration.md) for parameter details
- Review [Changelog](changelog.md) for updates and improvements
