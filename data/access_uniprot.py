#!/usr/bin/env python
from re import search
import numpy as np
import sys, requests
import pandas as pd

BASE = 'http://www.uniprot.org'
KB_ENDPOINT = '/uniprot/'
TOOL_ENDPOINT = '/uploadlists/'

def map_retrieve(ids2map, source_fmt='ACC+ID',target_fmt='ACC', output_fmt='tab'):
    ids2map = ','.join(ids2map)
    if np.size(ids2map)!=0:
        # ids2map = ' '.join(ids2map)
        payload = { 'query': ids2map,
                    'from': source_fmt,
                    'to': target_fmt,
                    'columns': 'id,go-id,database(interpro),database(PDB),database(pfam)', # we can add whichever database resources we want
                    'format': output_fmt,
                    }

    response = requests.get(BASE + TOOL_ENDPOINT, params=payload)

    if response.ok:
        return response.text
    else:
        response.raise_for_status()

# uniprot_ids = open(sys.argv[-1], "r").read()
# map_db = pd.read_csv(sys.argv[-1], header=None, sep=r'\s{2,}')
# print(map_db)

search_res = pd.read_csv(sys.argv[-1], header=None, sep='\t')
# map_db.to_dict()
# uniprot_ids = open(sys.argv[-1], "r").read().splitlines() #command line arguments passed to script -> only one input in the script
# print(uniprot_ids)

def statistics(c, ident, df=search_res):
    print(ident)
    print(df.iloc[:,c])
    print(np.median(df.iloc[:,c]))
    print(np.min(df.iloc[:,c]))
    print(np.max(df.iloc[:,c]))

uniprot_acc = map_retrieve(search_res.iloc[:,1], source_fmt='ACC+ID')
print(uniprot_acc)
# sys.stdout.write(str(uniprot_acc)+'\n')


