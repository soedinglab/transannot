#!/usr/bin/env python

import numpy as np
import sys, requests
import pandas as pd
# from re import search

# BASE = 'http://www.uniprot.org'
# KB_ENDPOINT = '/uniprot/'
# TOOL_ENDPOINT = '/uploadlists/'

# def map_retrieve(ids2map, source_fmt='ACC+ID',target_fmt='ACC', output_fmt='tab'):
#     print(ids2map)
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

search_res = pd.read_csv(sys.argv[-1], names=['queryID','seqDBID'], sep=' ', usecols=[0,1])

ids_request = {
    'from': (None, 'UniProtKB'),
    'to': (None, 'UniProtKB_AC-ID'),
    'ids': (None,','.join(search_res['seqDBID'].to_list())),
}

response = requests.post('https://rest.uniprot.org/idmapping/run', files=ids_request)
# uniprot_acc = map_retrieve(search_res['seqDBID'], source_fmt='ACC+ID')
# print(uniprot_acc)
# # sys.stdout.write(str(uniprot_acc)+'\n')


