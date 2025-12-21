# Usage

The fMRIPrep Workbench provides two methods for running pipeline steps:
an interactive TUI launcher and manual execution of sbatch scripts.

## Interactive TUI Launcher

The graphical launcher provides an interactive interface with context and parameter setting:

```bash
./launch
```

**Features:**

- Welcome screen with pipeline overview
- Workflow selector with step descriptions
- Interactive parameter setting for each step
- User-friendly for those less familiar with command line

**Example Workflow:**

1. Launch the TUI: `./launch`
2. Select a preprocessing step from the menu
3. Configure parameters (if needed)
4. Submit the job to SLURM

## Manual Execution

For more control, you can manually execute each sbatch script:

### Basic Usage

```bash
# Step 1: FlyWheel to Server transfer
./01-run.sbatch

# Step 2: dcm2niix conversion
./02-run.sbatch

# Step 3: Prep for fMRIPrep (dummy scan removal, fieldmap setup)
./03-run.sbatch

# Step 4: QC metadata verification
./04-run.sbatch

# Step 5: QC volume verification
./05-run.sbatch

# Step 6: fMRIPrep anatomical workflows only (optional)
./06-run.sbatch

# Step 7: Download FreeSurfer outputs (optional)
./toolbox/download_freesurfer.sh

# Step 8: Upload edited FreeSurfer outputs (optional)
./toolbox/upload_freesurfer.sh

# Step 9: fMRIPrep complete workflows
./07-run.sbatch

# Step 10: FSL GLM model setup
./08-fsl-glm/setup_glm.sh

# Step 11: FSL Level 1 analysis
./08-run.sbatch <model-name>

# Step 12: FSL Level 2 analysis
./09-run.sbatch <model-name>

# Step 13: FSL Level 3 analysis
./10-run.sbatch <model-name>

# Step 14: Tarball utility
./toolbox/tarball_sourcedata.sh
```

## Pipeline Steps

The preprocessing and analysis pipeline consists of 14 steps:

**Step 1: FlyWheel Transfer** (`01-run.sbatch`)
:   Automated transfer of scanner acquisitions from FlyWheel to server

**Step 2: DICOM Conversion** (`02-run.sbatch`)
:   Convert DICOM files to NIfTI format using heudiconv/dcm2niix

**Step 3: Prep for fMRIPrep** (`03-run.sbatch`)
:   - Remove dummy scans
    - Set up fieldmap-based distortion correction
    - Validate data structure

**Step 4: QC Metadata** (`04-run.sbatch`)
:   Verify DICOM to NIfTI to BIDS metadata conversion

**Step 5: QC Volumes** (`05-run.sbatch`)
:   Verify scan volume counts match expected values

**Step 6: fMRIPrep Anatomical** (`06-run.sbatch`)
:   Run fMRIPrep anatomical workflows only (optional, for manual FreeSurfer editing)

**Step 7: Download FreeSurfer** (`toolbox/download_freesurfer.sh`)
:   Download FreeSurfer outputs for manual surface editing (optional)

**Step 8: Upload FreeSurfer** (`toolbox/upload_freesurfer.sh`)
:   Upload edited FreeSurfer outputs back to server with automatic backup (optional)

**Step 9: fMRIPrep Complete** (`07-run.sbatch`)
:   Run full fMRIPrep workflows (anatomical + functional)

**Step 10: FSL GLM Setup** (`08-fsl-glm/setup_glm.sh`)
:   Setup new statistical model for FSL FEAT analysis

**Step 11: FSL Level 1** (`08-run.sbatch`)
:   Run Level 1 GLM analysis (individual task runs)

**Step 12: FSL Level 2** (`09-run.sbatch`)
:   Run Level 2 GLM analysis (subject-level, combining runs)

**Step 13: FSL Level 3** (`10-run.sbatch`)
:   Run Level 3 GLM analysis (group-level statistics)

**Step 14: Tarball Utility** (`toolbox/tarball_sourcedata.sh`)
:   Optimize inode usage by archiving sourcedata directories

!!! note "v0.2.0+ Changes"

    The pipeline has been expanded to 14 steps, including dedicated FreeSurfer editing utilities (steps 7-8), FSL FEAT statistical analysis (steps 10-13), and data management tools (step 14).

## Typical Workflow

### Standard Processing (No Manual FreeSurfer Editing or Statistical Analysis)

```bash
# Steps 1-5: Data acquisition and QC
./01-run.sbatch  # FlyWheel download
./02-run.sbatch  # DICOM conversion
./03-run.sbatch  # Prep for fMRIPrep
./04-run.sbatch  # QC metadata
./05-run.sbatch  # QC volumes

# Step 9: Skip step 6, run full fMRIPrep directly (steps 7-8 are for FreeSurfer editing)
./07-run.sbatch  # Full fMRIPrep workflows
```

### Processing with Manual FreeSurfer Editing

```bash
# Steps 1-5: Data acquisition and QC
./01-run.sbatch
./02-run.sbatch
./03-run.sbatch
./04-run.sbatch
./05-run.sbatch

# Step 6: Run anatomical-only fMRIPrep
./06-run.sbatch

# Step 7: Download FreeSurfer outputs
./toolbox/download_freesurfer.sh --server <server> --user <user> --remote-dir <dir> --subjects <list>

# (Manual editing with Freeview)

# Step 8: Upload edited surfaces
./toolbox/upload_freesurfer.sh --server <server> --user <user> --remote-dir <dir> --subjects <list>

# Step 9: Run full fMRIPrep with edited surfaces
./07-run.sbatch
```

### Complete Workflow with FSL FEAT Analysis

```bash
# Steps 1-9: Preprocessing (as above)
./01-run.sbatch  # through ./07-run.sbatch

# Step 10: Setup FSL GLM model
./08-fsl-glm/setup_glm.sh
# (Configure model_params.json, condition_key.json, task_contrasts.json)
# (Create EV timing files)

# Step 11: Run Level 1 analysis
./08-run.sbatch <model-name>

# Step 12: Run Level 2 analysis
./09-run.sbatch <model-name>

# Step 13: Run Level 3 analysis
./10-run.sbatch <model-name>
```

## SLURM Job Naming

!!! note "v0.2.0 Change"

    All SLURM jobs now use the unified naming pattern `fmriprep-workbench-{N}` where N is the step number.

| Step | Job Name | Directory (STEP_NAME) | Notes |
|------|----------|----------------------|-------|
| 1    | `fmriprep-workbench-1` | `01-fw2server` | FlyWheel download |
| 2    | `fmriprep-workbench-2` | `02-dcm2niix` | DICOM conversion |
| 3    | `fmriprep-workbench-3` | `03-prep-fmriprep` | Prep for fMRIPrep |
| 4    | `fmriprep-workbench-4` | `04-qc-metadata` | QC metadata |
| 5    | `fmriprep-workbench-5` | `05-qc-volumes` | QC volumes |
| 6    | `fmriprep-workbench-6` | `06-run-fmriprep` | fMRIPrep anat-only |
| 7    | N/A | `toolbox/` | FreeSurfer download (no SLURM) |
| 8    | N/A | `toolbox/` | FreeSurfer upload (no SLURM) |
| 9    | `fmriprep-workbench-9` | `07-run-fmriprep` | fMRIPrep full |
| 10   | N/A | `08-fsl-glm/` | FSL GLM setup (no SLURM) |
| 11   | `fmriprep-workbench-11` | `08-fsl-glm/` | FSL Level 1 |
| 12   | `fmriprep-workbench-12` | `08-fsl-glm/` | FSL Level 2 |
| 13   | `fmriprep-workbench-13` | `08-fsl-glm/` | FSL Level 3 |
| 14   | N/A | `toolbox/` | Tarball utility (no SLURM) |

The `JOB_NAME` is used for SLURM display (visible in `squeue`), while
`STEP_NAME` is used for log directory organization. Steps 7, 8, 10, and 14 are
utility scripts that run directly without SLURM job submission.

## Monitoring Jobs

### Check SLURM Job Status

```bash
# View all your jobs
squeue -u $USER

# View jobs by name pattern
squeue -u $USER -n fmriprep-workbench-3

# View specific job details
scontrol show job <job_id>

# View job array status
sacct -j <job_id>
```

### Check Logs

Log files are organized by step name in the configured log directory:

```bash
# SLURM logs (organized by step)
ls ${SLURM_LOG_DIR}/03-prep-fmriprep/
ls ${SLURM_LOG_DIR}/04-qc-metadata/
ls ${SLURM_LOG_DIR}/06-run-fmriprep/

# View a specific log file
# Format: <job_name>_<array_job_id>_<task_id>.out
less ${SLURM_LOG_DIR}/03-prep-fmriprep/fmriprep-workbench-3_12345_0.out

# Workflow logs
ls ${WORKFLOW_LOG_DIR}/
```

## Subject List Handling

!!! note "v0.2.0 Enhancement"

    Comment lines (starting with `#`) and blank lines are now automatically filtered when counting subjects for SLURM array jobs.

### Example Subject List

```text
# all-subjects.txt
# This is a study of memory encoding
# Subjects recruited 2024-2025

# Batch 1 - completed preprocessing
101
102
103

# Batch 2 - in progress
104
105:force    # Needs reprocessing due to motion
106:skip     # Excluded - excessive motion

# Batch 3 - pending
107
108
```

### Subject Modifiers

Use modifiers for fine-grained control:

```text
101                # Standard subject, runs all steps
102:step4          # Only run step 4 for this subject
103:step4:step5    # Only run steps 4 and 5
104:force          # Force rerun all steps
105:step5:force    # Only run step 5, force rerun
106:skip           # Skip this subject
```

## Quality Control

After preprocessing, review the outputs:

**Check fMRIPrep Reports**

```bash
# Open HTML reports in browser
firefox ${DERIVS_DIR}/sub-<subject_id>.html
```

**Validate BIDS Structure**

```bash
# Use BIDS validator (if installed)
bids-validator ${TRIM_DIR}
```

**Inspect Preprocessed Data**

```bash
# Check output structure
tree ${DERIVS_DIR}/sub-<subject_id>/

# View metadata
cat ${DERIVS_DIR}/sub-<subject_id>/func/*.json
```

## Troubleshooting

### Failed Jobs

If a job fails, check the logs:

1. Review SLURM output: `${SLURM_LOG_DIR}/<step-name>/*.out`
2. Check error logs: `${SLURM_LOG_DIR}/<step-name>/*.err`
3. Examine workflow logs: `${WORKFLOW_LOG_DIR}/`

Common solutions:

- Verify paths in `config.yaml`
- Check file permissions
- Ensure sufficient disk space
- Validate BIDS structure

### Rerunning Subjects

To rerun a subject, use the `force` modifier:

```text
# In your subject list file
101:force
```

Or manually remove the completion marker before rerunning.

### Debug Mode

Enable debug mode in `config.yaml`:

```yaml
misc:
  debug: 1
```

This runs the pipeline with only a single subject (array index 0) for testing.

### Configuration Validation

Test that your configuration loads correctly:

```bash
source ./load_config.sh

# Check key variables
echo "BASE_DIR: ${BASE_DIR}"
echo "TRIM_DIR: ${TRIM_DIR}"
echo "DERIVS_DIR: ${DERIVS_DIR}"
```

## Best Practices

1. **Test on a Single Subject**

   Always test your configuration on one subject before processing the entire dataset.
   Use debug mode or create a test subject list.

2. **Monitor Resource Usage**

   Use `sstat` and `sacct` to monitor job resource usage and adjust settings if needed.

3. **Regular Backups**

   Maintain backups of raw data and important intermediate outputs.

4. **Document Changes**

   Keep notes on any parameter changes or manual interventions.

5. **Review QC Reports**

   Always review fMRIPrep HTML reports for quality control.

6. **Use Comments in Subject Lists**

   Document your subject lists with comments to track processing status and notes.

## Next Steps

- See [Workflows](workflows.md) for detailed pipeline documentation
- Check [Contributing](contributing.md) to contribute improvements
- Review [Changelog](changelog.md) for version history
