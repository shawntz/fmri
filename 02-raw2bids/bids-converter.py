#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Converter for Flywheel raw downloads to BIDS format.

@Author: Shawn Schwartz - Stanford Memory Lab
@Date: February 26, 2025
@Dependencies: Python 3.9+
@Usage: python bids_converter.py --user your_sunet_id --subid 001 --exam_num 26147 --project_dir /path/to/parent/dir/ --fw_group_id surname --fw_project_id amass --task_id GoalAttnMemTest [--experiment_type basic] [--config path/to/config.json]
"""

import argparse
import logging
import os
import shutil
import tarfile
from glob import glob
from typing import Dict, List, Optional

from scan_config_manager import ScanConfigManager


class BIDSConverter:
    """A class to handle converting transferred files from Flywheel to BIDS format."""

    def __init__(
        self,
        user: str,
        subid: str,
        fw_session_id: str,
        project_dir: str,
        fw_group_id: str,
        fw_project_id: str,
        task_id: str,
        experiment_type: str = "basic",
        config_file: str = "scan-config.json",
        series_overrides: Optional[Dict[str, List[int]]] = None,
    ):
        self.user = user
        self.subid = subid, # new (trimmed) id
        self.exam_num = fw_session_id
        self.project_dir = project_dir
        self.fw_group_id = fw_group_id
        self.fw_project_id = fw_project_id
        self.task_id = task_id
        self.experiment_type = experiment_type
        self.logger = self._setup_logger()

        self.config_manager = ScanConfigManager(config_file, self.logger)

        if series_overrides:
            self.config_manager.apply_command_line_overrides(series_overrides)

        self.experiment_sequences = self.config_manager.get_experiment_config(
            experiment_type
        )
        self.logger.info(
            f"Using experiment type '{experiment_type}' with sequences: {self.experiment_sequences}"
        )

        self.scratch_dir = f"/scratch/users/{self.user}/fw_{self.exam_num}"
        self.bids_path = f"{self.project_dir}/bids"
        self.fw_tar_path = f"{self.project_dir}/flywheel"

    def _setup_logger(self) -> logging.Logger:
        logger = logging.getLogger("bids_converter")
        logger.setLevel(logging.INFO)
        formatter = logging.Formatter("[%(levelname)s] - %(message)s")

        handler = logging.StreamHandler()
        handler.setFormatter(formatter)
        logger.addHandler(handler)

        return logger

    def untar_file(self, file_path: str) -> None:
        try:
            self.logger.info(f"Extracting tar file: {file_path}")
            tar = tarfile.open(file_path)
            tar.extractall()
            tar.close()

            scitran_path = f"untar_{self.exam_num}/scitran"
            self.mkdir(scitran_path)

            tar_source = "scitran/"
            if os.path.exists(tar_source):
                tarfiles = os.listdir(tar_source)
                for file in tarfiles:
                    file_name = os.path.join(tar_source, file)
                    shutil.move(file_name, scitran_path)
                os.system("rm -rf scitran")
                self.logger.info(
                    "Files unpacked and moved into subject specific directory!"
                )
            else:
                self.logger.warning(
                    f"Directory {tar_source} does not exist after extraction"
                )

        except Exception as e:
            self.logger.error(f"Error extracting tar file: {str(e)}")
            raise

    def mkdir(self, path: str) -> None:
        if not os.path.exists(path):
            os.makedirs(path)
            self.logger.info(f"Created directory: {path}")

    def setup_bids_directories(self) -> Dict[str, str]:
        sub_path = f"{self.bids_path}/sub-{self.subid}"
        self.mkdir(sub_path)

        anat_path = f"{sub_path}/anat/"
        func_path = f"{sub_path}/func/"
        fmap_path = f"{sub_path}/fmap/"

        self.mkdir(anat_path)
        self.mkdir(func_path)
        self.mkdir(fmap_path)

        return {"anat": anat_path, "func": func_path, "fmap": fmap_path}

    def copy_sequence_files(
        self,
        sequence_name: str,
        target_dir: str,
        bids_prefix: str,
        file_pattern: str,
        series_suffix: str = "",
    ) -> List[str]:
        flywheel_path = f"untar_{self.exam_num}/scitran/{self.fw_group_id}/{self.fw_project_id}"
        series_numbers = self.config_manager.get_series_numbers(sequence_name)
        copied_files = []

        if not series_numbers:
            self.logger.info(f"No series numbers defined for {sequence_name}, skipping")
            return copied_files

        for i, series in enumerate(series_numbers):
            try:
                file_glob = file_pattern.format(self.exam_num, series, series_suffix)
                matching_files = glob(f"{flywheel_path}/*/{file_glob}")

                if matching_files:
                    source_file = matching_files[0]
                    if len(matching_files) > 1:
                        self.logger.warning(
                            f"Multiple files match pattern for {sequence_name} series {series}, using first match"
                        )

                    if sequence_name in ["t1", "t2", "mt"]:
                        dest_filename = f"{bids_prefix}.nii.gz"
                    else:
                        run_num = i + 1
                        dest_filename = f"{bids_prefix}_run-{run_num:02d}.nii.gz"

                    dest_path = os.path.join(target_dir, dest_filename)
                    shutil.copy(source_file, dest_path)
                    self.logger.info(
                        f"Copied {sequence_name} series {series} to {dest_path}"
                    )
                    copied_files.append(dest_path)
                else:
                    self.logger.warning(
                        f"No files found for {sequence_name} series {series}"
                    )

                    if self.config_manager.is_sequence_required(sequence_name):
                        self.logger.error(
                            f"Required sequence {sequence_name} (series {series}) not found"
                        )

            except Exception as e:
                self.logger.error(
                    f"Error copying {sequence_name} series {series}: {str(e)}"
                )

        return copied_files

    def process_anatomical_data(self, anat_path: str) -> None:
        # process T1 if in experiment
        if "t1" in self.experiment_sequences:
            self.copy_sequence_files(
                sequence_name="t1",
                target_dir=anat_path,
                bids_prefix=f"sub-{self.subid}_T1w",
                file_pattern="/*/{}/*T1*/*_{}_*.nii.gz",
            )

        # process T2 if in experiment
        if "t2" in self.experiment_sequences:
            self.copy_sequence_files(
                sequence_name="t2",
                target_dir=anat_path,
                bids_prefix=f"sub-{self.subid}_inplaneT2",
                file_pattern="/*/{}/*T2*/*_{}_*.nii.gz",
            )

        # process MT if in experiment
        if "mt" in self.experiment_sequences:
            self.copy_sequence_files(
                sequence_name="mt",
                target_dir=anat_path,
                bids_prefix=f"sub-{self.subid}_mt-lc",
                file_pattern="/*/{}/*MT*/*_{}_*.nii.gz",
            )

    def process_functional_data(self, func_path: str) -> None:
        # process test scans if in experiment
        if "test" in self.experiment_sequences:
            self.copy_sequence_files(
                sequence_name="test",
                target_dir=func_path,
                bids_prefix=f"sub-{self.subid}_task-{self.task_id}",
                file_pattern="/*/{}/*test*/*_{}_*.nii.gz",
            )

    def process_fieldmap_data(self, fmap_path: str) -> None:
        if "pe1" in self.experiment_sequences:
            self.copy_sequence_files(
                sequence_name="pe1",
                target_dir=fmap_path,
                bids_prefix=f"sub-{self.subid}_{self.task_id}",
                file_pattern="/*/{}/*pe1*CAL*/*_{}_*.nii.gz",
            )

    def move_tar_file(self) -> None:
        try:
            subj_tar_path = f"{self.fw_tar_path}/sub-{self.subid}"
            self.mkdir(subj_tar_path)

            source_tar = f"{self.scratch_dir}/niftis/{self.exam_num}.tar"
            target_tar = f"{subj_tar_path}/{self.exam_num}.tar"

            if os.path.exists(source_tar):
                shutil.move(source_tar, target_tar)
                self.logger.info(f"Moved tar file to {target_tar}")
            else:
                self.logger.warning(f"Source tar file {source_tar} does not exist")

        except Exception as e:
            self.logger.error(f"Error moving tar file: {str(e)}")

    def cleanup(self) -> None:
        try:
            untar_dir = f"/scratch/users/{self.user}/untar_{self.exam_num}"
            if os.path.exists(untar_dir):
                shutil.rmtree(untar_dir)
                self.logger.info(f"Removed temporary directory: {untar_dir}")

        except Exception as e:
            self.logger.error(f"Error during cleanup: {str(e)}")

    def set_permissions(self) -> None:
        try:
            commands = [
                f"chmod 775 {self.bids_path}/sub-{self.subid}/anat",
                f"chmod 775 {self.bids_path}/sub-{self.subid}/anat/*",
                f"chmod 775 {self.bids_path}/sub-{self.subid}/func",
                f"chmod 775 {self.bids_path}/sub-{self.subid}/func/*",
                f"chmod 775 {self.bids_path}/sub-{self.subid}/fmap",
                f"chmod 775 {self.bids_path}/sub-{self.subid}/fmap/*",
            ]

            for cmd in commands:
                os.system(cmd)

            self.logger.info("Set permissions for all BIDS directories")

        except Exception as e:
            self.logger.error(f"Error setting permissions: {str(e)}")

    def run(self) -> bool:
        try:
            self.config_manager.print_config_summary()

            tar_file = os.path.join(
                self.scratch_dir + "/niftis", self.exam_num + ".tar"
            )
            self.untar_file(tar_file)

            bids_dirs = self.setup_bids_directories()

            self.process_anatomical_data(bids_dirs["anat"])
            self.process_functional_data(bids_dirs["func"])
            self.process_fieldmap_data(bids_dirs["fmap"])

            self.move_tar_file()

            self.cleanup()

            self.set_permissions()

            self.logger.info("BIDS conversion completed successfully!")
            return True

        except Exception as e:
            self.logger.error(f"BIDS conversion failed: {str(e)}")
            return False

def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert Flywheel data to BIDS format."
    )
    parser.add_argument("--user", action="store", help="Your SUNet ID, e.g., janedoe")
    parser.add_argument("--subid", action="store", required=True, help="e.g. 001")
    parser.add_argument("--exam_num", action="store", required=True, help="e.g. 21940")
    parser.add_argument(
        "--project_dir", action="store", required=True, help="Parent dir where project files live"
    )
    parser.add_argument("--fw_group_id", action="store", required=True, help="Flywheel group ID (i.e., parent dir of all project IDs, fw://surname)")
    parser.add_argument("--fw_project_id", action="store", required=True, help="Flywheel Project ID (e.g., amass)")
    parser.add_argument("--task_id", action="store", required=True, help="Task name label that will appear in BIDS files")

    parser.add_argument(
        "--experiment_type",
        action="store",
        default="basic",
        help="Type of experiment (determines which sequences to include)",
    )
    parser.add_argument(
        "--config", action="store", default=None, help="Path to configuration file"
    )
    # add overrides for individual sequence series numbers
    parser.add_argument(
        "--t1_series",
        action="store",
        nargs="*",
        type=int,
        default=None,
        help="Override T1 series numbers",
    )
    parser.add_argument(
        "--t2_series",
        action="store",
        nargs="*",
        type=int,
        default=None,
        help="Override T2 series numbers",
    )
    parser.add_argument(
        "--mt_series",
        action="store",
        nargs="*",
        type=int,
        default=None,
        help="Override MT series numbers",
    )
    parser.add_argument(
        "--test_series",
        action="store",
        nargs="*",
        type=int,
        default=None,
        help="Override test series numbers",
    )
    parser.add_argument(
        "--pe1_series",
        action="store",
        nargs="*",
        type=int,
        default=None,
        help="Override PE1 series numbers",
    )

    return parser.parse_args()


def main():
    args = parse_arguments()

    if args.user is None:
        raise ValueError(
            "SUNet ID user argument not defined, please do so with the --user flag!"
        )

    series_overrides = {}
    if args.t1_series is not None:
        series_overrides["t1"] = args.t1_series
    if args.t2_series is not None:
        series_overrides["t2"] = args.t2_series
    if args.mt_series is not None:
        series_overrides["mt"] = args.mt_series
    if args.test_series is not None:
        series_overrides["test"] = args.test_series
    if args.pe1_series is not None:
        series_overrides["pe1"] = args.pe1_series

    converter = BIDSConverter(
        user=args.user,
        subid=args.subid,
        fw_session_id=args.exam_num,
        project_dir=args.project_dir,
        fw_group_id=args.fw_group_id,
        fw_project_id=args.fw_project_id,
        task_id=args.task_id,
        experiment_type=args.experiment_type,
        config_file=args.config,
        series_overrides=series_overrides,
    )

    success = converter.run()
    exit(0 if success else 1)


if __name__ == "__main__":
    main()
