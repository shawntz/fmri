Configuration
=============

The preprocessing pipeline requires proper configuration of several parameters
in the ``config.yaml`` file. This guide explains how to configure your pipeline.

.. note::

   **v0.2.0 Breaking Change**: The configuration system has migrated from
   ``settings.sh`` (Bash) to ``config.yaml`` (YAML). See the
   :ref:`migration-guide` section below if upgrading from an earlier version.

Configuration File
------------------

The main configuration file is ``config.yaml``, which is created by copying
``config.template.yaml``:

.. code-block:: bash

   cp config.template.yaml config.yaml

The configuration is loaded by sourcing ``load_config.sh``, which parses the
YAML file and exports environment variables for use in pipeline scripts:

.. code-block:: bash

   source ./load_config.sh

Path Configuration
------------------

Set up your directory structure in the ``directories`` section:

.. code-block:: yaml

   directories:
     base_dir: '/path/to/your/study'
     scripts_dir: '/path/to/your/study/code'
     raw_dir: '/path/to/your/study/sourcedata'
     trim_dir: '/path/to/your/study'
     workflow_log_dir: '/path/to/your/study/logs'
     templateflow_host_home: '~/.cache/templateflow'
     fmriprep_host_cache: '~/.cache/fmriprep'
     freesurfer_license: '~/freesurfer.txt'

**Path Descriptions:**

- ``base_dir``: Root directory for the study
- ``scripts_dir``: Path of cloned fmriprep-workbench repository
- ``raw_dir``: Raw BIDS-compliant data location (sourcedata)
- ``trim_dir``: Destination for processed data
- ``workflow_log_dir``: Directory for workflow logs
- ``templateflow_host_home``: Host cache directory for TemplateFlow templates
- ``fmriprep_host_cache``: fMRIPrep-specific cache directory
- ``freesurfer_license``: Path to your FreeSurfer license file

User Configuration
------------------

Configure user-specific settings:

.. code-block:: yaml

   user:
     email: 'johndoe@stanford.edu'
     username: 'johndoe'
     fw_group_id: 'pi'
     fw_project_id: 'amass'

Task Parameters
---------------

Configure your task-specific settings in the ``scan`` section:

.. code-block:: yaml

   scan:
     fw_cli_api_key_file: '~/flywheel_api_key.txt'
     fw_url: 'cni.flywheel.io'
     config_file: 'scan-config.json'
     experiment_type: 'advanced'
     task_id: 'OriginalTaskName'
     new_task_id: 'cleanname'
     n_dummy: 5
     run_numbers:
       - '01'
       - '02'
       - '03'
       - '04'
       - '05'
       - '06'
       - '07'
       - '08'

**Parameter Descriptions:**

- ``task_id``: Original task name in BIDS format
- ``new_task_id``: New task name (if renaming needed), otherwise set same value as ``task_id``
- ``n_dummy``: Number of dummy TRs to remove from the beginning of each run
- ``run_numbers``: List of all task BOLD run numbers (as strings with zero-padding)

Data Validation
---------------

Set expected volume counts for validation in the ``validation`` section:

.. code-block:: yaml

   validation:
     expected_fmap_vols: 12
     expected_bold_vols: 220
     expected_bold_vols_after_trimming: 215

These values are used by QC steps (04-qc-metadata and 05-qc-volumes) to verify
that your scans have the expected number of volumes.

Fieldmap Mapping
----------------

Map fieldmaps to BOLD runs in the ``fmap_mapping`` section:

.. code-block:: yaml

   fmap_mapping:
     '01': '01'  # TASK BOLD RUN 01 USES FMAP 01
     '02': '01'  # TASK BOLD RUN 02 USES FMAP 01
     '03': '02'  # TASK BOLD RUN 03 USES FMAP 02
     '04': '02'  # TASK BOLD RUN 04 USES FMAP 02
     '05': '03'  # TASK BOLD RUN 05 USES FMAP 03
     '06': '03'  # TASK BOLD RUN 06 USES FMAP 03
     '07': '04'  # TASK BOLD RUN 07 USES FMAP 04
     '08': '04'  # TASK BOLD RUN 08 USES FMAP 04

Each key represents a BOLD run number, and its value is the fieldmap number
that covers that run. This mapping determines which fieldmap is used for
susceptibility distortion correction for each BOLD run.

Subject Lists
-------------

Basic subject list in ``all-subjects.txt``:

.. code-block:: text

   # This is a comment - these lines are automatically filtered
   # Blank lines are also ignored

   101
   102
   103

.. note::

   **v0.2.0 Enhancement**: Comment lines (starting with ``#``) and blank lines
   are now automatically filtered when counting subjects for SLURM array jobs.
   This makes it easier to document your subject lists.

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

- ``step1`` to ``step7`` - Run specific steps only
- ``force`` - Force rerun even if already processed
- ``skip`` - Skip this subject entirely

Step-Specific Subject Files
~~~~~~~~~~~~~~~~~~~~~~~~~~~

By default, subjects are pulled from ``all-subjects.txt``. You can optionally
specify different subject lists per pipeline step in ``config.yaml``:

.. code-block:: yaml

   subjects_mapping:
     '01-fw2server': '01-subjects.txt'
     '02-raw2bids': '02-subjects.txt'
     '06-run-fmriprep': '06-subjects.txt'

Permissions
-----------

Set file and directory permissions:

.. code-block:: yaml

   permissions:
     dir_permissions: '775'
     file_permissions: '775'

SLURM Configuration
-------------------

Configure SLURM job parameters for general tasks:

.. code-block:: yaml

   slurm:
     email: 'your.email@institution.edu'
     time: '2:00:00'
     dcmniix_time: '12:00:00'
     mem: '4G'
     cpus: 8
     array_throttle: 10
     log_dir: '/path/to/your/study/logs'
     partition: 'partition1,partition2'

.. note::

   **v0.2.0 Change**: SLURM job names now use a unified ``fmriprep-workbench-{N}``
   naming pattern (e.g., ``fmriprep-workbench-3`` for step 3). The ``STEP_NAME``
   variable is used for directory organization, while ``JOB_NAME`` is used for
   SLURM display.

Pipeline Settings
-----------------

Configure container and derivatives paths:

.. code-block:: yaml

   pipeline:
     fmriprep_version: '24.0.1'
     derivs_dir: '/path/to/your/study/derivatives/fmriprep-24.0.1'
     singularity_image_dir: '/path/to/your/study/containers'
     singularity_image: 'fmriprep-24.0.1.simg'
     heudiconv_image: 'heudiconv_latest.sif'

fMRIPrep SLURM Settings
-----------------------

Configure SLURM parameters specifically for fMRIPrep jobs (steps 6 and 7):

.. code-block:: yaml

   fmriprep_slurm:
     job_name: 'fmriprep_yourproject'
     time: '48:00:00'
     cpus_per_task: 16
     mem_per_cpu: '4G'

fMRIPrep Settings
-----------------

Configure fMRIPrep-specific parameters:

.. code-block:: yaml

   fmriprep:
     omp_threads: 8
     nthreads: 12
     mem_mb: 30000
     fd_spike_threshold: 0.9
     dvars_spike_threshold: 3.0
     output_spaces: 'MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5'

Miscellaneous Settings
----------------------

.. code-block:: yaml

   misc:
     debug: 0  # Debug mode (0=off, 1=on)

When ``debug`` is set to ``1``, the pipeline runs with only a single subject
(array index 0) for testing purposes.

.. _migration-guide:

Migration from settings.sh (v0.1.x to v0.2.0)
---------------------------------------------

If you are upgrading from a version that used ``settings.sh``, follow these steps:

1. **Create new config file**:

   .. code-block:: bash

      cp config.template.yaml config.yaml

2. **Transfer your settings**: Map your old Bash variables to the new YAML structure:

   .. list-table:: Configuration Mapping
      :header-rows: 1
      :widths: 40 60

      * - Old (settings.sh)
        - New (config.yaml)
      * - ``BASE_DIR="/path/to/study"``
        - ``directories.base_dir: '/path/to/study'``
      * - ``task_id="TaskName"``
        - ``scan.task_id: 'TaskName'``
      * - ``n_dummy=5``
        - ``scan.n_dummy: 5``
      * - ``run_numbers=("01" "02")``
        - ``scan.run_numbers: ['01', '02']``
      * - ``declare -A fmap_mapping=(["01"]="01")``
        - ``fmap_mapping: {'01': '01'}``
      * - ``EXPECTED_FMAP_VOLS=12``
        - ``validation.expected_fmap_vols: 12``
      * - ``SLURM_EMAIL="email@edu"``
        - ``slurm.email: 'email@edu'``
      * - ``FMRIPREP_VERSION="24.0.1"``
        - ``pipeline.fmriprep_version: '24.0.1'``

3. **Update step references**: Note the new QC step numbering:

   - Old step 4 (toolbox QC metadata) is now step 4 (``04-qc-metadata``)
   - Old step 5 (toolbox QC volumes) is now step 5 (``05-qc-volumes``)
   - Old step 5/6 (fMRIPrep anat) is now step 6 (``06-run-fmriprep``)
   - Old step 6/7 (fMRIPrep full) is now step 7 (``07-run-fmriprep``)

4. **Remove old settings.sh**: Once migrated, you can remove the old ``settings.sh``
   file as it is no longer used.

Validation
----------

Before running the pipeline:

1. Verify all paths exist and are accessible
2. Confirm volume counts match your acquisition protocol
3. Test configuration loading:

   .. code-block:: bash

      source ./load_config.sh

4. Test on a single subject before batch processing
5. Review logs for configuration warnings

Common Issues
-------------

**YAML Syntax Errors**
   Ensure proper YAML formatting. Use a YAML validator if needed.
   Common issues include incorrect indentation and missing quotes around strings.

**Path Issues**
   Double-check all path specifications are absolute and accessible.
   Paths with tildes (``~``) are expanded automatically.

**Volume Mismatches**
   Verify ``validation.expected_fmap_vols`` and ``validation.expected_bold_vols``
   match your acquisition protocol.

**Fieldmap Mapping**
   Ensure each BOLD run has a corresponding fieldmap entry in ``fmap_mapping``.
   Keys and values should be quoted strings (e.g., ``'01': '01'``).

**Permission Problems**
   Check that ``permissions.dir_permissions`` and ``permissions.file_permissions``
   are appropriate for your cluster environment.

Next Steps
----------

After configuration, see the :doc:`usage` guide to learn how to run the pipeline.
