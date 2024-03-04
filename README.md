# TransAnnot: a fast transcriptome annotation pipeline
TransAnnot is a toolkit designed to predict protein functions, identify orthologous relationships, and decipher biological pathways for newly sequenced transcriptomes. Utilizing [MMseqs2's](https://mmseqs.com) fast sequence-sequence and sequence-profile search, it identifies the closest homologs from reference databases to infer essential details such as protein function, structure, and orthologous groups.

Optionally, TransAnnot can use [Plass](https://github.com/soedinglab/plass) for transcriptome assembly, enabling de novo assembly of raw sequence reads at the protein level.

TransAnnot is a free and open source (GPLv3), modular toolkit developed in C++.


<p align="center"><img src="https://github.com/soedinglab/transannot/blob/main/.github/TransAnnot_logo.png" height="400" /></p>

## Compile from source

Compiling TransAnnot from source allows for system-specific optimization. For the compilation `cmake`, `g++` and `git` are required. After the compilation, TransAnnot will be located in `build/bin` directory.

    git clone https://github.com/soedinglab/transannot.git
    cd transannot && mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..
    make -j 4
    make install
    export PATH=$(pwd)/transannot/bin/:$PATH

❗️ If you compile from source under macOS we recommend to install and use `gcc` instead of `clang` as a compiler. `gcc` can be installed with Homebrew. Force `cmake` to use `gcc` as a compiler by running:

    CC="$(brew --prefix)/bin/gcc-13"
    CCX="$(brew --prefix)/bin/g++-13"
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..

Other dependencies for the compilation from source are `zlib` and `bzip`.

## Workflow dependencies

- Plass - should be installed separately, see [corresponding repository](https://github.com/soedinglab/plass). To perform *de novo* assembly, it is required to install Plass to the current working directory. Standard usage is running on the results of a nucleotide assembler such as `Trinity`.  PLASS requires read lengths of at least 100 nt, so for shorter reads, a nucleotide assembler has to be used. 

- Genome assembly is a dynamic field, so the software is being continously updated. That is why no external assemblers (e.g Trinity) are included in the TransAnnot release package. One can install them separately on demand.

## Before starting

### tmp folder

`tmp` folder keeps temporary files. By default, all the intermediate output files from different modules will be kept in this folder. To clear `tmp` pass `--remove-tmp-files` parameter.

## Quick start

The quickest way to run TransAnnot is using the `easy` workflow:

    transannot easytransannot <inputReads.fastq> Pfam-A.full eggNOG UniProtKB/Swiss-Prot <resDB> <tmp> [options]

If (one of the) target databases are already downloaded in MMseqs2 format, directly provide the path to them, otherwise simply specify their names, and the databases will be downloaded automatically.

## Input

Possible inputs are:

* assembled transcriptomes (aobtained e.g. using Trinity) or raw transcriptome reads, which will be de novo assembled on the protein level using `plass`
* metatranscriptomes
* single-organism transcriptomes
<!-- in such case it is possible to check for the contamination with `contamination` module, which is based on MMseqs2 taxonomy workflow -->

## Running

### Modules

* `assemblereads`            *de novo* assembles raw sequencing reads to large genomic fragments (contigs).
* `annotate`            clusters given input for the reduction of redundancy and runs sequnce-profile and sequence-sequence searches to obtain the closest homologs with annotated function. It also retrieves descriptions of orthologous groups and protein families throgh mapping. 
<!-- After running thhe search UniProt IDs will be retrieved to get more detailed information about the provided transcriptome.  -->
<!-- (It finds homologs for assembled contigs in the custom defined protein seqeunce database (default UniProtKB) using reciprocal-best hits (rbh module) search from MMseqs2 suite if taxonomy ID `--taxid` is provided, or MMseqs2 search if no taxonomy ID is supplied. After runing the search Gene Ontology ID will be obtained from UniProt.) -->
<!-- * `contamination`       It checks contaminated contigs using _easy-taxonomy_ module from MMseqs2 suite. This approach uses taxonomy assignments of every contig to identify contamination -->
* `createquerydb`            creates a database from the sequence space (obtained from `downloaddb` module) in a memory-efficient MMSeqs2 format.
* `downloaddb`          downloads databases that serve as a search space for homology detection
* `easytransannot`      easy module for a quick start, performs assembly, downloads DB and executes annotation

### (Plass) Assembly

Plass is the default assembler, which is used in the `easytransannot` workflow as well. However, we recommend assembly with [Trinity](https://github.com/trinityrnaseq/trinityrnaseq/wiki) since Trinity provides more reliable assemblies compared to Plass. If assembly was performed using Trinity, proceed with `createquerydb` and further annotation. 

Before running this step Plass must be installed, detailed information about installation can be found [here](https://github.com/soedinglab/plass#install-plass). Please make sure PLASS is located in the current working directory.

In this step, reads will be assembled with Plass and afterwards a MMseqs2 database will be created, you may skip this step if the transcriptome is already assembled. Usage:

    transannot assemblereads <inputReads.fastq[.gz|bz]> ... <inputReads.fastq[.gz|bz]> <o: fastaFile with assembly> <o: seqDB> <tmp> [options]

### Dowloading databases

In this step, sequence databases for homology searches will be downloaded.
   
To see detailed information about databases, please use the following command:

    mmseqs databases -h

and execute the below command to download the databases (Ensure the same keyword as given in `mmseqs database -h`):

    transannot downloaddb <selection> <outDB> <tmp> [options]

Hence, `transannot` runs 3 searches in `annotate` module, this step should be repeated 3 times. For the annotation module `Pfam-A.full`, `eggNOG` (profile database) and `UniProtKB/SwissProt` (sequence database) are standard, so please download them using this module, for more information also check [MMseqs2 user guide](https://github.com/soedinglab/MMseqs2/wiki#downloading-databases).

### Annotate workflow

In the `annotate` module representative sequences will be extracted and used as search input to remove redundancy. 3 searches (one sequence-sequence and two seqeuce-profile) will be performed.

To run annotate module of transannot execute the following command:

    transannot annotate <assembledQueryDB> <path to Pfam profileTargetDB> <path to eggNOG profileTargetDB> <path to SwissProt sequenceTargetDB> <o:resTsvFile> <tmp> [options]

If one is interested in annotation against an user-defined database, `annotatecustom` provides such an opportunity. To run custom annotate module execute the following command:

    transannot annotatecustom <assembledQueryDB> <user-defined DB>
User-provided database will be converted to the MMseqs2 format within the module, but it is also possible to initially provide a MMseqs2-formatted database. Limitation is that unless ID descriptors are included in the database, no mapping can be performed and no group descriptors will be retreived.

#### Important options of the annotate module

`--simple-output` parameter allows user to obtain simplified output, which only includes query and target IDs, header of the target database and E-value. Whereas standard output also contains sequence identity and bit score for each target sequence. Usage: 
    
    transannot annotate $1 $2 $3 $4 $5 $6 --simple-output 

When no tag is used, standard output will be provided.

`--min-seq-id` is a parameter to adjust minimum sequence identity for the searches. Default value is set to 0.3.

`--no-run-clust` performs annotation without clustering. All the input sequences will undergo similarity searches.

#### Output

Outut is a tab-separated `.tsv` file containing following columns:

    queryID targetID description E-value sequenceIdentity bitScore typeOfSearch nameOfDatabase 
