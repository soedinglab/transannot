#!/usr/bin/env python

import pandas as pd
import sys

prof_db = pd.read_csv(sys.argv[-3], sep='\t', usecols=[0,1], names=['query','target'])
pfam_db = pd.read_csv(sys.argv[-2], sep='\t', usecols=[0,4], names=['id','clan_name'])
prof_db.drop(prof_db.tail(1).index,inplace=True)
prof_id = prof_db['target']

pfamidsdict=pfam_db.set_index('id')['clan_name'].to_dict()
prof_db['clan_name']=""
sep='.'
for i in range(len(prof_id)):
    newid=prof_id[i].split(sep, 1)[0]
    try:
        prof_db.iloc[i,2]=pfamidsdict[newid]
    except:
        prof_db.iloc[i,2]='None'


prof_db.to_csv(sys.argv[-1], sep='\t', index=False)