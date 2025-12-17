Usage
=====

The SML fMRI Preprocessing Template provides two methods for running pipeline steps:
an interactive TUI launcher and manual execution of sidecar scripts.

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
4. Submit the job to Slurm

Manual Execution
----------------

For more control, you can manually execute each sidecar script:

Basic Usage
~~~~~~~~~~~

.. code-block:: bash

   # Run step 1: FlyWheel to Server transfer
   ./01-run.sbatch

   # Run step 3: dcm2niix conversion
   ./03-run.sbatch

   # Run step 4: Prep for fMRIPrep
   ./04-run.sbatch

fMRIPrep Options
~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Anatomical workflows only
   ./05-run.sbatch --anat-only

   # Both anatomical and functional workflows
   ./05-run.sbatch

   # Continue with remaining fMRIPrep steps
   ./06-run.sbatch

Pipeline Steps
--------------

The preprocessing pipeline consists of the following steps:

**Step 1: FlyWheel Transfer**
   Automated transfer of scanner acquisitions from FlyWheel to Server

**Step 2: BIDS Conversion** *(if needed)*
   Convert raw data to BIDS format

**Step 3: dcm2niix Conversion**
   Convert DICOM files to NIfTI format

**Step 4: Prep for fMRIPrep**
   - Remove dummy scans
   - Set up fieldmap-based distortion correction
   - Validate data structure

**Step 5: fMRIPrep Anatomical**
   Run fMRIPrep anatomical workflows only (if doing manual edits)

**Step 6: fMRIPrep Complete**
   Run remaining fMRIPrep steps (functional workflows)

Monitoring Jobs
---------------

Check Slurm Job Status
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # View all your jobs
   squeue -u $USER

   # View specific job details
   scontrol show job <job_id>

   # View job array status
   sacct -j <job_id>

Check Logs
~~~~~~~~~~

Log files are stored in the configured log directory:

.. code-block:: bash

   # Slurm logs
   ls ${BASE_DIR}/logs/slurm/

   # Workflow logs
   ls ${BASE_DIR}/logs/workflows/

   # View a specific log
   less ${BASE_DIR}/logs/slurm/step-01_<subject_id>.out

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

1. Review Slurm output: ``${BASE_DIR}/logs/slurm/*.out``
2. Check error logs: ``${BASE_DIR}/logs/slurm/*.err``
3. Examine workflow logs: ``${BASE_DIR}/logs/workflows/``

Common solutions:

- Verify paths in ``settings.sh``
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

Enable debug mode in ``settings.sh``:

.. code-block:: bash

   DEBUG=1

This provides more verbose output for troubleshooting.

Best Practices
--------------

1. **Test on a Single Subject**
   
   Always test your configuration on one subject before processing the entire dataset.

2. **Monitor Resource Usage**
   
   Use ``sstat`` and ``sacct`` to monitor job resource usage and adjust settings if needed.

3. **Regular Backups**
   
   Maintain backups of raw data and important intermediate outputs.

4. **Document Changes**
   
   Keep notes on any parameter changes or manual interventions.

5. **Review QC Reports**
   
   Always review fMRIPrep HTML reports for quality control.

Next Steps
----------

- See :doc:`workflows` for detailed pipeline documentation
- Check :doc:`contributing` to contribute improvements
- Review :doc:`changelog` for version history
