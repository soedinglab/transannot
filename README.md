# TransAnnot: a fast transcriptome annotation pipeline
TransAnnot is a toolkit designed to predict protein functions, identify orthologous relationships, and decipher biological pathways for newly sequenced transcriptomes. Utilizing [MMseqs2's](https://mmseqs.com) fast sequence-sequence and sequence-profile search, it identifies the closest homologs from reference databases to infer essential details such as protein function, structure, and orthologous groups.

Optionally, TransAnnot can use [Plass](https://github.com/soedinglab/plass) for transcriptome assembly, enabling *de novo* assembly of raw sequence reads at the protein level.

TransAnnot is a free and open-source (GPLv3), modular toolkit developed in C++.

Now published in Bioinformatics Advances: [https://doi.org/10.1093/bioadv/vbae152](https://doi.org/10.1093/bioadv/vbae152)

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

- Plass - should be installed separately, see [corresponding repository](https://github.com/soedinglab/plass). To perform *de novo* assembly, it is required to install Plass to the current working directory. Standard usage is running on the results of a nucleotide assembler such as `Trinity`.  PLASS requires read lengths of at least 100 nt, so for shorter reads, a nucleotide assembler has to be used. 

- Genome assembly is a dynamic field, so the software is being continously updated. That is why no non-inhouse assemblers (e.g Trinity) are included in the TransAnnot release package. One can install them separately on demand. Some of the tools which might be useful are:

* [transdecoder](https://github.com/TransDecoder/TransDecoder) - identifies coding regions within the transcript
* [mrna-spades]()
* [Trinity]()


- Another dependencies are UniProtKB/Swiss-Prot, eggNOG and Pfam databases provided in the MMseqs2 format.

## Before starting

### tmp folder

`tmp` folder keeps temporary files. By default, all the intermediate output files from different modules will be kept in this folder. To clear `tmp` pass `--remove-tmp-files` parameter.

## Quick-ish start
For the fastest results, please consider assembling the data and translating it into amino acid sequences beforehand.

#### STEP 1: Download default databases
(THIS IS A ONE-TIME PROCESS THAT WILL ONLY HAVE TO BE EXECUTED THE FIRST TIME AFTER `TRANSANNOT` HAS BEEN DOWNLOADED.)

Download the default databases using `transannot downloaddb`:
    transannot downloaddb eggNOG <path_to_output>/<eggNOGDB_name> <eggNOGDB_tmpdir_name> [options]
    transannot downloaddb Pfam <path_to_output>/<PfamDB_name> <PfamDB_tmpdir_name> [options]
    transannot downloaddb SwissProt <path_to_output>/<SwissProtDB_name> <SwissProtDB_tmpdir_name> [options]

(The downloads can take quite long depending on the download server loads, so it is advisable to execute these commands inside a windows manager such as `tmux` or `screen`.)

#### STEP 2: Annotating the data
This can be done in one of the following three ways (we strongly recommend option C).

##### Option A: Starting with sequencing reads
The quickest way to run TransAnnot is by using the `easytransannot` module:

    transannot easytransannot <inputReads.fastq> Pfam-A.full eggNOG UniProtKB/Swiss-Prot <resDB> <tmp> [options]

If (one of the) target databases is already downloaded in MMseqs2 format, directly provide the path to them, otherwise simply specify their names, and the databases will be downloaded automatically. `easytransannot` uses Plass assembler, for more details check the descriptions for `assemblereads` module below.

##### Option B: Starting with assembled nucleotide sequences (NOT RECOMMENDED)
Should a nucleotide assembly already be available (e.g., in `<input.fasta>`), it can be annotated as follows:

    transannot createquerydb <input.fasta> <input_queryDB_name> <tmp> [options]
    transannot annotate <input_queryDB_name> Pfam-A.full eggNOG UniProtKB/Swiss-Prot <resDB> <tmp> [options]

(`<input_queryDB_name>` is just a string providing either the name and additionally the path to the MMseqs2-formatted database for the input sequences.)

We recommend against starting with nucleotide sequences as of the current release because the translated search that `TransAnnot` relies upon is quite slow.

##### Option C: Starting with assembled, _in silico_ translated amino acid sequences (RECOMMENDED)
It is far more preferable to translate the assembly with a tool such as [TransDecoder](https://github.com/TransDecoder/TransDecoder) prior to annotation with `TransAnnot` as the searches are very fast in this case. The workflow in this case is identical to the one described above; simply provide the input `FASTA` file containing the translated amino acid sequences to `tranannot createquerydb` and then supply the created query DB as input to `transannot annotate`.

## Inputs

Possible inputs are assembled on the protein level:

* assembled transcriptomes (obtained e.g. using Trinity) or raw transcriptome reads, which will be *de novo* assembled on the protein level using `plass`
* metatranscriptomes
* single-organism transcriptomes
* TransAnnot can work with the long reads input too. Thus, to enable PLASS assembly, input should be provided as a concatenated single file for single-end reads
<!-- in such case it is possible to check for the contamination with `contamination` module, which is based on MMseqs2 taxonomy workflow -->

## Execution

### Modules

* `assemblereads` - *de novo* assembles raw sequencing reads to large genomic fragments (contigs).
* `createquerydb` - creates a database in a memory-efficient MMSeqs2 format for the query input sequence.
* `downloaddb` - downloads reference databases in MMSeqs2 format on which annotations for query sequences will be searched.
* `annotate` - performs clustering on input sequences to reduce redundancy and runs sequence-profile and sequence-sequence searches for the reference query sequences to obtain the closest homologs with the annotated function. In addition, it maps descriptions of orthologous groups and protein families to the query sequences.
* `easytransannot` - an easy one-line command module for the complete transannot workflow, starting from input assembly, downloading reference databases to an output of sequence annotations.
* `annotatecustom` - facilitates annotation against user-supplied databases instead of the default databases used by `TransAnnot`.
<!-- After running the search UniProt IDs will be retrieved to get more detailed information about the provided transcriptome.  -->
<!-- (It finds homologs for assembled contigs in the custom-defined protein sequence database (default UniProtKB) using reciprocal-best hits (rbh module) search from MMseqs2 suite if taxonomy ID `--taxid` is provided, or MMseqs2 search if no taxonomy ID is supplied. After running the search Gene Ontology ID will be obtained from UniProt.) -->
<!-- * `contamination`       It checks contaminated contigs using _easy-taxonomy_ module from MMseqs2 suite. This approach uses taxonomy assignments of every contig to identify contamination -->


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

By default, `transannot` runs 3 searches in the subsequent `annotate` module against the following databases: (i) `Pfam-A.full` (profile database), (ii) `eggNOG` (profile database) and (iii) `UniProtKB/SwissProt` (sequence database). Hence, use the above command separately for each database to download them, for more information check [MMseqs2 user guide](https://github.com/soedinglab/MMseqs2/wiki#downloading-databases).We use the abovementioned databases for the default annotation workflow to ensure comprehensive set of annotations that include hand-reviewed homologs (`SwissProt`), fine-grained orthologs (`eggNOG`), and domains (`Pfam-A`). On demand, one can use [`annotatecustom`](##Use-of-custom-database-for-annotation) to perform annotation against user-defined database.

`downloaddb` allows resuming the download of the DB if it's detected in the provided directory path.

### annotate

This module extracts representative sequences from the query database using clustering (redundancy-free set) and uses them as search input for 3 transcriptome annotation searches (one sequence-sequence and two sequence-profile). To ensure deep coverage of the transcriptome, TransAnnot only retains non-overlapping hits for each query.

To run the annotate module, execute the following command:

    transannot annotate <assembledQueryDB> <path to Pfam profileTargetDB> <path to eggNOG profileTargetDB> <path to SwissProt sequenceTargetDB> <o:resTsvFile> <tmp> [options]

### annotatecustom

Annotates against user-specified databases. Run as follows:

    transannot annotatecustom <assembledQueryDB> <user-defined DB>

## Output

`TransAnnot`'s output is, in general, a tab-separated `.tsv` file containing the following columns:

    queryID targetID qstart qend description E-value sequenceIdentity bitScore typeOfSearch nameOfDatabase 

Where,
* `queryID` is the sequence identifier for the annotated transcript.
* `targetID` is the identifier for the sequence/profile from which the annotation is sourced.
* `qstart` start index of the annotated query.
* `qend` end index of the annotated query.
* `description` is the string (e.g., `FASTA` header from the matched `Swiss-Prot` sequence) supplying the human-readable annotation (e.g., "XYZ protein").
* `E-value` is the expectation value for this particular match (combination of query and target sequences) which indicates, loosely, the confidence one can have that the match is real (i.e., due to shared evolutionary history) and not due to chance (lower the `E-value` the better).
* `sequenceIdentity` is the number of positions in both sequences that are identical to one another, represented as a fraction of the total (sum) of the sequence length(s). This is a percentage value.
* 'bitScore` is the normalized size (in bits) of the hypothetical database one would have to search against to obtain the match at hand purely by chance (higher the `bitScore` the better).
* `typeOfSearch` is a filed that indicates whether the database searched is a sequence or a profile database.
* `nameOfDatabase` is a filed indicating the name of the database searched (e.g., "Pfam).

## Important options of the annotate module

`--simple-output` parameter allows users to obtain simplified output for each query sequence, which only includes query and target IDs, a header of the target database and E-value. Whereas standard output contains sequence identity and bit score in addition to details provided in the `--simple-output`. Usage: 
    
    transannot annotate $1 $2 $3 $4 $5 $6 --simple-output 

When no tag is used, standard output will be provided.

`--min-seq-id` is a parameter to adjust the minimum sequence identity for the searches. The default value is set to 0.3.

`--no-run-clust` performs annotation without clustering. All the input query sequences will undergo annotation searches.

## Use of custom database for annotation
If one is interested in annotation against a user-defined database, `annotatecustom` module provides such an opportunity. To run the custom annotate module execute the following command:

    transannot annotatecustom <assembledQueryDB> <user-defined DB>

The user-provided database will be converted to the MMseqs2 format within the module, but it is also possible to initially provide a MMseqs2-formatted database. A limitation is that unless ID descriptors are included in the database, no mapping can be performed and no group descriptors will be retrieved.

## tmp folder

`tmp` folder keeps temporary files. By default, all the intermediate output files from different modules will be kept in this folder. To clear `tmp` pass `--remove-tmp-files` parameter [bool], applicable for all modules except `createquerydb` and `downloaddb`.

## TransAnnot wiki

The `TransAnnot` wiki can be found here: [https://github.com/soedinglab/transannot/wiki](https://github.com/soedinglab/transannot/wiki).

## Citing TransAnnot

Please cite our publication ([https://doi.org/10.1093/bioadv/vbae152](https://doi.org/10.1093/bioadv/vbae152)) in Bioinformatics Advances.
