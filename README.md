# TransAnnot: a fast transcriptome annotation pipeline
TransAnnot is a toolkit designed to predict protein functions, identify orthologous relationships, and decipher biological pathways for newly sequenced transcriptomes. Utilizing [MMseqs2's](https://mmseqs.com) fast sequence-sequence and sequence-profile search, it identifies the closest homologs from reference databases to infer essential details such as protein function, structure, and orthologous groups.

Optionally, TransAnnot can use [Plass](https://github.com/soedinglab/plass) for transcriptome assembly, enabling *de novo* assembly of raw sequence reads at the protein level.

TransAnnot is a free and open-source (GPLv3), modular toolkit developed in C++.


<p align="center"><img src="https://github.com/soedinglab/transannot/blob/main/.github/TransAnnot_logo.png" height="400" /></p>

## Compile from source

Compiling TransAnnot from the source allows for system-specific optimization. For the compilation `cmake`, `g++` and `git` are required. After the compilation, TransAnnot will be located in the `build/bin` directory.

    git clone https://github.com/soedinglab/transannot.git
    cd transannot && mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..
    make -j 4
    make install
    export PATH=$(pwd)/bin/:$PATH

❗️ If you compile from source under macOS we recommend installing and using `gcc` instead of `clang` as a compiler. `gcc` can be installed with Homebrew. Force `cmake` to use `gcc` as a compiler by running:

    CC="$(brew --prefix)/bin/gcc-13"
    CCX="$(brew --prefix)/bin/g++-13"
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..

Other dependencies for the compilation from the source are `zlib` and `bzip`.

## Workflow dependencies

<<<<<<< Updated upstream
- Plass - should be installed separately in the current working directory, see [corresponding repository](https://github.com/soedinglab/plass), to perform *de novo* assembly.
- Databases - Pfam, EggNOG and UniProtKB/Swiss-Prot
<!-- Since genome assembly is a dynamic field and corresponding software are being constantly updated, we prefer not to integrate external genome assemblers (e.g. Trinity) into the TransAnnot package. One can install them separately on demand. -->
=======
- Plass - should be installed separately, see [corresponding repository](https://github.com/soedinglab/plass). To perform *de novo* assembly, it is required to install Plass to the current working directory. Standard usage is running on the results of a nucleotide assembler such as `Trinity`.  PLASS requires read lengths of at least 100 nt, so for shorter reads, a nucleotide assembler has to be used. 

- Genome assembly is a dynamic field, so the software is being continously updated. That is why no non-inhouse assemblers (e.g Trinity) are included in the TransAnnot release package. One can install them separately on demand. Some of the tools which might be useful are:

* [transdecoder](https://github.com/TransDecoder/TransDecoder) - identifies coding regions within the transcript
* [mrna-spades]()
* [Trinity]()


- Another dependencies are UniProtKB/Swiss-Prot, eggNOG and Pfam databases provided in the MMseqs2 format.

## Before starting

### tmp folder

`tmp` folder keeps temporary files. By default, all the intermediate output files from different modules will be kept in this folder. To clear `tmp` pass `--remove-tmp-files` parameter.
>>>>>>> Stashed changes

## Quick start

The quickest way to run TransAnnot is by using the `easytransannot` module:

    transannot easytransannot <inputReads.fastq> Pfam-A.full eggNOG UniProtKB/Swiss-Prot <resDB> <tmp> [options]

If (one of the) target databases is already downloaded in MMseqs2 format, directly provide the path to them, otherwise simply specify their names, and the databases will be downloaded automatically. `easytransannot` uses Plass assembler, for more details check the descriptions for `assemblereads` module below.

## Input

<<<<<<< Updated upstream
Possible inputs can be one of the following:

* translated sequences of assembled transcriptomes (obtained e.g. using Trinity followed by TransDecoder)
* raw transcriptome reads in fastq format, which will be *de novo* assembled by `plass` at the protein level

TransAnnot accepts input files from single-organism transcriptomes as well as metatranscriptomes.
<!-- In such case, it is possible to check for the contamination with the `contamination` module, which is based on MMseqs2 taxonomy workflow -->
=======
Possible inputs are assembled on the protein level:

* assembled transcriptomes (obtained e.g. using Trinity) or raw transcriptome reads, which will be *de novo* assembled on the protein level using `plass`
* metatranscriptomes
* single-organism transcriptomes
<!-- in such case it is possible to check for the contamination with `contamination` module, which is based on MMseqs2 taxonomy workflow -->
>>>>>>> Stashed changes

## Running

### Modules

* `assemblereads`            *de novo* assembles raw sequencing reads to large genomic fragments (contigs).
* `createquerydb`            creates a database in a memory-efficient MMSeqs2 format for the query input sequence.
* `downloaddb`          downloads reference databases in MMSeqs2 format on which annotations for query sequences will be searched.
* `annotate`            performs clustering on input sequences to reduce redundancy and runs sequence-profile and sequence-sequence searches for the reference query sequences to obtain the closest homologs with the annotated function. In addition, it maps descriptions of orthologous groups and protein families to the query sequences. 
<!-- After running the search UniProt IDs will be retrieved to get more detailed information about the provided transcriptome.  -->
<!-- (It finds homologs for assembled contigs in the custom-defined protein sequence database (default UniProtKB) using reciprocal-best hits (rbh module) search from MMseqs2 suite if taxonomy ID `--taxid` is provided, or MMseqs2 search if no taxonomy ID is supplied. After running the search Gene Ontology ID will be obtained from UniProt.) -->
<!-- * `contamination`       It checks contaminated contigs using _easy-taxonomy_ module from MMseqs2 suite. This approach uses taxonomy assignments of every contig to identify contamination -->
* `easytransannot`      an easy one-line command module for the complete transannot workflow, starting from input assembly, downloading reference databases to an output of sequence annotations.

### assemblereads

This module uses Plass to assemble input read sequences and obtain translated protein sequences. Plass requires read length of at least 100nt, therefore `assemblereads` or `easytransannot` module is applicable only for input reads of length $\ge$ 100nt. To run, Plass must be installed and located in the *current working directory*. Detailed information about installation can be found [here](https://github.com/soedinglab/plass#install-plass).

In this step, reads will be assembled with Plass and afterwards an MMseqs2 database will be created, you may skip this step if the transcriptome is already assembled and translated. Usage:

    transannot assemblereads <inputReads.fastq[.gz|bz]> ... <inputReads.fastq[.gz|bz]> <o: fastaFile with assembly> <o: seqDB> <tmp> [options]

Since Plass has not been benchmarked for transcriptome assembly, for standard usage, we recommend using nucleotide assembler such as [Trinity] (https://github.com/trinityrnaseq/trinityrnaseq/wiki) followed by protein translator (e.g TransDecoder) (https://github.com/TransDecoder/TransDecoder/wiki) before running TransAnnot for sequence annotation. If the input query sequence is obtained from external tools, just proceed directly with `createquerydb` module. 

### createquerydb
This module creates a database for input query sequences in memory-efficient MMSeqs2 format.

To create a query database, execute the following command:

    transannot createquerydb <inputFastaFile> <sequenceDB> <tmpDir> [options]

If input fasta file is obtained from external tools without using `assemblereads` module, this `createquerydb` module must be used. Otherwise, `assemblereads` module already provides a query sequence database in MMSeqs2 format and hence this step can be skipped. 

### downloaddb

This module downloads sequence databases for homology searches.
   
To see detailed information about databases, please use the following command:

    mmseqs databases -h

and execute the below command to download the databases (Ensure the same keyword as given in `mmseqs database -h`):

    transannot downloaddb <selection> <outDB> <tmp> [options]  

By default, `transannot` runs 3 searches in the subsequent `annotate` module against the following databases: (i) `Pfam-A.full` (profile database), (ii) `eggNOG` (profile database) and (iii) `UniProtKB/SwissProt` (sequence database). Hence, use the above command separately for each database to download them, for more information check [MMseqs2 user guide](https://github.com/soedinglab/MMseqs2/wiki#downloading-databases).

### annotate

This module extracts representative sequences from the query database using clustering (redundancy-free set) and uses them as search input for 3 transcriptome annotation searches (one sequence-sequence and two sequence-profile).

To run the annotate module, execute the following command:

    transannot annotate <assembledQueryDB> <path to Pfam profileTargetDB> <path to eggNOG profileTargetDB> <path to SwissProt sequenceTargetDB> <o:resTsvFile> <tmp> [options]

#### Output

Outut is a tab-separated `.tsv` file containing the following columns:

    queryID targetID description E-value sequenceIdentity bitScore typeOfSearch nameOfDatabase 

#### Important options of the annotate module

`--simple-output` parameter allows users to obtain simplified output for each query sequence, which only includes query and target IDs, a header of the target database and E-value. Whereas standard output contains sequence identity and bit score in addition to details provided in the `--simple-output`. Usage: 
    
    transannot annotate $1 $2 $3 $4 $5 $6 --simple-output 

When no tag is used, standard output will be provided.

`--min-seq-id` is a parameter to adjust the minimum sequence identity for the searches. The default value is set to 0.3.

`--no-run-clust` performs annotation without clustering. All the input query sequences will undergo annotation searches.

#### Use of custom database for annotation
If one is interested in annotation against a user-defined database, `annotatecustom` module provides such an opportunity. To run the custom annotate module execute the following command:

    transannot annotatecustom <assembledQueryDB> <user-defined DB>

The user-provided database will be converted to the MMseqs2 format within the module, but it is also possible to initially provide a MMseqs2-formatted database. A limitation is that unless ID descriptors are included in the database, no mapping can be performed and no group descriptors will be retrieved.

#### tmp folder

`tmp` folder keeps temporary files. By default, all the intermediate output files from different modules will be kept in this folder. To clear `tmp` pass `--remove-tmp-files` parameter [bool], applicable for all modules except `createquerydb` and `downloaddb`.
