#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Update BIDS fieldmap metadata for fMRI preprocessing

This script updates the JSON metadata for fieldmaps and their corresponding
BOLD images to properly link them for distortion correction in fMRIPrep.
It handles both AP and PA phase encoding directions and sets the appropriate
B0 field identifiers and intended-for relationships.

@Author: Shawn Schwartz - Stanford Memory Lab
@Date: January 30, 2025
@Description: Update JSON metadata in fieldmap and BOLD files for fMRIPrep
@Dependencies: Python 3.9+
@Usage: Called by prepare_fmri.sh as part of the preprocessing pipeline

Arguments:
    --subid: Subject ID without "sub-" prefix (e.g., '001')
    --bids-dir: Path to BIDS directory
    --task-id: Original task identifier
    --new-task-id: New task identifier (if renaming)
    --fmap-mapping: JSON string of fieldmap:BOLD run mapping
    --runs: Comma-separated list of run numbers
"""

from pathlib import Path
import json
import argparse
import logging
from typing import Dict, List


def setup_logging(subject_id: str) -> logging.Logger:
    """Configure logging"""
    logging.basicConfig(
        format='(%(asctime)s) [%(levelname)s] %(message)s',
        level=logging.INFO,
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    logger = logging.getLogger(f"fmap_metadata_sub-{subject_id}")
    return logger

def update_json_metadata(
    bids_dir: Path,
    subject_id: str,
    task_id: str,
    new_task_id: str,
    run_id: str,
    fmap_mapping: Dict[str, str],
    logger: logging.Logger
) -> None:
    """
    Update JSON metadata for fieldmaps and BOLD data
    """
    fmap_id = fmap_mapping.get(run_id)

    # check if BOLD file exists
    bold_file = bids_dir / f'sub-{subject_id}/func/sub-{subject_id}_task-{new_task_id}_run-{run_id}_dir-PA_bold.nii.gz'
    if not bold_file.exists():
        logger.warning(f"BOLD file not found: {bold_file}")
        return

    # find paired run for this fieldmap
    paired_runs = []
    for run, fmap in fmap_mapping.items():
        if fmap == fmap_id:
            paired_runs.append(run)
    paired_runs.sort()

    # generate IntendedFor file list
    intended_files = [
        f'bids::sub-{subject_id}/func/sub-{subject_id}_task-{new_task_id}_run-{run}_dir-PA_bold.nii.gz'
        for run in paired_runs
    ]
    
    fmap_identifier = f'phasediff_fmap{fmap_id}'
    
    # update fieldmap JSONs
    for direction in ['AP', 'PA']:
        polarity = '1-flipped' if direction == 'AP' else '0-normal'
        phasedir = 'j-' if direction == 'AP' else 'j'
        json_path = bids_dir / f'sub-{subject_id}/fmap/sub-{subject_id}_acq-{new_task_id}_run-{fmap_id}_dir-{direction}_epi.json'
        
        try:
            json_path.chmod(0o775)
            with json_path.open() as f:
                metadata = json.load(f)
            
            metadata.update({
                'B0FieldIdentifier': fmap_identifier,
                'IntendedFor': intended_files,
                'PhaseEncodingDirection': phasedir,
                'PhaseEncodingPolarityGE': polarity,
                'TaskName': new_task_id 
            })
            
            metadata = dict(sorted(metadata.items()))
            with json_path.open('w') as f:
                json.dump(metadata, f, indent=2)
            
            logger.info(f"Updated {direction} fieldmap metadata for run {run_id}")
            
        except Exception as e:
            logger.error(f"Failed to update {direction} fieldmap metadata: {e}")
    
    # update BOLD JSON
    try:
        bold_path = Path(bold_file)

        if bold_path.name.endswith('.nii.gz'):
            bold_json = bold_path.with_name(bold_path.name[:-7] + '.json')
        else:
            print("Error: file doesn't end with .nii.gz")
    
        bold_json.chmod(0o775)
        
        with bold_json.open() as f:
            metadata = json.load(f)
        
        metadata.update({
            'B0FieldSource': fmap_identifier,
            'PhaseEncodingDirection': 'j',
            'PhaseEncodingPolarityGE': '0-normal',
            'TaskName': new_task_id 
        })
        
        metadata = dict(sorted(metadata.items()))
        with bold_json.open('w') as f:
            json.dump(metadata, f, indent=2)
            
        logger.info(f"Updated BOLD metadata for run {run_id}")
        
    except Exception as e:
        logger.error(f"Failed to update BOLD metadata: {e}")

def main():
    parser = argparse.ArgumentParser(description='Update BIDS metadata for fieldmap processing')
    parser.add_argument('--subid', required=True, help='Subject ID (e.g., 001)')
    parser.add_argument('--bids-dir', required=True, help='Path to BIDS directory')
    parser.add_argument('--task-id', required=True, help='Original task ID')
    parser.add_argument('--new-task-id', required=True, help='New task ID')
    parser.add_argument('--fmap-mapping', required=True, help='JSON string of fieldmap mapping dictionary')
    parser.add_argument('--runs', required=True, help='Comma-separated list of run numbers')
    args = parser.parse_args()

    logger = setup_logging(args.subid)
    
    fmap_mapping = json.loads(args.fmap_mapping)
    run_numbers = args.runs.split(',')
    
    for run_id in run_numbers:
        update_json_metadata(
            bids_dir=Path(args.bids_dir),
            subject_id=args.subid,
            task_id=args.task_id,
            new_task_id=args.new_task_id,
            run_id=run_id,
            fmap_mapping=fmap_mapping,
            logger=logger
        )

if __name__ == '__main__':
    main()
