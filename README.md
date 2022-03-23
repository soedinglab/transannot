# A transcriptome annotation pipeline
It predicts protein functions, orthologous relationships and biological pathways for the whole newly sequenced transcriptome.
It first performs PLASS to assemble raw sequence reads and uses mmseqs2 reciprocal blast hits to obtain closest homologs.
Based on the functions of homologs, the method infers protein functions.

