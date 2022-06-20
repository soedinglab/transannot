# TransAnnot - a transcriptome annotation pipeline
TransAnnot predicts protein functions, orthologous relationships and biological pathways for the whole newly sequenced transcriptome.
It uses MMseqs2 reciprocal best hit to obtain closest homologs from UniProtKB database (or user defined database) and infer protein function, structure and orthologous groups based on the identified homologs.
Prior to functional annotation, it can perform transcriptome sequence assembly using PLASS (Protein-Level ASSembler) to assemble raw sequence reads on protein level upon user request.

## Compile from source
Compiling from source helps to optimize TransAnnot for the specific system, which improve its performance. For the compilation `cmake`, `g++` and `git` are required. After the compilation the TransAnnot will be located in `build/bin` directory (or just run `which transannot` in the command line to get the pathway to TransAnnot)

    git clone https://github.com/mariia-zelenskaia/transannot.git
    cd transannot && mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..
    make -j 4
    sudo make install
    export PATH=$(pwd)/transannot/bin/:$PATH

❗️ If you compile from source under macOS we recommend to install and use `gcc` instead of `clang` as a compiler. gcc can be installed with Homebrew. Force cmake to use gcc as a compiler by running:

    CC="$(brew --prefix)/bin/gcc-10"
    CCX="$(brew --prefix)/bin/g++-10"
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=. ..

Other dependencies for the compilation from source are `zlib` and `bzip`.

## Input
Possible inputs are:

* assembled transcriptomes (obtained e.g. using Trinity) or raw transcriptome reads, which will be assembled at protein level using `plass`
* metatranscriptomes
* single-organism transcriptomes, in such case it is possible to check for the contamination with `contamination` module, which is based on MMseqs2 taxonomy workflow

## Running

### Modules

* `assemble`            It assembles raw sequencing reads to large genomic fragments (contigs)
* `annotate`            It finds homologs for assembled contigs in the custom defined protein seqeunce database (default UniProtKB) using reciprocal-best hits (rbh module) search from MMseqs2 suite if taxonomy ID `--taxid` is provided, or MMseqs2 search if no taxonomy ID is supplied. After runing the search Gene Ontology ID will be obtained from UniProt. 
* `annotateprofiles`    It ...
* `contamination`       It checks contaminated contigs using _easy-taxonomy_ module from MMseqs2 suite. This approach uses taxonomy assignments of every contig to identify contamination
* `createquerydb`            It creates a database from the sequence space (obtained from `downloaddb` module) in a required format for MMseqs2 rbh module
* `downloaddb`          It downloads the user defined database that serves as a search space for homology detection

### Dowloading databases

In this step, sequence database for homology search will be downloaded.
Default database is UniProtKB and can be obtained using a below command:

    transannot downloaddb UniProtKB <outDB> <tmp> [options]
    
To see other options for your choice, please use the below command:

    mmseqs databases -h

and use the below command to download the preferred database (ensure the same keyword as given in `mmseqs database -h`):

    transannot downloaddb <selection> <outDB> <tmp> [options]

### Annotate workflow

`annotate -h` provides details on sequence type and databases acceptable for the `annotate` module. 

### Contamination

Contamination module checks for the contamination in the transcriptomic data. It uses MMseqs2 _easy-taxonomy_ module.

    transannot contamination <Input.fasta> <targetDB> <outPath> <tmp> [options]
 
You can find the report of taxonomy assignments in `outPath` folder.

### tmp folder

`tmp` folder keeps temporary files. By default, all the intermediate output files from different modules will be kept in this folder. To clear `tmp` pass `--remove-tmp-files` parameter.
