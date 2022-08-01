#!/usr/bin/env python
import numpy as np
import pandas as pd
import sys, requests

BASE = 'http://www.uniprot.org'
KB_ENDPOINT = '/uniprot/'
TOOL_ENDPOINT = '/uploadlists/'

def map_retrieve(ids2map, source_fmt='ACC+ID',target_fmt='ACC', output_fmt='tab'):
    if hasattr(ids2map, 'pop'):
        ids2map = ' '.join(ids2map)
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

uniprot_ids = pd.read_csv(sys.argv[-1], index_col=False).to_numpy() #command line arguments passed to script -> only one input in the script
print(uniprot_ids)
uniprot_acc = map_retrieve(uniprot_ids, source_fmt='ACC+ID')
sys.stdout.write(str(uniprot_acc)+'\n')
