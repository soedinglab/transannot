#!/usr/bin/env python
from re import search
import numpy as np
import sys, requests
import pandas as pd

# BASE = 'http://www.uniprot.org'
# KB_ENDPOINT = '/uniprot/'
# TOOL_ENDPOINT = '/uploadlists/'hDB

# def map_retrieve(ids2map, source_fmt='ACC+ID',target_fmt='ACC', output_fmt='tab'):
#     ids2map = ','.join(ids2map)
#     if np.size(ids2map)!=0:
#         # ids2map = ' '.join(ids2map)
#         payload = { 'query': ids2map,
#                     'from': source_fmt,
#                     'to': target_fmt,
#                     'columns': 'id,go-id,database(interpro),database(PDB),database(pfam)', # we can add whichever database resources we want
#                     'format': output_fmt,
#                     }

#     response = requests.get(BASE + TOOL_ENDPOINT, params=payload)

#     if response.ok:
#         return response.text
#     else:
#         response.raise_for_status()

# uniprot_ids = open(sys.argv[-1], "r").read()
search_res = pd.read_csv(sys.argv[-1], header=None, sep='\t')
search_res = search_res[search_res.iloc[:,11]>50]
print(search_res)
print(type(search_res))
# uniprot_ids = open(sys.argv[-1], "r").read().splitlines() #command line arguments passed to script -> only one input in the script
# print(uniprot_ids)

def statistics(c, ident, df=search_res):
    print(ident)
    print(df.iloc[:,c])
    print(np.median(df.iloc[:,c]))
    print(np.min(df.iloc[:,c]))
    print(np.max(df.iloc[:,c]))

# statistics(2, 'seq_ident')
# statistics(10, 'E-value')
# statistics(11, 'bit score')

# search_res = search_res.sort_values([search_res.iloc[:,11],search_res.iloc[:,0]], ascending=False)
search_res = search_res.groupby(search_res.iloc[:,0], axis = 0)[search_res.iloc[:,11]].max()
# search_res = search_res.groupby(search_res.iloc[:,0])[search_res.iloc[:,11]].max()
print(search_res)
# query_ids=set(search_res.iloc[:,0])
# for i in query_ids:
#     print(i)
#     print(search_res[search_res.iloc[:,0]==i])
#     new_rows = search_res[search_res.iloc[:,0]==i].sort_values(by=[search_res.iloc[:,11]], ascending=False).groupby(search_res.iloc[:,0])

# uniprot_acc = map_retrieve(uniprot_ids, source_fmt='ACC+ID')
# print(uniprot_acc)
# sys.stdout.write(str(uniprot_acc)+'\n')


