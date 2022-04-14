# A transcriptome annotation pipeline
It predicts protein functions, orthologous relationships and biological pathways for the whole newly sequenced transcriptome.
It first performs PLASS (Protein-Level ASSembler) to assemble raw sequence reads on protein level and uses MMseqs2 reciprocal best hit to obtain closest homologs.
Based on the functions of homologs, the pipeline infers protein functions.

## Input
Possible inputs are:

* assembled (e.g. with Trinity) transcriptomes
* non-assembled transcriptomes, which will be assembled with `plass`
* metatranscriptomes
* single-organism transcriptomes, in such case it is possible to check for the contamonation based on MMseqs2 taxonomy with `contamination` module

## Running

### Modules

* `assembly`            Assemble ...
* `annotate`            Annotate with rbh ...
* `contamination`       Check for the contamination with `mmseqs taxonomy`
* `downloaddb`          Download database to search against