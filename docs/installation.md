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

## Docker Installation (Recommended)

The easiest way to use fMRIPrep Workbench is via the pre-built Docker container. This eliminates dependency management and ensures consistent environments.

### Prerequisites

- Docker Engine 20.10+ (for local workstations)
- OR Singularity/Apptainer 3.0+ (for HPC clusters)

### Option 1: Using Docker (Local Workstations)

#### 1. Install Docker

Follow the official Docker installation guide for your platform:
- [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- [Docker Engine for Linux](https://docs.docker.com/engine/install/)

#### 2. Pull the Image

```bash
docker pull shawnschwartz/fmriprep-workbench:latest
```

#### 3. Download the Wrapper Script

```bash
# Clone the repository (or download just the wrapper script)
git clone https://github.com/shawntz/fmriprep-workbench.git
cd fmriprep-workbench

# Make the wrapper script executable
chmod +x fmriprep-workbench
```

#### 4. Start the Container

```bash
./fmriprep-workbench start
```

#### 5. Launch the TUI

```bash
./fmriprep-workbench launch
```

### Option 2: Using Singularity (HPC Clusters)

Singularity/Apptainer is designed for HPC environments and provides better integration with job schedulers like SLURM.

#### 1. Download Pre-built Singularity Image

Download the `.sif` file from the latest release:

```bash
# Replace vX.Y.Z with the actual version
wget https://github.com/shawntz/fmriprep-workbench/releases/download/vX.Y.Z/fmriprep-workbench_vX.Y.Z.sif
```

#### 2. Or Convert from Docker Hub

If a pre-built Singularity image isn't available:

```bash
# Using Singularity 3.x
singularity build fmriprep-workbench_vX.Y.Z.sif docker://shawnschwartz/fmriprep-workbench:latest

# Using Apptainer (newer Singularity)
apptainer build fmriprep-workbench_vX.Y.Z.sif docker://shawnschwartz/fmriprep-workbench:latest
```

#### 3. Run the Container

```bash
# Interactive shell
singularity shell \
  --bind $(pwd):/workspace \
  --bind $HOME/.cache/templateflow:/cache/templateflow \
  --bind $HOME/.cache/fmriprep:/cache/fmriprep \
  fmriprep-workbench_vX.Y.Z.sif

# Execute a specific command
singularity exec \
  --bind $(pwd):/workspace \
  fmriprep-workbench_vX.Y.Z.sif \
  /opt/fmriprep-workbench/launch

# Submit as SLURM job
sbatch --wrap="singularity exec --bind $(pwd):/workspace fmriprep-workbench_vX.Y.Z.sif /opt/fmriprep-workbench/01-run.sbatch"
```

### Option 3: Using Docker Compose

For more complex setups with multiple services:

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Container Mount Points

The container exposes the following mount points:

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./` (current directory) | `/opt/fmriprep-workbench/workspace` | Working directory |
| `./config.yaml` | `/data/config/config.yaml` | Configuration file |
| `./all-subjects.txt` | `/data/subjects/all-subjects.txt` | Subject list |
| `./logs/` | `/data/logs` | Log files |
| `~/.cache/templateflow` | `/data/cache/templateflow` | TemplateFlow cache |
| `~/.cache/fmriprep` | `/data/cache/fmriprep` | fMRIPrep cache |

### Wrapper Script Commands

The `fmriprep-workbench` wrapper script provides convenient commands:

```bash
./fmriprep-workbench start     # Start container in background
./fmriprep-workbench stop      # Stop the container
./fmriprep-workbench launch    # Launch the TUI
./fmriprep-workbench shell     # Open bash shell
./fmriprep-workbench logs      # View container logs
./fmriprep-workbench status    # Check container status
./fmriprep-workbench exec <cmd># Execute command in container
./fmriprep-workbench pull      # Pull latest image
./fmriprep-workbench build     # Build image locally
./fmriprep-workbench help      # Show help
```

### Building Locally

To build the Docker image from source:

```bash
# Clone the repository
git clone https://github.com/shawntz/fmriprep-workbench.git
cd fmriprep-workbench

# Build the image
docker build -t shawnschwartz/fmriprep-workbench:latest .

# Or use the wrapper script
./fmriprep-workbench build
```

## Next Steps

After installation, proceed to the [Configuration](configuration.md) guide to set up
your preprocessing pipeline parameters in detail.

For Docker-specific usage instructions, see [Docker Usage Guide](docker-usage.md).
