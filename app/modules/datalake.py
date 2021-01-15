"""
datalake.py.

This module contains the DataLakeService class that implements
service methods for Azure DataLake.
"""
import io
import logging
import os
from datetime import datetime
from typing import List

import pandas as pd
from azure.core.exceptions import ResourceExistsError, ResourceNotFoundError
from azure.storage.filedatalake import DataLakeServiceClient, FileSystemClient
from configuration import DL


class DataLakeService:
    """Shared class for Azure DataLake service."""

    def __init__(self, container_name: str) -> None:
        """Initialize class."""
        self._container_name = container_name
        self._data_lake_service = create_datalake_service_client()
        self._container = self.get_datalake_container()

    def get_datalake_container(self) -> FileSystemClient:
        """Get a client to interact with the specified file system."""
        try:
            filesystem_client = self._data_lake_service.create_file_system(
                file_system=self._container_name
            )
        except ResourceExistsError:
            filesystem_client = self._data_lake_service.get_file_system_client(
                self._container_name
            )
        return filesystem_client

    def append_data(self, dir_name: str, file_name: str, data: bytes) -> None:
        """Append data to the file."""
        dir_client = self._container.get_directory_client(dir_name)
        file_client = dir_client.get_file_client(file_name)
        offset: int = 0
        try:
            offset = file_client.get_file_properties().size
        except ResourceNotFoundError:
            logging.info("%s append_data: File %s not found", self.__class__, file_name)
            file_client = dir_client.create_file(file_name)
        file_client.append_data(data, offset, len(data))
        file_client.flush_data(len(data) + offset)

    def save_data(self, data: bytes, file_name: str, metadata: dict = None) -> None:
        """Upload data to a file."""
        file_dir = "/".join(file_name.split("/")[:-1])
        file_name = file_name.split("/")[-1]
        directory_client = self._container.get_directory_client(file_dir)
        directory_client.create_directory()
        file_client = directory_client.get_file_client(file_name)
        file_client.upload_data(data, overwrite=True, metadata=metadata)

    def save_dataframe(
        self,
        df: pd.DataFrame,
        file_name: str,
        cols=None,
        metadata: dict = None,
        sep=",",
    ) -> None:
        """Save DataFrame to file."""
        start = datetime.now()
        content = df.to_csv(columns=cols, index=False, sep=sep)
        self.save_data(content, file_name, metadata)
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")

    def get_data(self, file_name: str) -> bytes:
        """Read content from the file."""
        file_client = self._container.get_file_client(file_name)
        return file_client.download_file().readall()

    def get_file_metadata(self, file_name: str) -> dict:
        """Return all user-defined metadata."""
        file_client = self._container.get_file_client(file_name)
        return file_client.get_file_properties().metadata

    def add_file_metadata(self, file_name: str, metadata: dict) -> None:
        """Set one or more user-defined name-value pairs to file."""
        file_client = self._container.get_file_client(file_name)
        file_metadata = file_client.get_file_properties().metadata
        # Remove hdi_isfolder metadata key which cannot be set
        try:
            del file_metadata["hdi_isfolder"]
        except KeyError:
            pass
        file_client.set_metadata({**file_metadata, **metadata})

    def get_dataframe(
        self,
        file_name: str,
        index_col: List[str] = None,
        usecols: list = None,
        dtype: object = None,
        sep: str = ",",
        quoting: int = 0,
        verbose: bool = False,
    ) -> pd.DataFrame:
        """Load csv file content into DataFrame."""
        start = datetime.now()
        content = self.get_data(file_name).decode()
        df = pd.read_csv(
            io.StringIO(content),
            sep=sep,
            index_col=index_col,
            usecols=usecols,
            dtype=dtype,
            quoting=quoting,
            verbose=verbose,
        )
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
        return df

    def refresh_dictionary(self, df: pd.DataFrame, cols: list, file_name: str) -> None:
        """Add new keys to dictionary files."""
        start = datetime.now()
        try:
            old_data = self.get_dataframe(
                file_name=file_name, index_col=cols[0], usecols=cols
            )
        except ResourceNotFoundError:
            old_data = pd.DataFrame()
        old_data = old_data.append(df[cols].set_index(cols[0]))
        old_data = old_data[~old_data.index.duplicated(keep="last")]
        old_data.reset_index(inplace=True)
        self.save_dataframe(old_data, file_name)
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")

    def merge_dataframes(
        self, df_full: pd.DataFrame, df_updated: pd.DataFrame, file_name: str
    ) -> None:
        """
        Merge dataframes using index and saves result in specified file.

        Dataframes need to have unique, joinable indexes.
        :param df_full: original, full dataframe.
        :param df_updated: dataframe with updated rows.
        :param file_name: name of destination file.
        """
        start = datetime.now()
        df_full = df_full.append(df_updated)
        df_full = df_full[~df_full.index.duplicated(keep="last")]
        df_full.reset_index(inplace=True)
        self.save_dataframe(df_full, file_name)
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")

    def get_files_list(self, dir_name: str) -> list:
        """Get file paths from specified directory ordered by modified date."""
        paths = self._container.get_paths(dir_name)
        try:
            df = [
                {"name": x.name, "last_modified": x.last_modified}
                for x in paths
                if x.is_directory is False
            ]
            lst = (pd.DataFrame(df).sort_values(by="last_modified"))["name"].to_list()
        except (AttributeError, KeyError):
            lst = list()
        return lst

    def get_directories_list(self, dir_name: str) -> list:
        """Get subdirectories of specified directory ordered by modified date."""
        paths = self._container.get_paths(dir_name)
        try:
            df = [
                {"name": x.name, "last_modified": x.last_modified}
                for x in paths
                if x.is_directory is True
            ]
            lst = (pd.DataFrame(df).sort_values(by="last_modified"))["name"].to_list()
        except (AttributeError, KeyError):
            lst = list()
        return lst

    def rename_dir(
        self,
        file_name: str,
        rename_from: str = "incoming",
        rename_to: str = "processed",
    ) -> None:
        """Rename directory incoming to processed."""
        # pylint: disable=expression-not-assigned
        try:
            self._container.get_directory_client(
                file_name
            ).get_directory_properties().metadata["hdi_isfolder"]
            file_dir = file_name
        except KeyError:
            file_dir = os.path.dirname(file_name)
        directory_client = self._container.get_directory_client(file_dir)
        dest_dir = file_dir.replace(rename_from, rename_to)
        directory_client_dest = self._container.get_directory_client(dest_dir)
        directory_client_dest.create_directory()
        directory_client.rename_directory(
            f"{directory_client.file_system_name}/{dest_dir}"
        )

    def rename_file(self, file_name: str, rename_from: str, rename_to: str) -> None:
        """Rename file path in Azure Storage DataLake."""
        # pylint: disable=expression-not-assigned
        try:
            self._container.get_directory_client(
                file_name
            ).get_directory_properties().metadata["hdi_isfolder"]
            logging.error("%s is a directory, not a file", file_name)
            return
        except KeyError:
            pass
        file_client = self._container.get_file_client(file_name)
        dest_file = file_name.replace(rename_from, rename_to)
        dest_dir = os.path.dirname(dest_file)
        directory_client_dest = self._container.get_directory_client(dest_dir)
        directory_client_dest.create_directory()
        file_client.rename_file(f"{file_client.file_system_name}/{dest_file}")

    def delete_directory(self, dir_name: str) -> None:
        """Return paths to subdirectories in specified directory."""
        self._container.delete_directory(dir_name)


def create_datalake_service_client() -> DataLakeServiceClient:
    """Return DataLake Service Clien."""
    account_name = DL.STORAGE_ACCOUNT_NAME
    credential = DL.STORAGE_ACCOUNT_KEY
    account_url = f"https://{account_name}.dfs.core.windows.net/"
    datalake_service = DataLakeServiceClient(
        account_url=account_url, credential=credential
    )
    return datalake_service


def dictionary_dataframe_from_dataframe(df: pd.DataFrame, cols: list) -> pd.DataFrame:
    """Remove duplicates on specified columns in DataFrame."""
    result_df = df[cols].drop_duplicates()
    result_df.set_index(cols[0], inplace=True)
    return result_df
