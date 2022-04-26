#include "Command.h"
#include "LocalCommandDeclarations.h"
#include "LocalParameters.h"

const int NO_CITATION = 0;
const char* binary_name = "transannot";
const char* tool_name = "TransAnnot";
const char* tool_introduction =
"TransAnnot: An annotation pipeline that predicts functions of de novo assembled transcripts based on homology search using MMSeqs2";
// const char* main_author = 

LocalParameters& localPar = LocalParameters::getLocalInstance();
std::vector<struct Command> commands = {
    {"assembly",    assembly,   &localPar.assembly, COMMAND_MAIN,
        "Assembly of de novo transcriptomes on protein level with PLASS",
        "It is also possible to give already assembled (e.g. with Trinity) files as input",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
        "<i:fast(a|q)File[.gz]> | <i:fastqFile1_1[.gz] ... <i:fastqFileN_1[.gz] <i:fastqFileN_2[.gz]> <o:fastaFile> <tmpDir>",
        NO_CITATION, {{"",DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, NULL}}},

    },

    {"downloaddb",  downloaddb,     &localPar.downloaddb, COMMAND_MAIN,
        "Download database to run reciprocal best hit (RBH) against",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
        "<name> <outPath> <tmpDir>",
        NO_CITATION, {}
        
    },

    {"annotate",    annotate, &localPar.annotateworkflow, COMMAND_MAIN,
        "Run RBH of MMseqs2 to find homology, depending on UniProtID get further information about transcriptome functions",
        "Information from KEGG, ExPASy, Pfam, EggNOG and other databases may be assigned. For details call annotate -h or --help",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
        "<i:queryFastaFile[.gz]> <i:targetDB> <o:outputPath> <tmpDir>",
        NO_CITATION, {}

    },

    {"createdb",    createdb, &localPar.createdb, COMMAND_MAIN,
        "Create MMseqs database from assembled sequences (with transannot annotate or other tool)",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
        "<i:fastaFile> <o:sequenceDB> <tmpDir>",
        NO_CITATION, {}
    },

     {"contamination",   contamination, &localPar.contaminationworkflow, COMMAND_EXPERT,
        "Check for the contamination with MMseqs taxonomy",
        "Assigns taxaIDs and then finds organisms with minor frequency",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
        "<>",
        NO_CITATION, {}
        
    }

    
};
