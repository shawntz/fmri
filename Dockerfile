# ============================================================================
# fMRIPrep Workbench Docker Container
# ============================================================================
# This container provides the fMRIPrep Workbench pipeline orchestration tools
# for fMRI preprocessing and statistical analysis workflows.
#
# The container includes:
# - Python 3.11 with PyYAML for configuration management
# - FSL for neuroimaging analysis (FEAT GLM, fslnvols)
# - Git for version control
# - Interactive TUI launcher
# - All pipeline scripts and utilities
#
# Note: This container orchestrates pipelines that use other containers
# (fMRIPrep, heudiconv) via Singularity/Apptainer on HPC systems.
# ============================================================================

FROM ubuntu:22.04 as base

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Set locale
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    python3.11 \
    python3-pip \
    python3.11-venv \
    rsync \
    tar \
    gzip \
    bash \
    bc \
    vim \
    nano \
    less \
    && rm -rf /var/lib/apt/lists/*

# Install FSL (minimal installation for FEAT and utilities)
RUN wget -O- http://neuro.debian.net/lists/jammy.us-ca.full | \
    tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com 0xA5D32F012649A5A9 && \
    apt-get update && \
    apt-get install -y fsl-core fsl-atlases && \
    rm -rf /var/lib/apt/lists/*

# Configure FSL environment
ENV FSLDIR=/usr/share/fsl/5.0 \
    FSLOUTPUTTYPE=NIFTI_GZ \
    PATH=/usr/share/fsl/5.0/bin:$PATH \
    LD_LIBRARY_PATH=/usr/share/fsl/5.0/lib:$LD_LIBRARY_PATH

# Install Python packages
RUN pip3 install --no-cache-dir \
    pyyaml>=6.0 \
    numpy \
    pandas \
    matplotlib

# Create workbench user (non-root for security)
RUN useradd -m -s /bin/bash -u 1000 workbench && \
    mkdir -p /opt/fmriprep-workbench && \
    chown -R workbench:workbench /opt/fmriprep-workbench

# Set working directory
WORKDIR /opt/fmriprep-workbench

# Copy pipeline files
COPY --chown=workbench:workbench . /opt/fmriprep-workbench/

# Make scripts executable
RUN find /opt/fmriprep-workbench -type f -name "*.sh" -exec chmod +x {} \; && \
    find /opt/fmriprep-workbench -type f -name "*.sbatch" -exec chmod +x {} \; && \
    chmod +x /opt/fmriprep-workbench/launch && \
    chmod +x /opt/fmriprep-workbench/toolbox/*.py 2>/dev/null || true

# Create mount point directories
RUN mkdir -p \
    /data/config \
    /data/subjects \
    /data/logs \
    /data/study \
    /data/cache/templateflow \
    /data/cache/fmriprep \
    /data/containers \
    && chown -R workbench:workbench /data

# Switch to workbench user
USER workbench

# Set environment variables for container
ENV WORKBENCH_VERSION=0.2.0 \
    WORKBENCH_HOME=/opt/fmriprep-workbench \
    PATH=/opt/fmriprep-workbench:$PATH

# Default command
CMD ["/bin/bash"]

# Metadata labels
LABEL maintainer="Shawn Schwartz <shawnschwartz@stanford.edu>" \
      org.opencontainers.image.title="fMRIPrep Workbench" \
      org.opencontainers.image.description="Pipeline orchestration toolbox for fMRI preprocessing and statistical analysis" \
      org.opencontainers.image.version="0.2.0" \
      org.opencontainers.image.url="https://github.com/shawntz/fmriprep-workbench" \
      org.opencontainers.image.documentation="https://fmriprep-workbench.readthedocs.io" \
      org.opencontainers.image.source="https://github.com/shawntz/fmriprep-workbench" \
      org.opencontainers.image.licenses="MIT"
