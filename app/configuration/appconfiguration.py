"""
appconfiguration.py.

This module contains get_appcf_settings function.
"""
import json
import os
from pathlib import Path

from azure.appconfiguration import AzureAppConfigurationClient
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


def get_appcf_settings(key_filter: str, label_filter: str) -> dict:
    """Get specified app configurations."""
    base_url = os.environ["APPCF_ENDPOINT"]
    credential = DefaultAzureCredential()
    client = AzureAppConfigurationClient(base_url, credential)
    filtered_listed = client.list_configuration_settings(key_filter, label_filter)
    config = dict()
    for item in filtered_listed:
        if (
            item.content_type
            == "application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8"
        ):
            url_parts = Path(json.loads(item.value)["uri"]).parts
            kv_client = SecretClient(
                vault_url="//".join(url_parts[:2]), credential=credential
            )
            secret_value = kv_client.get_secret(url_parts[-1]).value
            config.update({item.key: secret_value})
        else:
            config.update({item.key: item.value})
    return config
