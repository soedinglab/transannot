# A transcriptome annotation pipeline
It predicts protein functions, orthologous relationships and biological pathways for the whole newly sequenced transcriptome.
It first performs PLASS (Protein-Level ASSembler) to assemble raw sequence reads on protein level and uses MMseqs2 reciprocal best hit to obtain closest homologs.
Based on the functions of homologs, the pipeline infers protein functions.

> to install default DataBase type:
`annotate downloaddb UniProtKB `