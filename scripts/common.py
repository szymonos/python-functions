"""
    common.py
    ---------

    This module contains common functions used in other modules.
"""
from datetime import datetime

import numpy as np
import pandas as pd


def df_info(df: pd.DataFrame, clean: bool = False) -> pd.DataFrame:
    """
    Function for analyzing DataFrame.
    :param df: input DataFrame for analysis.
    :param clean: flag for performing initial cleaning of DataFrame.
    :return: DataFrame with analysis.
    """
    start = datetime.now()
    if clean:
        df.fillna(np.nan, inplace=True)  # replace None with np.nan
        df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)  # trim spaces
        df = df.replace('', np.nan)
    dnull = dict([(v, df[v].isna().any()) for v in df.columns.values])
    dcnt = dict([(v, len(df[v].dropna())) for v in df.columns.values])
    dunicode = dict(
        [(v, df[v].apply(lambda r: len(r) != len(r.encode()) if type(r) == str else False).any())
         for v in df.columns.values
         if (df[v].notna().any() and df[v].dtypes == 'object')]
    )
    dmin = dict(
        [(v, df[v].min())
         for v in df.columns.values
         if (df[v].notna().any() and df[v].dtypes not in ['object', 'float64'])]
    )
    dmax = dict(
        [(v, df[v].max())
         for v in df.columns.values
         if (df[v].notna().any() and df[v].dtypes not in ['object', 'float64'])]
    )
    dmin.update(dict(
        [(v, int(df[v].min()))
         for v in df.columns.values
         if (df[v].notna().any() and df[v].dtypes == 'float64')]
    ))
    dmax.update(dict(
        [(v, int(df[v].max()))
         for v in df.columns.values
         if (df[v].notna().any() and df[v].dtypes == 'float64')]
    ))
    dmin.update(dict(
        [(v, int(df[v].apply(lambda r: len(str(r)) if r is not np.nan else np.nan).min()))
         for v in df.columns.values
         if (df[v].notna().any() and df[v].dtypes == 'object')]
    ))
    dmax.update(dict(
        [(v, int(df[v].apply(lambda r: len(str(r)) if r is not np.nan else np.nan).max()))
         for v in df.columns.values
         if (df[v].notna().any() and df[v].dtypes == 'object')]
    ))
    dmode = dict(
        [(v, df[v].mode()[0])
         for v in df.columns.values
         if (df[v].notna().any() and not df[v].is_unique)]
    )
    dmodecnt = dict(
        [(v, len(df[df[v] == df[v].mode()[0]]))
         for v in df.columns.values
         if df[v].notna().any()]
    )
    dunique = dict(
        [(v, len(df[v].unique()))
         for v in df.columns.values
         if df[v].notna().any()]
    )
    desc = pd.DataFrame({'types': df.dtypes})
    desc['isnull'] = pd.Series(dnull)
    desc['count'] = pd.Series(dcnt)
    desc['isunicode'] = pd.Series(dunicode)
    desc['min'] = pd.Series(dmin)
    desc['max'] = pd.Series(dmax)
    desc['mode'] = pd.Series(dmode)
    desc['mode_cnt'] = pd.Series(dmodecnt).astype('Int64')
    desc['uniq_cnt'] = pd.Series(dunique).astype('Int64')
    print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
    return desc
