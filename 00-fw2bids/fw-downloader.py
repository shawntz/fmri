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
    --fw_api_key_file: Path to text file containing your Flywheel CLI API key (defaults to user's HOME directory)
"""

import argparse
import os
import logging
from typing import Tuple, Optional


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Download zipped images from flywheel.')
    parser.add_argument('--user', action='store', help='Your SUNet ID, e.g., johndoe')
    parser.add_argument('--fw_subject_id', action='store', 
                       help='Identify subject id used for GE scan session, e.g., Y001')
    parser.add_argument('--fw_session_id', action='store', 
                       help='Identify GE scan session id, e.g., 25901')
    parser.add_argument('--fw_api_key_file', action='store', 
                       default='flywheel_api_key.txt',
                       help='Filename with Flywheel CLI API key within user HOME dir')
    return parser.parse_args()

def main():
    args = parse_arguments()

    if args.user is None:
        raise ValueError("SUNet ID user argument not defined, please do so with the --user flag!")
    
    # todo: implement downloader class and create instance here...

if __name__ == "__main__":
    main()
