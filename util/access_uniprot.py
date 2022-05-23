#!/usr/bin/env python

import requests, sys, json

website_api = "https://rest.uniprot.org/beta"

def get_url(url, **kwargs):
    response = requests.get(url, **kwargs);
    
    if not response.ok:
        print(response.text)
        response.raise_for_status()
        sys.exit()
    
    return(response)
  
r = get_url(f"{website_api}/uniprotkb/search?query=P04637")
data = r.json()
go_id = data['results'][0]['uniProtKBCrossReferences']['database'=='GO']['id']
