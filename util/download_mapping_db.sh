#!/bin/sh -e

#download & extract
wget https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping/idmapping.dat.gz
gzip -d idmapping.dat.gz

#remove duplicates
awk '!seen[$3]++' idmapping.dat >> idmapping_prefilt.dat
rm -f idmapping.dat
