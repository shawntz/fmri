Usage
=====

The fMRIPrep Workbench provides two methods for running pipeline steps:
an interactive TUI launcher and manual execution of sbatch scripts.

Interactive TUI Launcher
-------------------------

The graphical launcher provides an interactive interface with context and parameter setting:

.. code-block:: bash

   ./launch

**Features:**

- Welcome screen with pipeline overview
- Workflow selector with step descriptions
- Interactive parameter setting for each step
- User-friendly for those less familiar with command line

**Example Workflow:**

1. Launch the TUI: ``./launch``
2. Select a preprocessing step from the menu
3. Configure parameters (if needed)
4. Submit the job to SLURM

Manual Execution
----------------

For more control, you can manually execute each sbatch script:

Basic Usage
~~~~~~~~~~~

.. code-block:: bash

   # Run step 1: FlyWheel to Server transfer
   ./01-run.sbatch

   # Run step 2: dcm2niix conversion
   ./02-run.sbatch

   # Run step 3: Prep for fMRIPrep (dummy scan removal, fieldmap setup)
   ./03-run.sbatch

   # Run step 4: QC metadata verification
   ./04-run.sbatch

   # Run step 5: QC volume verification
   ./05-run.sbatch

   # Run step 6: fMRIPrep anatomical workflows only
   ./06-run.sbatch

   # Run step 7: fMRIPrep complete workflows
   ./07-run.sbatch

Pipeline Steps
--------------

The preprocessing pipeline consists of seven steps:

**Step 1: FlyWheel Transfer** (``01-run.sbatch``)
   Automated transfer of scanner acquisitions from FlyWheel to server

**Step 2: DICOM Conversion** (``02-run.sbatch``)
   Convert DICOM files to NIfTI format using heudiconv/dcm2niix

**Step 3: Prep for fMRIPrep** (``03-run.sbatch``)
   - Remove dummy scans
   - Set up fieldmap-based distortion correction
   - Validate data structure

**Step 4: QC Metadata** (``04-run.sbatch``)
   Verify DICOM to NIfTI to BIDS metadata conversion

**Step 5: QC Volumes** (``05-run.sbatch``)
   Verify scan volume counts match expected values

**Step 6: fMRIPrep Anatomical** (``06-run.sbatch``)
   Run fMRIPrep anatomical workflows only (for manual FreeSurfer editing)

**Step 7: fMRIPrep Complete** (``07-run.sbatch``)
   Run full fMRIPrep workflows (anatomical + functional)

.. note::

   **v0.2.0 Change**: Steps 4 and 5 are now dedicated pipeline steps with their
   own sbatch wrappers, rather than toolbox-only utilities. The fMRIPrep steps
   have been renumbered to 6 and 7.

Typical Workflow
----------------

Standard Processing (No Manual FreeSurfer Editing)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # 1. Download data from FlyWheel
   ./01-run.sbatch

   # 2. Convert DICOM to NIfTI
   ./02-run.sbatch

   # 3. Prepare for fMRIPrep
   ./03-run.sbatch

   # 4. Verify metadata
   ./04-run.sbatch

   # 5. Verify volume counts
   ./05-run.sbatch

   # 6. Skip step 6, run full fMRIPrep directly
   ./07-run.sbatch

Processing with Manual FreeSurfer Editing
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Steps 1-5 same as above...
   ./01-run.sbatch
   ./02-run.sbatch
   ./03-run.sbatch
   ./04-run.sbatch
   ./05-run.sbatch

   # 6. Run anatomical-only fMRIPrep
   ./06-run.sbatch

   # 7. Download, edit FreeSurfer surfaces, re-upload

   # 8. Run full fMRIPrep with edited surfaces
   ./07-run.sbatch

SLURM Job Naming
----------------

.. note::

   **v0.2.0 Change**: All SLURM jobs now use the unified naming pattern
   ``fmriprep-workbench-{N}`` where N is the step number.

.. list-table:: Job Names
   :header-rows: 1
   :widths: 20 30 50

   * - Step
     - Job Name
     - Directory (STEP_NAME)
   * - 1
     - ``fmriprep-workbench-1``
     - ``01-fw2server``
   * - 2
     - ``fmriprep-workbench-2``
     - ``02-dcm2niix``
   * - 3
     - ``fmriprep-workbench-3``
     - ``03-prep-fmriprep``
   * - 4
     - ``fmriprep-workbench-4``
     - ``04-qc-metadata``
   * - 5
     - ``fmriprep-workbench-5``
     - ``05-qc-volumes``
   * - 6
     - ``fmriprep-workbench-6``
     - ``06-run-fmriprep``
   * - 7
     - ``fmriprep-workbench-7``
     - ``07-run-fmriprep``

The ``JOB_NAME`` is used for SLURM display (visible in ``squeue``), while
``STEP_NAME`` is used for log directory organization.

Monitoring Jobs
---------------

Check SLURM Job Status
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # View all your jobs
   squeue -u $USER

   # View jobs by name pattern
   squeue -u $USER -n fmriprep-workbench-3

   # View specific job details
   scontrol show job <job_id>

   # View job array status
   sacct -j <job_id>

Check Logs
~~~~~~~~~~

Log files are organized by step name in the configured log directory:

.. code-block:: bash

   # SLURM logs (organized by step)
   ls ${SLURM_LOG_DIR}/03-prep-fmriprep/
   ls ${SLURM_LOG_DIR}/04-qc-metadata/
   ls ${SLURM_LOG_DIR}/06-run-fmriprep/

   # View a specific log file
   # Format: <job_name>_<array_job_id>_<task_id>.out
   less ${SLURM_LOG_DIR}/03-prep-fmriprep/fmriprep-workbench-3_12345_0.out

   # Workflow logs
   ls ${WORKFLOW_LOG_DIR}/

Subject List Handling
---------------------

.. note::

   **v0.2.0 Enhancement**: Comment lines (starting with ``#``) and blank lines
   are now automatically filtered when counting subjects for SLURM array jobs.

Example Subject List
~~~~~~~~~~~~~~~~~~~~

.. code-block:: text

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

Subject Modifiers
~~~~~~~~~~~~~~~~~

Use modifiers for fine-grained control:

.. code-block:: text

   101                # Standard subject, runs all steps
   102:step4          # Only run step 4 for this subject
   103:step4:step5    # Only run steps 4 and 5
   104:force          # Force rerun all steps
   105:step5:force    # Only run step 5, force rerun
   106:skip           # Skip this subject

Quality Control
---------------

After preprocessing, review the outputs:

**Check fMRIPrep Reports**

.. code-block:: bash

   # Open HTML reports in browser
   firefox ${DERIVS_DIR}/sub-<subject_id>.html

**Validate BIDS Structure**

.. code-block:: bash

   # Use BIDS validator (if installed)
   bids-validator ${TRIM_DIR}

**Inspect Preprocessed Data**

.. code-block:: bash

   # Check output structure
   tree ${DERIVS_DIR}/sub-<subject_id>/

   # View metadata
   cat ${DERIVS_DIR}/sub-<subject_id>/func/*.json

Troubleshooting
---------------

Failed Jobs
~~~~~~~~~~~

If a job fails, check the logs:

1. Review SLURM output: ``${SLURM_LOG_DIR}/<step-name>/*.out``
2. Check error logs: ``${SLURM_LOG_DIR}/<step-name>/*.err``
3. Examine workflow logs: ``${WORKFLOW_LOG_DIR}/``

Common solutions:

- Verify paths in ``config.yaml``
- Check file permissions
- Ensure sufficient disk space
- Validate BIDS structure

Rerunning Subjects
~~~~~~~~~~~~~~~~~~

To rerun a subject, use the ``force`` modifier:

.. code-block:: text

   # In your subject list file
   101:force

Or manually remove the completion marker before rerunning.

Debug Mode
~~~~~~~~~~

Enable debug mode in ``config.yaml``:

.. code-block:: yaml

   misc:
     debug: 1

This runs the pipeline with only a single subject (array index 0) for testing.

Configuration Validation
~~~~~~~~~~~~~~~~~~~~~~~~

Test that your configuration loads correctly:

.. code-block:: bash

   source ./load_config.sh

   # Check key variables
   echo "BASE_DIR: ${BASE_DIR}"
   echo "TRIM_DIR: ${TRIM_DIR}"
   echo "DERIVS_DIR: ${DERIVS_DIR}"

Best Practices
--------------

1. **Test on a Single Subject**

   Always test your configuration on one subject before processing the entire dataset.
   Use debug mode or create a test subject list.

2. **Monitor Resource Usage**

   Use ``sstat`` and ``sacct`` to monitor job resource usage and adjust settings if needed.

3. **Regular Backups**

   Maintain backups of raw data and important intermediate outputs.

4. **Document Changes**

   Keep notes on any parameter changes or manual interventions.

5. **Review QC Reports**

   Always review fMRIPrep HTML reports for quality control.

6. **Use Comments in Subject Lists**

   Document your subject lists with comments to track processing status and notes.

Next Steps
----------

- See :doc:`workflows` for detailed pipeline documentation
- Check :doc:`contributing` to contribute improvements
- Review :doc:`changelog` for version history
