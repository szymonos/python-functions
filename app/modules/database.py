"""
database.py.

This module contains the DataLakeService class that implements
service methods for Azure DataLake.
"""
import logging
from datetime import datetime
from typing import Dict, List
from urllib import parse

import pandas as pd
import sqlalchemy as db
from retrying import retry
from sqlalchemy import Table, create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import IntegrityError, OperationalError, ProgrammingError
from sqlalchemy.orm import scoped_session, sessionmaker


def retry_if_operational_error(exception):
    """Check if exception is an OperationalError."""
    return isinstance(exception, OperationalError)


class DbApp:
    """
    Methods for database handling using SQLAlchemy.

    :param connstr_var: environment variable name storing odbc sql
        connection string.
    """

    def __init__(self, connstr_var: str) -> None:
        """Initialize class."""
        self.__conn_str = connstr_var
        self.engine = self.get_engine()

    def get_engine(self) -> Engine:
        """Create engine used for connecting to database."""
        params = parse.quote_plus(self.__conn_str)
        engine = create_engine(
            "mssql+pyodbc:///?odbc_connect=%s" % params,
            pool_use_lifo=True,
            pool_pre_ping=True,
            fast_executemany=True,
        )
        return engine

    def get_table(self, table_name: str) -> Table:
        """Get table definition from database."""
        start = datetime.now()
        sch_tbl = table_name.split(".")
        if len(sch_tbl) == 1:
            sch_tbl += sch_tbl
            sch_tbl[0] = "dbo"
        metadata = db.MetaData()
        table = Table(
            sch_tbl[1],
            metadata,
            schema=sch_tbl[0],
            autoload=True,
            autoload_with=self.engine,
        )
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
        return table

    @retry(
        retry_on_exception=retry_if_operational_error,
        stop_max_attempt_number=5,
        wait_fixed=2000,
    )
    def execute_query(self, query: str) -> Dict[str, object]:
        """
        Execute sql query against database.

        :param query: query text.
        :return: dict with Status and Message.
            Status: -1 (succeded); 0 (failed).
            Message: OK (succeded); exception message (failed).
        """
        start = datetime.now()
        db_session = scoped_session(sessionmaker(bind=self.engine))
        try:
            db_session.execute(text(query))
            db_session.commit()
            msg = {"Status": -1, "Message": "OK"}
        except (IntegrityError, ProgrammingError) as ex:
            db_session.rollback()
            logging.exception("Exception occurred")
            msg = {"Status": 0, "Message": str(ex)}
        db_session.remove()
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
        return msg

    @retry(
        retry_on_exception=retry_if_operational_error,
        stop_max_attempt_number=5,
        wait_fixed=2000,
    )
    def read_query(self, query: str, index_col: List[str] = None) -> pd.DataFrame:
        """Execute sql query that return rows."""
        start = datetime.now()
        df = pd.read_sql_query(sql=query, index_col=index_col, con=self.engine)
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
        return df

    @retry(
        retry_on_exception=retry_if_operational_error,
        stop_max_attempt_number=5,
        wait_fixed=2000,
    )
    def read_table(
        self, table: str, columns: list = None, index_col: List[str] = None
    ) -> pd.DataFrame:
        """Read sql table (slower than read_query)."""
        start = datetime.now()
        sch_tbl = table.split(".")
        if len(sch_tbl) == 1:
            sch_tbl += sch_tbl
            sch_tbl[0] = "dbo"
        df = pd.read_sql_table(
            table_name=sch_tbl[1],
            schema=sch_tbl[0],
            columns=columns,
            index_col=index_col,
            con=self.engine,
        )
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
        return df

    def write_table(
        self, table: str, df: pd.DataFrame, if_exists: str = "append"
    ) -> Dict[str, object]:
        """
        Write records stored in a DataFrame to a SQL database.

        :param table: name of SQL table with optional schema name.
        :param df: DataFrame that will be written to the table.
        :param if_exists: how to behave if the table already exists
        :return: dict with Status and Message.
            Status: DataFrame rows count (succeded) or 0 (failed).
            Message: OK (succeded); exception message (failed).
        """
        start = datetime.now()
        sch_tbl = table.split(".")
        if len(sch_tbl) == 1:
            sch_tbl += sch_tbl
            sch_tbl[0] = "dbo"
        try:
            df.to_sql(
                name=sch_tbl[1],
                schema=sch_tbl[0],
                con=self.engine,
                index=False,
                chunksize=10000,
                if_exists=if_exists,
            )
            msg = {"Status": len(df), "Message": "OK"}
        except (IntegrityError, ProgrammingError) as ex:
            logging.exception("Exception occurred")
            msg = {"Status": 0, "Message": str(ex)}
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
        return msg

    def dispose(self) -> None:
        """Close existing connections in database."""
        self.engine.dispose()
