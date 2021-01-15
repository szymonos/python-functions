"""
config.py.

This module contains app configuration.
"""
import os

from configuration import get_appcf_settings

ENV_NAME = os.environ["ENV_STATE"]


class DB:
    """DB configuration."""

    # pylint: disable=too-few-public-methods
    config = get_appcf_settings("ConnectionStrings:DbOdbc", ENV_NAME)

    CONNSTR_DB = config["ConnectionStrings:DbOdbc"]


class DL:
    """DataLake configuration."""

    # pylint: disable=too-few-public-methods
    config = get_appcf_settings("DataLake:*", ENV_NAME)

    STORAGE_ACCOUNT_KEY = config["DataLake:AccountKey"]
    STORAGE_ACCOUNT_NAME = config["DataLake:AccountName"]
