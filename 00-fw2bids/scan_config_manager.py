#!/usr/bin/env python3
"""
Scan Config Manager

This module handles loading and merging scan configurations from different sources:
1. Default configurations
2. User configuration files
3. Command-line overrides

It provides a unified configuration interface for the BIDS converter pipeline.
"""

import json
import logging
from typing import Dict, List, Any, Optional


class ScanConfigManager:
    """Manages scan configs for the SML meta-fmriprep preprocessing pipeline.
    """

    def __init__(self, config_file: Optional[str] = None, logger: Optional[logging.Logger] = None):
        self.config_file = config_file
        self.logger = logger or self._setup_logger()
        self.config = self._load_user_config(config_file)

    def _setup_logger(self) -> logging.Logger:
        logger = logging.getLogger('scan_config_manager')
        logger.setLevel(logging.INFO)
        formatter = logging.Formatter('[%s(levelname)s] - %(message)s')

        handler = logging.StreamHandler()
        handler.setFormatter(formatter)
        logger.addHandler(handler)

        return logger

    def _load_user_config(self, config_file: str) -> Dict[str, Any]:
        try:
            with open(config_file, 'r') as f:
                user_config = json.load(f)

            self.logger.info(f"Loaded scanner configuration from {config_file}")

        except (json.JSONDecodeError, IOError) as e:
            self.logger.error(f"Error loading scanner configuration from {config_file}: {str(e)}")

        return user_config

    def apply_command_line_overrides(self, overrides: Dict[str, List[int]]) -> None:
        for seq_name, series_numbers in overrides.items():
            if series_numbers is not None and seq_name in self.config["default_sequences"]:
                self.config["default_sequences"][seq_name]["series_numbers"] = series_numbers
                self.logger.info(f"Applied override for {seq_name}: {series_numbers}")

    def get_sequence_config(self, sequence_name: str) -> Dict[str, Any]:
        if sequence_name in self.config["default_sequences"]:
            return self.config["default_sequences"][sequence_name]
        else:
            return {"series_numbers": [], "required": False, "description": "Unknown sequence"}

    def get_experiment_config(self, experiment_type: str) -> List[str]:
        if experiment_type in self.config["experiment_types"]:
            return self.config["experiment_types"][experiment_type]
        else:
            self.logger.warning(f"Unknown experiment type: {experiment_type}")
            return self.config["experiment_types"].get("basic", [])

    def get_series_numbers(self, sequence_name: str) -> List[int]:
        return self.get_sequence_config(sequence_name).get("series_numbers", [])

    def is_sequence_required(self, sequence_name: str) -> bool:
        return self.get_sequence_config(sequence_name).get("required", False)

    def get_all_sequences(self) -> List[str]:
        return list(self.config["default_sequences"].keys())

    def get_all_experiment_types(self) -> List[str]:
        return list(self.config["experiment_types"].keys())

    def print_config_summary(self) -> None:
        self.logger.info("Current Configuration Summary:")
        self.logger.info("Available sequences:")

        for seq_name, seq_config in self.config["default_sequences"].items():
            required = "Required" if seq_config.get("required", False) else "Optional"
            series = seq_config.get("series_numbers", [])
            desc = seq_config.get("description", "No description")

            self.logger.info(f"  - {seq_name} ({required}): {desc}")
            self.logger.info(f"    Series: {series}")

        self.logger.info("Available experiment types:")
        for exp_name, exp_sequences in self.config["experiment_types"].items():
            self.logger.info(f"  - {exp_name}: {', '.join(exp_sequences)}")


