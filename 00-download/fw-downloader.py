#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Handler for downloading zipped MRI acquisitions from Flywheel.

@Author: Shawn Schwartz - Stanford Memory Lab
@Date: February 20, 2025
@Dependencies: Python 3.9+
@Usage: Called by xyz.sh as part of the preprocessing pipeline

Arguments:
    --user: Stanford SUNet ID (for authentication)
    --fw_subject_id: Subject identifier entered on the control console
    --fw_session_id: Scan session identifier located next to subject id on Flywheel
    --fw_project_id: Flywheel Project ID (e.g., amass)
    --fw_instance_url: URL/server address of Flywheel Instance (e.g., cni.flywheel.io)
    --fw_group_id: Flywheel group ID (i.e., parent dir of all project IDs, fw://surname)
    --fw_api_key_file: Path to text file containing your Flywheel CLI API key (defaults to user's HOME directory)
"""

import argparse
import os
import logging
from typing import Tuple


class FlywheelDownloader:
    """A class to handle transfering data from Flywheel to another server."""

    def __init__(self, user: str, fw_subject_id: str, fw_session_id: str,
                 fw_project_id: str, fw_instance_url: str, fw_group_id: str,
                 fw_api_key_file: str = 'flywheel_api_key.txt'):
        self.user = user
        self.fw_subject_id = fw_subject_id
        self.fw_session_id = fw_session_id
        self.fw_project_id = fw_project_id
        self.fw_instance_url = fw_instance_url
        self.fw_group_id = fw_group_id
        self.fw_api_key_file = fw_api_key_file
        self.logger = self._setup_logger()

    def _setup_logger(self) -> logging.Logger:
        logger = logging.getLogger('flywheel_downloader')
        logger.setLevel(logging.INFO)
        formatter = logging.Formatter('[%(levelname)s] - %(message)s')

        handler = logging.StreamHandler()
        handler.setFormatter(formatter)
        logger.addHandler(handler)

        return logger

    def _get_api_key(self) -> str:
        fw_api_key_path = f'{self.fw_api_key_file}'

        try:
            with open(fw_api_key_path, 'r') as fw_file:
                return fw_file.read().rstrip()
        except FileNotFoundError:
            self.logger.error(f"Flywheel CLI API key file not found at {fw_api_key_path}")
            raise

    def login_to_fw(self) -> bool:
        try:
            fw_api_key = self._get_api_key()
            self.logger.info(f"Attempting Flywheel login for user {self.user}")

            fw_path_os_cmd = f'$HOME/flywheel/cli/fw login {self.fw_instance_url}:{fw_api_key}'
            self.logger.info(f"Executing: {fw_path_os_cmd}")

            return os.system(fw_path_os_cmd)
        except Exception as e:
            self.logger.error(f"Login attempt to {self.fw_instance_url} failed: {str(e)}")
            return False

    def make_directories(self) -> Tuple[str, str, str]:
        dir_scratch = f'/scratch/users/{self.user}/fw_{self.fw_session_id}'
        dir_nifti = f'{dir_scratch}/niftis'
        dir_dicom = f'{dir_scratch}/dicoms'

        for dir in [dir_scratch, dir_nifti, dir_dicom]:
            if not os.path.exists(dir):
                os.makedirs(dir)
                self.logger.info(f"Created directory: {dir}")

        return dir_scratch, dir_nifti, dir_dicom

    def download(self, data_type: str, output_dir: str) -> bool:
        try:
            cmd = ('$HOME/flywheel/cli/fw download '
                  f'{self.fw_group_id}/{self.fw_project_id}/{self.fw_subject_id}/{self.fw_session_id} '
                  f'-i {data_type} '
                  f'-o {output_dir}/{self.fw_session_id}.tar')

            self.logger.info(f"Downloading {data_type} files...")
            self.logger.info(f"Executing: {cmd}")

            return os.system(cmd) == 0
        except Exception as e:
            self.logger.error(f"{data_type} download failed: {str(e)}")
            return False

    def run(self) -> bool:
        try:
            if not self.login_to_fw():
                return False

            _, dir_nifti, dir_dicom = self.make_directories()
            print("directories made")

            print("now at nift")
            if not self.download('nifti', dir_nifti):
                print("nifti err")
                return False
            print("made it out of nift")
            if not self.download('dicom', dir_dicom):
                return False

            self.logger.info("Flywheel Downloader workflow completed successfully!")
            return True
        except Exception as e:
            self.logger.error(f"Flywheel Downloader workflow failed: {str(e)}")
            return False

def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Download zipped images from flywheel.')
    parser.add_argument('--user', action='store', help='Your SUNet ID, e.g., johndoe')
    parser.add_argument('--fw_subject_id', action='store',
                       help='Identify subject id used for GE scan session, e.g., Y001')
    parser.add_argument('--fw_session_id', action='store',
                       help='Identify GE scan session id, e.g., 25901')
    parser.add_argument('--fw_project_id', action='store',
                       help='Flywheel Project ID (e.g., amass)')
    parser.add_argument('--fw_instance_url', action='store',
                       help='URL/server address of Flywheel Instance (e.g., cni.flywheel.io)')
    parser.add_argument('--fw_group_id', action='store',
                       help='Flywheel group ID (i.e., parent dir of all project IDs, fw://surname)')
    parser.add_argument('--fw_api_key_file', action='store',
                       default='flywheel_api_key.txt',
                       help='Filename with Flywheel CLI API key within user HOME dir')
    return parser.parse_args()

def main():
    args = parse_arguments()

    if args.user is None:
        raise ValueError("SUNet ID user argument not defined, please do so with the --user flag!")

    if args.fw_subject_id is None:
        raise ValueError("Flywheel subject ID argument not defined, please do so with the --fw_subject_id flag!")

    if args.fw_session_id is None:
        raise ValueError("Flywheel session ID argument not defined, please do so with the --fw_session_id flag!")

    if args.fw_project_id is None:
        raise ValueError("Flywheel project ID argument not defined, please do so with the --fw_project_id flag!")

    if args.fw_instance_url is None:
        raise ValueError("Flywheel instance server URL argument not defined, please do so with the --fw_instance_url flag!")

    if args.fw_group_id is None:
        raise ValueError("Flywheel group ID argument not defined, please do so with the --fw_group_id flag!")

    if args.fw_api_key_file is None:
        raise ValueError("Flywheel API key file path argument not defined, please do so with the --fw_api_key_file flag!")

    fw_downloader = FlywheelDownloader(
        user=args.user,
        fw_subject_id=args.fw_subject_id,
        fw_session_id=args.fw_session_id,
        fw_project_id=args.fw_project_id,
        fw_instance_url=args.fw_instance_url,
        fw_group_id=args.fw_group_id,
        fw_api_key_file=args.fw_api_key_file
    )

    success = fw_downloader.run()
    exit(0 if success else 1)

if __name__ == "__main__":
    main()
