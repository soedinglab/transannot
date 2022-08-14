import sys, requests
import pandas as pd

API_URL = "https://rest.uniprot.org"
session = requests.Session()
def submitmapping(fromdb, todb, ids2map):

    request=requests.post(
        f"{API_URL}/idmapping/run",
        data={"from":fromdb, "to":todb, "ids":",".join(ids2map)},
    )
    request.raise_for_status()
    return request.json()["jobId"]

def checkmappingresults(jobid):
    while True:
        request=session.get(f"{API_URL}/idmapping/status{jobid}")
        request.raise_for_status()
        js = request.json()
        for jobStatus in js:
            if js[jobStatus] == "RUNNING":
                print()

#many inputs of script: fromDB to map is 2nd input sys.argv[0] is a script name
i_fromdb=sys.argv[2]
i_ids2map = pd.read_csv(sys.argv[1], index_col=False).to_numpy()