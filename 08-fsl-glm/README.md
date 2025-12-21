# FSL GLM Statistical Analysis

This directory contains tools for creating and executing neuroimaging statistical analysis using FSL FEAT. The pipeline creates `*.fsf` files for level 1 (individual runs), level 2 (subject), and level 3 (group) analysis of fMRI data.

## Overview

The FSL GLM analysis pipeline assumes that:
- You have completed fMRIPrep preprocessing (steps 1-7)
- You are familiar with FSL and GLM analysis
- You have your experimental design and timing information ready

## Analysis Levels

### Level 1: Individual Runs
First-level analysis examines each individual run separately. Creates statistical maps for each task run for each subject.

### Level 2: Subject-Level
Second-level analysis combines multiple runs from the same subject. Creates subject-level statistical maps.

### Level 3: Group-Level
Third-level analysis performs group statistics across all subjects. Creates group-level statistical maps.

## Quick Start

### 1. Setup a New GLM Model

Use the interactive launcher:
```bash
./launch
# Select option 8: FSL GLM: Setup new statistical model
```

Or run directly:
```bash
./08-fsl-glm/setup_glm.sh
```

This will create the model directory structure and template configuration files in:
```
BASE_DIR/model/level1/model-<your-model-name>/
```

### 2. Configure Your Model

After setup, you need to configure three key files:

#### a. `model_params.json`
Contains model parameters like smoothing, high-pass filtering, confound modeling, etc.

Example:
```json
{
  "smoothing": 5.0,
  "use_inplane": false,
  "nohpf": false,
  "nowhite": false,
  "noconfound": false,
  "doreg": true,
  "usebrainmask": true,
  "specificruns": {}
}
```

#### b. `condition_key.json`
Maps EV numbers to condition names for each task.

Example:
```json
{
  "flanker": {
    "1": "congruent_correct",
    "2": "congruent_incorrect",
    "3": "incongruent_correct",
    "4": "incongruent_incorrect"
  }
}
```

#### c. `task_contrasts.json` (optional)
Defines contrasts between conditions.

Example:
```json
{
  "flanker": {
    "incongruent_vs_congruent": [-1, -1, 1, 1],
    "incorrect_vs_correct": [-1, 1, -1, 1],
    "incongruent_vs_congruent_correct": [-1, 0, 1, 0]
  }
}
```

### 3. Create EV Files

Place your experimental timing files in the onset directories:

**If you have sessions:**
```
BASE_DIR/model/level1/model-<modelname>/sub-<subid>/ses-<sesname>/task-<taskname>_run-<runname>/onsets/
```

**If no sessions:**
```
BASE_DIR/model/level1/model-<modelname>/sub-<subid>/task-<taskname>_run-<runname>/onsets/
```

**EV file naming convention:**
- With sessions: `sub-<subid>_ses-<sesname>_task-<taskname>_run-<runname>_ev-00<N>`
- Without sessions: `sub-<subid>_task-<taskname>_run-<runname>_ev-00<N>`

where `N` is the EV number (e.g., 001, 002, 003).

**EV file format:**
- Can be `.txt` or `.tsv` files
- Three columns (tab-separated): onset time, duration, weight
- Example:
  ```
  0.0    2.5    1
  5.0    2.5    1
  10.0   2.5    1
  ```

### 4. Run Level 1 Analysis

Using the interactive launcher:
```bash
./launch
# Select option 9: FSL GLM: Run Level 1 analysis
# Enter your model name
# Choose whether to only create FSF files (no-feat mode)
```

Or run directly:
```bash
./08-run.sbatch <model-name>

# To only create FSF files without running FEAT:
./08-run.sbatch <model-name> --no-feat
```

This will:
- Generate `.fsf` files for each run
- Submit SLURM job array to run FEAT
- Or run serially/in parallel using joblib if SLURM is unavailable

### 5. Run Level 2 Analysis

After Level 1 completes:
```bash
./launch
# Select option 10: FSL GLM: Run Level 2 analysis

# Or run directly:
./09-run.sbatch <model-name>
```

### 6. Run Level 3 Analysis

After Level 2 completes:
```bash
./launch
# Select option 11: FSL GLM: Run Level 3 analysis

# Or run directly:
./10-run.sbatch <model-name>
```

## Confound Modeling

If you want to include motion confounds or other nuisance regressors:

1. During setup, when asked about confounds, choose to include them
2. The setup script will generate `confounds.json` with all available confounds from fMRIPrep
3. Edit `confounds.json` to select which confounds to include:

```json
{
  "confounds": [
    "X",
    "Y",
    "Z",
    "RotX",
    "RotY",
    "RotZ"
  ]
}
```

4. Confound files will be automatically generated when you run Level 1 analysis

## Advanced Options

### Custom FSF Settings

Create a custom stub file to override default FEAT settings:
```bash
# Create custom stub in model directory
nano BASE_DIR/model/level1/model-<modelname>/design_level1_custom.stub
```

Any settings in the custom stub will override the defaults from `design_level1_fsl5.stub`.

### Specific Runs Only

To run analysis on only specific subjects/runs, modify the `specificruns` field in `model_params.json`:

**With sessions:**
```json
{
  "specificruns": {
    "sub-01": {
      "ses-01": {
        "flanker": ["1", "2"]
      }
    },
    "sub-02": {
      "ses-01": {
        "flanker": ["1", "2"]
      }
    }
  }
}
```

**Without sessions:**
```json
{
  "specificruns": {
    "sub-01": {
      "flanker": ["1"]
    },
    "sub-02": {
      "flanker": ["1", "2"]
    }
  }
}
```

## Directory Structure

```
BASE_DIR/
├── bids/                          # fMRIPrep output
├── model/
│   ├── level1/
│   │   └── model-<modelname>/
│   │       ├── model_params.json
│   │       ├── condition_key.json
│   │       ├── task_contrasts.json (optional)
│   │       ├── confounds.json (optional)
│   │       ├── design_level1_custom.stub (optional)
│   │       └── sub-<subid>/
│   │           └── ses-<sesname>/      # If sessions exist
│   │               └── task-<taskname>_run-<runname>/
│   │                   ├── onsets/
│   │                   │   ├── sub-<subid>_ses-<sesname>_task-<taskname>_run-<runname>_ev-001
│   │                   │   └── sub-<subid>_ses-<sesname>_task-<taskname>_run-<runname>_ev-confounds
│   │                   └── <runname>.feat/  # Created by FEAT
│   ├── level2/
│   │   └── model-<modelname>/
│   │       └── sub-<subid>/
│   │           └── <task>.gfeat/  # Created by Level 2
│   └── level3/
│       └── model-<modelname>/
│           └── <task>_<contrast>.gfeat/  # Created by Level 3
```

## Monitoring Jobs

Check SLURM job status:
```bash
squeue -u $USER
```

Check logs:
```bash
# Main logs
ls logs/slurm/fsl-glm/

# Job array output
ls logs/slurm/08-fsl-glm/
```

## Troubleshooting

### FEAT fails with "No FEAT directories found"
- Ensure Level 1 completed successfully before running Level 2
- Check that `.feat` directories exist in the expected locations

### Missing EV files
- Verify EV files are named correctly
- Check that file paths match the directory structure
- The pipeline will skip missing EV files automatically (FSL will fail if all EVs are zero)

### "Conflicting study identifiers" error
- If you manually merged scans from multiple sessions
- The setup created the structure for the `all` grouping strategy
- This should be handled automatically

### SLURM jobs not submitting
- If SLURM is unavailable, the pipeline will automatically fall back to joblib parallel processing
- Or run serially if joblib is not available

## Technical Details

### Files in This Directory

- `setup.py` - Creates model directory structure and configuration files
- `run_level1.py` - Generates and executes Level 1 FEAT jobs
- `run_level2.py` - Generates and executes Level 2 FEAT jobs
- `run_level3.py` - Generates and executes Level 3 FEAT jobs
- `mk_level1_fsf_bbr.py` - Creates Level 1 FSF files
- `mk_level2_fsf.py` - Creates Level 2 FSF files
- `mk_level3_fsf.py` - Creates Level 3 FSF files
- `run_feat_job.py` - Job runner for SLURM array tasks
- `get_level1_jobs.py` - Identifies Level 1 jobs to run
- `get_level2_jobs.py` - Identifies Level 2 jobs to run
- `directory_struct_utils.py` - Utility functions for directory structure
- `setup_utils.py` - Utility functions for model setup
- `nifti_utils.py` - Utility functions for reading NIfTI headers
- `design_level1_fsl5.stub` - Template for Level 1 FSF files
- `design_level2.stub` - Template for Level 2 FSF files
- `design_level3.stub` - Template for Level 3 FSF files

### Integration with fmriprep-workbench

The FSL GLM pipeline is fully integrated with the fmriprep-workbench architecture:
- Uses the same `load_config.sh` configuration system
- Follows the same SLURM job submission patterns
- Logs to the same directory structure
- Accessible through the interactive `./launch` menu

## Credits

The core FSL GLM analysis scripts were adapted from the [fmri-pipeline](https://github.com/alicexue/fmri-pipeline) repository by Alice Xue (Stanford Memory Lab) and integrated into fmriprep-workbench by Shawn Schwartz (Stanford Memory Lab).

## Additional Resources

- [FSL FEAT Documentation](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FEAT)
- [FSL FEAT User Guide](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FEAT/UserGuide)
- [BIDS fMRI Derivatives](https://bids-specification.readthedocs.io/en/stable/05-derivatives/04-functional-imaging-derivatives.html)
