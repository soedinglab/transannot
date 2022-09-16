#!/usr/bin/env python

import numpy as np
import sys, requests
import pandas as pd
from io import StringIO
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
    'from': (None, 'UniProtKB_AC-ID'),
    'to': (None, 'UniRef90'),
    'ids': (None,','.join(search_res['seqDBID'].to_list())),
}

response = requests.post('https://rest.uniprot.org/idmapping/run', files=ids_request)
url=response.json()

# without stream
url_req='https://rest.uniprot.org/idmapping/uniref/results/'+url['jobId']+'?format=tsv'
acc = requests.get(url_req)
# print(type(acc.content))
data=acc.content
data=data.decode("utf-8")

data_input=StringIO(data)
mapping_res=pd.read_csv(data_input, sep='\t')
data=search_res.merge(mapping_res, left_on='seqDBID', right_on='From', how='outer').drop(['From','Date of creation'], axis=1)
print(data)
