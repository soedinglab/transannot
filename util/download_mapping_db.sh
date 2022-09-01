#!/bin/sh -e


wget https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping/idmapping.dat.gz
gzip -d idmapping.dat.gz