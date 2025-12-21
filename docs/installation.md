# Installation

## Prerequisites

Before using the fMRIPrep Workbench, ensure you have:

- Access to a computing cluster with SLURM workload manager
- Singularity/Apptainer for container execution
- FreeSurfer license file
- Git for version control
- Python 3.6 or higher (with PyYAML package)

## Getting Started

### 1. Create Repository from Template

Click the "Use this template" button on the [GitHub repository](https://github.com/shawntz/fmriprep-workbench)
to create your own copy.

### 2. Clone Your Repository

```bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
```

### 3. Configure Settings

Copy the configuration template and customize for your study:

```bash
cp config.template.yaml config.yaml
```

Edit `config.yaml` with your study-specific parameters. Key sections to configure:

```yaml
directories:
  base_dir: '/path/to/your/study'
  scripts_dir: '/path/to/your/study/code'
  raw_dir: '/path/to/your/study/sourcedata'
  trim_dir: '/path/to/your/study'
  freesurfer_license: '~/freesurfer.txt'

scan:
  task_id: 'YourTaskName'
  n_dummy: 5
  run_numbers:
    - '01'
    - '02'

validation:
  expected_fmap_vols: 12
  expected_bold_vols: 220

slurm:
  email: 'your.email@institution.edu'
  partition: 'your,partitions'
```

### 4. Set Up Subject List

Create your subject list file:

```bash
cp all-subjects.template.txt all-subjects.txt
```

Add your subject IDs (one per line, just the number without "sub-" prefix):

```text
# Study subjects
101
102
103
```

### 5. Verify Configuration

Test that your configuration loads correctly:

```bash
source ./load_config.sh
```

You should see a message indicating successful configuration loading and
the number of subjects found.

### 6. Verify Paths

Ensure all paths in `config.yaml` are correct and accessible:

- `directories.base_dir` - Your study's root directory
- `directories.raw_dir` - BIDS-formatted raw data location
- `directories.trim_dir` - Destination for processed data
- `directories.freesurfer_license` - Path to FreeSurfer license file
- `pipeline.singularity_image_dir` - Path to Singularity/Apptainer containers

## System Requirements

**Minimum Requirements:**

- 8 CPU cores per subject
- 8GB RAM per subject
- 100GB storage per subject (for preprocessed outputs)

**Recommended:**

- 16 CPU cores per subject
- 32GB RAM per subject
- 200GB storage per subject

**Software Dependencies:**

- SLURM workload manager
- Singularity/Apptainer 3.0+
- FreeSurfer (via container)
- fMRIPrep (via container)
- dcm2niix/heudiconv (via container)
- Python 3.6+ with PyYAML

## Container Setup

The pipeline uses Singularity/Apptainer containers for reproducibility.
Configure container paths in `config.yaml`:

```yaml
pipeline:
  singularity_image_dir: '/path/to/containers'
  singularity_image: 'fmriprep-24.0.1.simg'
  heudiconv_image: 'heudiconv_latest.sif'
```

Ensure the containers exist at the specified paths before running the pipeline.

## Python Dependencies

The configuration loader requires PyYAML. Install it if not available:

```bash
pip install pyyaml
```

Or using conda:

```bash
conda install pyyaml
```

## Migration from v0.1.x

If upgrading from a version that used `settings.sh`:

1. Create the new configuration file:

   ```bash
   cp config.template.yaml config.yaml
   ```

2. Transfer your settings from `settings.sh` to `config.yaml`.
   See the [migration guide](configuration.md#migration-from-settingssh-v01x-to-v020) in the Configuration documentation for
   a detailed mapping of old to new settings.

3. Note the new pipeline step numbering (14 steps total):

   - Steps 1-5: FlyWheel download, DICOM conversion, prep, and QC
   - Step 6: fMRIPrep anatomical-only (optional, for manual FreeSurfer editing)
   - Steps 7-8: FreeSurfer download/upload utilities (optional)
   - Step 9: fMRIPrep full workflows
   - Steps 10-13: FSL FEAT statistical analysis (Level 1, 2, 3 GLM)
   - Step 14: Tarball utility for data management

4. Remove or archive your old `settings.sh` file.

## Next Steps

After installation, proceed to the [Configuration](configuration.md) guide to set up
your preprocessing pipeline parameters in detail.
