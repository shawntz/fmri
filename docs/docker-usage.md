# Docker Usage Guide

This guide provides detailed instructions for using fMRIPrep Workbench via Docker containers.

## Quick Start

```bash
# Pull the image
docker pull shawnschwartz/fmriprep-workbench:latest

# Start the container
./fmriprep-workbench start

# Launch the TUI
./fmriprep-workbench launch
```

## Container Management

### Starting the Container

The wrapper script automatically configures mount points and environment variables:

```bash
./fmriprep-workbench start
```

This mounts:
- Current directory → `/opt/fmriprep-workbench/workspace`
- `config.yaml` → `/data/config/config.yaml`
- `all-subjects.txt` → `/data/subjects/all-subjects.txt`
- `logs/` → `/data/logs`
- `~/.cache/templateflow` → `/data/cache/templateflow`
- `~/.cache/fmriprep` → `/data/cache/fmriprep`

### Stopping the Container

```bash
./fmriprep-workbench stop
```

### Checking Status

```bash
./fmriprep-workbench status
```

### Viewing Logs

```bash
./fmriprep-workbench logs
```

## Running Pipeline Steps

### Interactive TUI (Recommended)

```bash
./fmriprep-workbench launch
```

This opens the interactive terminal user interface where you can:
- Select pipeline steps
- Configure parameters
- Submit jobs to SLURM (if available)

### Manual Command Execution

Execute individual pipeline steps:

```bash
# Step 1: FlyWheel download
./fmriprep-workbench exec ./01-run.sbatch <args>

# Step 2: DICOM conversion
./fmriprep-workbench exec ./02-run.sbatch <args>

# Step 3: Prep for fMRIPrep
./fmriprep-workbench exec ./03-run.sbatch

# And so on...
```

### Opening a Shell

For direct interaction with the container:

```bash
./fmriprep-workbench shell
```

Once inside, you can run any command:

```bash
# Inside the container
cd /opt/fmriprep-workbench/workspace
./launch
ls -la
source load_config.sh
```

## Docker Compose Usage

### Starting Services

```bash
docker-compose up -d
```

### Viewing Logs

```bash
docker-compose logs -f
```

### Stopping Services

```bash
docker-compose down
```

### Custom Configuration

Create a `docker-compose.override.yml` file for custom settings:

```yaml
version: '3.8'

services:
  fmriprep-workbench:
    volumes:
      # Add custom mounts
      - /path/to/your/data:/data/study:rw

    environment:
      # Add custom environment variables
      - CUSTOM_VAR=value

    deploy:
      resources:
        limits:
          cpus: '16'
          memory: 32G
```

## Singularity Usage (HPC Clusters)

### Basic Usage

```bash
# Interactive shell
singularity shell \
  --bind $(pwd):/workspace \
  --bind $HOME/.cache/templateflow:/cache/templateflow \
  --bind $HOME/.cache/fmriprep:/cache/fmriprep \
  fmriprep-workbench_v0.2.0.sif

# Execute command
singularity exec \
  --bind $(pwd):/workspace \
  fmriprep-workbench_v0.2.0.sif \
  /opt/fmriprep-workbench/launch
```

### SLURM Integration

Submit pipeline steps as SLURM jobs:

```bash
#!/bin/bash
#SBATCH --job-name=fmriprep-workbench
#SBATCH --time=24:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8

# Load Singularity module
module load singularity

# Set up bind mounts
export WORKDIR=$(pwd)
export SINGULARITY_BIND="${WORKDIR}:/workspace,${HOME}/.cache/templateflow:/cache/templateflow"

# Execute pipeline step
singularity exec \
  fmriprep-workbench_v0.2.0.sif \
  /opt/fmriprep-workbench/01-run.sbatch <args>
```

### Environment Variables

Pass environment variables to Singularity:

```bash
singularity exec \
  --env CUSTOM_VAR=value \
  --bind $(pwd):/workspace \
  fmriprep-workbench_v0.2.0.sif \
  /opt/fmriprep-workbench/launch
```

## Advanced Docker Usage

### Running Without Wrapper Script

Manual Docker run command:

```bash
docker run -it --rm \
  --name fmriprep-workbench \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd):/opt/fmriprep-workbench/workspace:rw" \
  -v "$(pwd)/config.yaml:/data/config/config.yaml:ro" \
  -v "$(pwd)/all-subjects.txt:/data/subjects/all-subjects.txt:ro" \
  -v "$(pwd)/logs:/data/logs:rw" \
  -v "${HOME}/.cache/templateflow:/data/cache/templateflow:rw" \
  -v "${HOME}/.cache/fmriprep:/data/cache/fmriprep:rw" \
  shawnschwartz/fmriprep-workbench:latest \
  /bin/bash
```

### GPU Support

If you need GPU access (for future GPU-accelerated processing):

```bash
docker run -it --rm \
  --gpus all \
  --name fmriprep-workbench \
  -v "$(pwd):/opt/fmriprep-workbench/workspace:rw" \
  shawnschwartz/fmriprep-workbench:latest \
  /bin/bash
```

### Custom Network

Run with custom Docker network:

```bash
# Create network
docker network create fmriprep-network

# Run container on network
docker run -it --rm \
  --name fmriprep-workbench \
  --network fmriprep-network \
  -v "$(pwd):/opt/fmriprep-workbench/workspace:rw" \
  shawnschwartz/fmriprep-workbench:latest \
  /bin/bash
```

## Troubleshooting

### Permission Issues

If you encounter permission errors:

```bash
# Check file ownership
ls -la

# Ensure container runs as your user
docker run --user "$(id -u):$(id -g)" ...
```

### Mount Point Errors

Verify mount points are correct:

```bash
# Inside container
ls -la /opt/fmriprep-workbench/workspace
ls -la /data/config
ls -la /data/subjects
```

### Container Won't Start

Check Docker logs:

```bash
docker logs fmriprep-workbench
```

Verify Docker is running:

```bash
docker ps
docker info
```

### Singularity Bind Errors

Ensure paths exist before binding:

```bash
mkdir -p $HOME/.cache/templateflow
mkdir -p $HOME/.cache/fmriprep
mkdir -p logs
```

### Image Pull Failures

If image pull fails:

```bash
# Try with explicit registry
docker pull docker.io/shawnschwartz/fmriprep-workbench:latest

# Check Docker Hub status
curl -s https://status.docker.com/api/v2/status.json
```

## Best Practices

### Data Management

1. **Keep data outside the container**: Always use volume mounts for data
2. **Use named volumes for caches**: Persist TemplateFlow and fMRIPrep caches
3. **Regular backups**: Back up configuration files and subject lists

### Performance

1. **Resource limits**: Set appropriate CPU and memory limits in `docker-compose.yml`
2. **Cache directories**: Mount cache directories to avoid re-downloading templates
3. **Parallel processing**: Use SLURM array jobs for parallel subject processing

### Security

1. **Non-root user**: Always run as non-root user (handled automatically by wrapper)
2. **Read-only mounts**: Mount configuration files as read-only (`:ro`)
3. **Network isolation**: Use custom networks when running multiple containers

## Examples

### Example 1: Complete Preprocessing Workflow

```bash
# Start container
./fmriprep-workbench start

# Run preprocessing steps
./fmriprep-workbench exec ./01-run.sbatch <args>  # FlyWheel download
./fmriprep-workbench exec ./02-run.sbatch <args>  # DICOM conversion
./fmriprep-workbench exec ./03-run.sbatch         # Prep for fMRIPrep
./fmriprep-workbench exec ./04-run.sbatch         # QC metadata
./fmriprep-workbench exec ./05-run.sbatch         # QC volumes
./fmriprep-workbench exec ./07-run.sbatch         # fMRIPrep full

# Stop container
./fmriprep-workbench stop
```

### Example 2: FSL FEAT Analysis

```bash
# Start container
./fmriprep-workbench start

# Setup GLM model
./fmriprep-workbench exec ./10-fsl-glm/setup_glm.sh

# Run analyses
./fmriprep-workbench exec ./08-run.sbatch my-model  # Level 1
./fmriprep-workbench exec ./09-run.sbatch my-model  # Level 2
./fmriprep-workbench exec ./10-run.sbatch my-model  # Level 3

# Stop container
./fmriprep-workbench stop
```

### Example 3: Interactive Development

```bash
# Open shell
./fmriprep-workbench shell

# Inside container - test configurations
cd /opt/fmriprep-workbench/workspace
source load_config.sh
echo "Testing configuration..."

# Make changes, test, repeat
exit
```

## See Also

- [Installation Guide](installation.md)
- [Configuration Guide](configuration.md)
- [Usage Guide](usage.md)
- [Workflows Guide](workflows.md)
