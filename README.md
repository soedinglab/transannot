# TransAnnot - a transcriptome annotation pipeline
It predicts protein functions, orthologous relationships and biological pathways for the whole newly sequenced transcriptome.
It first performs PLASS (Protein-Level ASSembler) to assemble raw sequence reads on protein level and uses MMseqs2 reciprocal best hit to obtain closest homologs.
Based on the functions of homologs, the pipeline infers protein functions.

## Input
Possible inputs are:

* assembled (e.g. with Trinity) transcriptomes
* non-assembled transcriptomes, which will be assembled on protein level with `plass`
* metatranscriptomes
* single-organism transcriptomes, in such case it is possible to check for the contamination with `contamination` module, which is based on MMseqs2 taxonomy workflow

## Running

### about tmp

`tmp` is a folder to keep temporary files. By the default all the intermediate outputs will be kept in this folder after running each module. To clear tmp pass `--remove-tmp-files` parameter.

### Modules

* `assembly`            Assemble ...
* `annotate`            Annotate with rbh ...
* `contamination`       Check for the contamination with `mmseqs easy-taxonomy`
* `createdb`            Create mmseqs database from the sequence, which was not assembled with transannot assembly
* `downloaddb`          Download database to search against

### Dowloading databases

In this step database to search against will be downloaded.
Default database is UniProtKB, so if you want to download this database simply run:

    transannot downloaddb UniProtKB <outDB> <tmp> [options]
    
However, if you would like to download other databases, run:

    mmseqs databases -h

for an extended information about the databases that can be downloaded. 
Possible databases are for example Swiss-Prot and PDB. 

Then run:

    transannot downloaddb <selection> <outDB> <tmp> [options]

### Annotate workflow

Calling `annotate -h` returns details on what type of information about sequence user may get using annotate module. 

### Contamination

Contamination module checks for the contamination in a given data. It uses mmseqs `easy-taxonomy` module. As target DB you may use the database, that was downloaded to run annotation. To run:

    transannot contamination <Input.fasta> <targetDB> <outpath> <tmp> [options]
 
You can find the taxonomy report in <outPath>.
