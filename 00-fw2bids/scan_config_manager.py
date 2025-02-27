#!/usr/bin/env python3
"""
Scan Config Manager

This module handles loading and merging scan configurations from different sources:
1. Default configurations
2. User configuration files
3. Command-line overrides

It provides a unified configuration interface for the BIDS converter pipeline.
"""

import json, logging, os
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
            self.logger.warning(f"")

            