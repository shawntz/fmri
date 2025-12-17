Configuration
=============

The preprocessing pipeline requires proper configuration of several parameters
in the ``settings.sh`` file. This guide explains how to configure your pipeline.

Configuration File
------------------

The main configuration file is ``settings.sh``, which is created by copying
``settings.template.sh``:

.. code-block:: bash

   cp settings.template.sh settings.sh

Path Configuration
------------------

Set up your directory structure:

.. code-block:: bash

   BASE_DIR="/my/project/dir"           # Root directory for the study
   SCRIPTS_DIR="${BASE_DIR}/scripts"    # Path of cloned fMRI repo
   RAW_DIR="${BASE_DIR}/bids"           # Raw BIDS-compliant data location
   TRIM_DIR="${BASE_DIR}/bids_trimmed"  # Destination for processed data
   WORKFLOW_LOG_DIR="${BASE_DIR}/logs/workflows"
   TEMPLATEFLOW_HOST_HOME="${HOME}/.cache/templateflow"
   FMRIPREP_HOST_CACHE="${HOME}/.cache/fmriprep"
   FREESURFER_LICENSE="${HOME}/freesurfer.txt"

Task Parameters
---------------

Configure your task-specific settings:

.. code-block:: bash

   task_id="SomeTaskName"   # Original task name in BIDS format
   new_task_id="cleanname"  # New task name (if renaming needed)
   n_dummy=5                # Number of dummy TRs to remove
   run_numbers=("01" "02" "03" "04" "05" "06" "07" "08")

Data Validation
---------------

Set expected volume counts for validation:

.. code-block:: bash

   EXPECTED_FMAP_VOLS=12   # Expected volumes in fieldmap scans
   EXPECTED_BOLD_VOLS=220  # Expected volumes in BOLD scans

Fieldmap Mapping
----------------

Map fieldmaps to BOLD runs:

.. code-block:: bash

   declare -A fmap_mapping=(
       ["01"]="01"  # Task BOLD run 01 uses fmap 01
       ["02"]="01"  # Task BOLD run 02 uses fmap 01
       ["03"]="02"  # Task BOLD run 03 uses fmap 02
       ["04"]="02"  # Task BOLD run 04 uses fmap 02
   )

Subject Lists
-------------

Basic subject list in ``all-subjects.txt``:

.. code-block:: text

   101
   102
   103

Subject ID Modifiers
~~~~~~~~~~~~~~~~~~~~

You can use suffix modifiers for per-subject control:

.. code-block:: text

   101                # Standard subject, runs all steps
   102:step4          # Only run step 4 for this subject
   103:step4:step5    # Only run steps 4 and 5
   104:force          # Force rerun all steps
   105:step5:force    # Only run step 5, force rerun
   106:skip           # Skip this subject

**Available Modifiers:**

- ``step1`` to ``step6`` - Run specific steps only
- ``force`` - Force rerun even if already processed
- ``skip`` - Skip this subject entirely

Slurm Configuration
-------------------

Configure Slurm job parameters:

.. code-block:: bash

   export SLURM_EMAIL="hello@stanford.edu"
   export SLURM_TIME="2:00:00"
   export SLURM_MEM="8G"
   export SLURM_CPUS="8"
   export SLURM_ARRAY_THROTTLE="10"
   export SLURM_PARTITION="hns,normal"

fMRIPrep Settings
-----------------

Configure fMRIPrep-specific parameters:

.. code-block:: bash

   FMRIPREP_VERSION="24.0.1"
   FMRIPREP_OMP_THREADS=8
   FMRIPREP_NTHREADS=12
   FMRIPREP_MEM_MB=30000
   FMRIPREP_FD_SPIKE_THRESHOLD=0.9
   FMRIPREP_DVARS_SPIKE_THRESHOLD=3.0
   FMRIPREP_OUTPUT_SPACES="MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5"

Permissions
-----------

Set file and directory permissions:

.. code-block:: bash

   DIR_PERMISSIONS=775   # Directory level
   FILE_PERMISSIONS=775  # File level

Validation
----------

Before running the pipeline:

1. Verify all paths exist and are accessible
2. Confirm volume counts match your acquisition protocol
3. Test configuration on a single subject
4. Review logs for configuration warnings

Common Issues
-------------

**Path Issues**
   Double-check all path specifications are absolute and accessible

**Volume Mismatches**
   Verify EXPECTED_FMAP_VOLS and EXPECTED_BOLD_VOLS match your protocol

**Fieldmap Mapping**
   Ensure each BOLD run has a corresponding fieldmap entry

**Permission Problems**
   Check that DIR_PERMISSIONS and FILE_PERMISSIONS are appropriate

Next Steps
----------

After configuration, see the :doc:`usage` guide to learn how to run the pipeline.
