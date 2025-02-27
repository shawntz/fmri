#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Converter for Flywheel raw downloads to BIDS format.

@Author: Shawn Schwartz - Stanford Memory Lab
@Date: February 26, 2025
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
import logging
import os
import shutil
import tarfile
from glob import glob
from pathlib import Path
from typing import List, Optional, Dict, Any


class BIDSConverter:
    """A class to handle converting transferred files from Flywheel to BIDS format."""

    def __init__(self, user: str, subid: str, exam_num: str,
                 t1_series: List[int] = None, t2_series: List[int] = None,
                 mt_series: List[int] = None, test_series: List[int] = None,
                 pe1_series: List[int] = None):
        self.user = user
        self.subid = subid
        self.exam_num = exam_num
        self.t1_series = t1_series
        self.t2_series = t2_series
        self.mt_series = mt_series
        