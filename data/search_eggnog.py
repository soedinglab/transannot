#!/usr/bin/env python

import pandas as pd
import sys

prof_db = pd.read_csv(sys.argv[-3], sep='\t', usecols=[0,1], names=['query','target'])
nog_db = pd.read_csv(sys.argv[-2], sep='\t', usecols=[1,3], names=['id','family_name'])
prof_db.drop(prof_db.tail(1).index,inplace=True)
prof_id = prof_db['target']

nogidsdict=nog_db.set_index('id')['family_name'].to_dict()
prof_db['family_name']=""
for i in range(len(prof_id)):
    try:
        prof_db.iloc[i,2]=nogidsdict[prof_id[i]]
    except:
        prof_db.iloc[i,2]='None'


prof_db.to_csv(sys.argv[-1], sep='\t', index=False)