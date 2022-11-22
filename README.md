# TransAnnot - a fast and easy transcriptome annotation pipeline

TransAnnot is a GPL-3.0 licensed, C++ implemented modular toolkit. TransAnnot predicts protein functions, orthologous relationships and biological pathways for the whole newly sequenced transcriptome.
It uses high-performative MMseqs2 sequence-profile search to obtain closest homologs from profile database and infer protein function, structure and orthologous groups based on the identified homologs.
Prior to functional annotation, it can perform transcriptome sequence assembly using PLASS (Protein-Level ASSembler) to *de novo* assemble raw sequence reads on protein level upon user request.

## Compile from source

Compiling from source helps to optimize TransAnnot for the specific system, which improve its performance. For the compilation `cmake`, `g++` and `git` are required. After the compilation TransAnnot will be located in `build/bin` directory.

    git clone https://github.com/mariia-zelenskaia/transannot.git
    cd transannot && mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..
    make -j 4
    sudo make install
    export PATH=$(pwd)/transannot/bin/:$PATH

❗️ If you compile from source under macOS we recommend to install and use `gcc` instead of `clang` as a compiler. `gcc` can be installed with Homebrew. Force cmake to use gcc as a compiler by running:

    CC="$(brew --prefix)/bin/gcc-10"
    CCX="$(brew --prefix)/bin/g++-10"
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..

Other dependencies for the compilation from source are `zlib` and `bzip`.

## Workflow dependencies

- PLASS - should be installed separately, see [corresponding repository](https://github.com/soedinglab/plass). To perform *de novo* assembly, it is required to install PLASS to the current working directory.

## Before starting

### tmp folder

`tmp` folder keeps temporary files. By default, all the intermediate output files from different modules will be kept in this folder. To clear `tmp` pass `--remove-tmp-files` parameter.

## Quick start

There is a possibility to run TransAnnot using easy module

    transannot easytransannot <inputReads.fastq> Pfam-A.full eggNOG UniProtKB/Swiss-Prot <resDB> <tmp> [options]

If (one of the) target databases are already downloaded in MMseqs2 format, just provide pathway to them, otherwise simply use their names, and the databases will be downloaded in easy module.

## Input

Possible inputs are:

* assembled transcriptomes (obtained e.g. using Trinity) or raw transcriptome reads, which will be de novo assembled at protein level using `plass`
* metatranscriptomes
* single-organism transcriptomes
<!-- in such case it is possible to check for the contamination with `contamination` module, which is based on MMseqs2 taxonomy workflow -->

## Running

### Modules

* `assemblereads`            It *de novo* assembles raw sequencing reads to large genomic fragments (contigs)
* `annotate`            It clusters given input for the reduction of redundancy and runs sequnce-profile search against profile database (e.g. PDB70) and sequence-sequence search to obtain the closest homologs with annotated function
<!-- After running thhe search UniProt IDs will be retrieved to get more detailed information about the provided transcriptome.  -->
<!-- (It finds homologs for assembled contigs in the custom defined protein seqeunce database (default UniProtKB) using reciprocal-best hits (rbh module) search from MMseqs2 suite if taxonomy ID `--taxid` is provided, or MMseqs2 search if no taxonomy ID is supplied. After runing the search Gene Ontology ID will be obtained from UniProt.) -->
<!-- * `contamination`       It checks contaminated contigs using _easy-taxonomy_ module from MMseqs2 suite. This approach uses taxonomy assignments of every contig to identify contamination -->
* `createquerydb`            It creates a database from the sequence space (obtained from `downloaddb` module) in a required format for MMseqs2 rbh module
* `downloaddb`          It downloads the user defined database that serves as a search space for homology detection
* `easytransannot`      Easy module for a quick start, performs assembly, downloads DB and executes annotation

### PLASS assembly

Before running this step PLASS must be installed, detailed information about installation can be found [here](https://github.com/soedinglab/plass#install-plass). Please make sure PLASS is located in the current working directory.

In this step, reads will be assembled with Protein-Level ASSembler PLASS and afterwards MMseqs2 database will be created, you may skip this step if the transcriptome is already assembled. Usage:

    transannot assemblereads <inputReads.fastq[.gz|bz]> ... <inputReads.fastq[.gz|bz]> <fastaFile> <seqDB> <tmp> [options]

### Dowloading databases

In this step, sequence database for homology search will be downloaded.
<!-- Default database is PDB70 and can be obtained using a below command:

    transannot downloaddb PDB70 <outDB> <tmp> [options] -->    
To see options for your choice, please use the below command:

    mmseqs databases -h

and execute the below command to download the preferred database (ensure the same keyword as given in `mmseqs database -h`):

    transannot downloaddb <selection> <outDB> <tmp> [options]

Hence transannot runs 3 searches in `annotate` module, this step should be repeated 3 times. For the annotation module `Pfam-A.full`, `eggNOG` (profile datbases) and `UniProtKB/SwissProt` (sequence database) are standard, so please download them using this module, for more information also check [MMseqs2 user guide](https://github.com/soedinglab/MMseqs2/wiki#downloading-databases).

### Annotate workflow

In the `annotate` module representative sequences will be extracted and used as search input to remove redundancy. 3 searches (one sequence-sequence and two seqeuce-profile) will be performed.

To run annotate module of transannot execute the following command:

    transannot annotate <assembledQueryDB> <path to Pfam profileTargetDB> <path to eggNOG profileTargetDB> <path to SwissProt sequenceTargetDB> <outDB> <tmp> [options]

#### Important options of the annotate module

`--simple-output` parameter allows user to obtain simplified output, which only includes query and target IDs, header of the target database and E-value. Whereas standard output also contains sequence identity and bit score for each target sequence. Usage: 
    
    transannot annotate $1 $2 $3 $4 $5 $6 --simple-output 

When no tag is used, standard output will be provided.

`--min-seq-id` is a parameter to adjust minimum sequence identity for the searches. Default value is set to 0.6.

### Profile databases

Sequence profiles contain linear probabilities for each aminoacid at every position of the set. There is an internal MMseqs2 profile DB format. `annotate` module of transannot implements sequence-profile search, that is why profile databases must be provided as a input target.

<!-- ### Contamination

Contamination module checks for the contamination in the transcriptomic data. It uses MMseqs2 _easy-taxonomy_ module.

    transannot contamination <Input.fasta> <targetDB> <outPath> <tmp> [options]
 
You can find the report of taxonomy assignments in `outPath` folder. -->
