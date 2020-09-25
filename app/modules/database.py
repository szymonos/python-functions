""" dist/sqlalchemy.py """
import logging
import os
from datetime import datetime
from typing import TypeVar
from urllib import parse

import pandas as pd
import sqlalchemy as db
from pyodbc import OperationalError
from retrying import retry
from sqlalchemy import Table, create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import scoped_session, sessionmaker

StrList = TypeVar('StrList', str, list)


def retry_if_operational_error(exception):
    """Return True if retry on OperationalError, False otherwise"""
    return isinstance(exception, OperationalError)


class DbCdp:
    """Methods for database handling using SQLAlchemy."""

    def __init__(self):
        self.__conn_str = str(os.getenv('CONNSTR_DB'))
        self.engine = self.get_engine()

    def get_engine(self) -> Engine:
        """Create engine used for connecting to database."""
        params = parse.quote_plus(self.__conn_str)
        engine = create_engine(
            "mssql+pyodbc:///?odbc_connect=%s" % params,
            pool_use_lifo=True,
            pool_pre_ping=True,
            fast_executemany=True
        )
        return engine

    def get_table(self, table: str) -> Table:
        """Get table definition from database."""
        start = datetime.now()
        sch_tbl = table.split('.')
        if len(sch_tbl) == 1:
            sch_tbl += sch_tbl
            sch_tbl[0] = 'dbo'
        metadata = db.MetaData()
        table = Table(
            sch_tbl[1],
            metadata,
            schema=sch_tbl[0],
            autoload=True,
            autoload_with=self.engine
        )
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
        return table

    def execute_query(self, query: str) -> None:
        """Execute sql procedure that returns nothing."""
        start = datetime.now()
        db_session = scoped_session(sessionmaker(bind=self.engine))
        try:
            db_session.execute(text(query))
            db_session.commit()
        except Exception:
            logging.exception('Exception occurred')
            db_session.rollback()
        db_session.remove()
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")

    @retry(retry_on_exception=retry_if_operational_error, stop_max_attempt_number=5, wait_fixed=500)
    def read_query(
        self,
        query: db.select,
        index_col: StrList = None
    ) -> pd.DataFrame:
        """Execute sql query that return rows."""
        start = datetime.now()
        df = pd.DataFrame()
        try:
            df = pd.read_sql_query(sql=query, index_col=index_col, con=self.engine)
        except OperationalError:
            logging.exception('Exception occurred')
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
        return df

    @retry(retry_on_exception=retry_if_operational_error, stop_max_attempt_number=5, wait_fixed=500)
    def read_table(
        self,
        table: str,
        columns: list = None,
        index_col: StrList = None
    ) -> pd.DataFrame:
        """Read sql table (slower than read_query)."""
        start = datetime.now()
        sch_tbl = table.split('.')
        if len(sch_tbl) == 1:
            sch_tbl += sch_tbl
            sch_tbl[0] = 'dbo'
        df = pd.DataFrame()
        try:
            df = pd.read_sql_table(
                table_name=sch_tbl[1],
                schema=sch_tbl[0],
                columns=columns,
                index_col=index_col,
                con=self.engine
            )
        except OperationalError:
            logging.exception('Exception occurred')
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
        return df

    @retry(retry_on_exception=retry_if_operational_error, stop_max_attempt_number=5, wait_fixed=500)
    def write_table(
        self,
        table: str,
        df: pd.DataFrame,
        if_exists: str = 'append'
    ) -> None:
        """Insert data into table using pandas."""
        start = datetime.now()
        sch_tbl = table.split('.')
        if len(sch_tbl) == 1:
            sch_tbl += sch_tbl
            sch_tbl[0] = 'dbo'
        try:
            df.to_sql(
                name=sch_tbl[1],
                schema=sch_tbl[0],
                con=self.engine,
                index=False,
                chunksize=50000,
                if_exists=if_exists
            )
        except OperationalError:
            logging.exception('Exception occurred')
        print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")

    def dispose(self) -> None:
        """Close existing connections in database."""
        self.engine.dispose()
