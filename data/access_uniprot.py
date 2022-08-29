#!/usr/bin/env python
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
uniprot_ids = pd.read_csv(sys.argv[-1], header=None, sep='\t')
print(uniprot_ids)
print(type(uniprot_ids))
# uniprot_ids = open(sys.argv[-1], "r").read().splitlines() #command line arguments passed to script -> only one input in the script
# print(uniprot_ids)

seq_ident = uniprot_ids.iloc[:,2]
print("seq_ident:")
print(seq_ident)
print(np.median(seq_ident))

# uniprot_acc = map_retrieve(uniprot_ids, source_fmt='ACC+ID')
# print(uniprot_acc)
# sys.stdout.write(str(uniprot_acc)+'\n')


