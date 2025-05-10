#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert DICOM tarball to BIDS format using heudiconv.

@Author: Shawn Schwartz - Stanford Memory Lab
@Date: May 9, 2025
@Description: Extract metadata from scan dicom headers for heudiconv
@Dependencies: Python 3.9+
@Usage: Called by dcm2niix.sh as part of the preprocessing pipeline

Arguments:
    --subid: Subject ID without "sub-" prefix (e.g., '001')
    --bids-dir: Path to BIDS directory
    --task-id: Original task identifier
    --new-task-id: New task identifier (if renaming)
    --fmap-mapping: JSON string of fieldmap:BOLD run mapping
    --runs: Comma-separated list of run numbers
"""

import argparse, os, shutil, tarfile, subprocess
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(description='Convert DICOM tarball to BIDS.')
    parser.add_argument("--user", action="store", help="Your SUNet ID, e.g., janedoe")
    parser.add_argument("--subid", action="store", required=True, help="e.g. 001")
    parser.add_argument("--exam_num", action="store", required=True, help="e.g. 21940")
    parser.add_argument("--project_dir", action="store", required=True, help="Parent dir where project files live")
    parser.add_argument("--fw_group_id", action="store", required=True, help="Flywheel group ID (i.e., parent dir of all project IDs, fw://surname)")
    parser.add_argument("--fw_project_id", action="store", required=True, help="Flywheel Project ID (e.g., amass)")
    parser.add_argument("--task_id", action="store", required=True, help="Task name label that will appear in BIDS files")
    parser.add_argument("--sing_image_path", action="store", required=True, help="Path to the heudiconv singularity image, should be defined in settings.sh")
    return parser.parse_args()

def main():
    args = parse_args()

    if args.user is None:
        raise ValueError(
            "SUNet ID user argument not defined, please do so with the --user flag!"
        )

    scratch_base = Path(f"/scratch/users/{args.user}")
    scratch_sub_dir = scratch_base / f"sub-{args.subid}"
    untar_dir = scratch_sub_dir / f"untar_{args.exam_num}"
    oak_base = Path(f"{args.project_dir}")
    bids_dir = oak_base / "bids"
    dicoms_dir = oak_base / "dicoms"
    heu_file = "dcm_heuristic.py"

    # Source and target DICOM tar
    tar_input = scratch_base / f"fw_{args.exam_num}" / "dicoms" / f"{args.exam_num}.tar"
    tar_target = dicoms_dir / f"sub-{args.subid}.tar"

    # Make needed dirs
    dicom_extract_dir = dicoms_dir / f"sub-{args.subid}"
    dicom_extract_dir.mkdir(parents=True, exist_ok=True)
    untar_dir.mkdir(parents=True, exist_ok=True)

    # Untar
    print(f"[INFO] Extracting {tar_input} -> {untar_dir}")
    shutil.move(str(tar_input), scratch_sub_dir / f"{args.exam_num}.tar")
    with tarfile.open(scratch_sub_dir / f"{args.exam_num}.tar") as tar:
        tar.extractall(path=untar_dir)

    # Move tar to permanent oak location
    shutil.move(str(scratch_sub_dir / f"{args.exam_num}.tar"), tar_target)
    print(f"[INFO] Tar archive moved to {tar_target}")

    # Unzip DICOMs
    zipdir = untar_dir / "scitran" / f"{args.fw_group_id}" / f"{args.fw_project_id}" / f"{args.subid}" / f"{args.exam_num}"
    print(f"[INFO] Unzipping all zip files from {zipdir}")
    for zf in zipdir.glob("**/*.zip"):
        subprocess.run(['unzip', '-qq', str(zf), '-d', str(dicom_extract_dir)], check=True)

    # Delete screenshots
    for pattern in ["*2000*.dicom", "*4000*.dicom", "*_200*.dicom"]:
        for f in dicom_extract_dir.glob(pattern):
            f.unlink()

    print(f"[INFO] Screenshot DICOMs deleted from {dicom_extract_dir}")

    # Cleanup
    # shutil.rmtree(scratch_sub_dir)
    print(f"[INFO] Cleaned up temporary dir {scratch_sub_dir}")

    # Run heudiconv
    print(f"[INFO] Running heudiconv for sub-{args.subid}")
    cmd = (
        f"singularity run --cleanenv "
        f"-B {dicoms_dir}:/indir -B {bids_dir}:/outdir "
        f"-e {args.sing_image_path} "
        f"-d /indir/sub-{{subject}}/*.dicom/*.dcm "
        f"-o /outdir/ -f {heu_file} -s {args.subid} -c dcm2niix -b notop --overwrite"
    )
    subprocess.run(cmd, shell=True, check=True)

    print("[INFO] DICOM to BIDS conversion complete.")

if __name__ == "__main__":
    main()