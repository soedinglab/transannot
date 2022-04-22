#include "Command.h"
#include "LocalCommandDeclarations.h"
#include "LocalParameters.h"

const int NO_CITATION = 0;
const char* binary_name = "transannot";
const char* tool_name = "TransAnnot";
const char* tool_introduction =
"TransAnnot: An annotation pipeline that predicts functions of de novo assembled transcripts based on homology search using MMSeqs2";

LocalParameters& localPar = LocalParameters::getLocalInstance();
std::vector<struct Command> commands = {
    {"assembly",    assembly,   &localPar.assembly, COMMAND_MAIN,
        "Assembly of de novo transcriptomes on protein level with PLASS",
        "It is also possible to give already assembled (e.g. with Trinity) files as input",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de", "Yazhini A. yazhini@mpinat.mpg.de",
        "<i:fastaFile> <outPath> <tmpDir>",
        NO_CITATION, {}

    },

    {"downloaddb",  downloaddb,     &localPar.downloaddb, COMMAND_MAIN,
        "Download database to run reciprocal best hit (RBH) against",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de", "Yazhini A. yazhini@mpinat.mpg.de",
        "<name> <outPath> <tmpDir>",
        NO_CITATION, {}
        
    },

    {"contamination",   contamination, &localPar.contaminationworkflow, COMMAND_MAIN,
        "Check for the contamination with MMseqs taxonomy",
        "May be used with the non-metatranscriptomes",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de", "Yazhini A. yazhini@mpinat.mpg.de",
        "<>",
        NO_CITATION, {}
        
    },

    {"annotate",    annotate, &localPar.annotateworkflow, COMMAND_MAIN,
        "Run RBH of MMseqs2 to find homology",
        "Afterwards get GeneOntology ID (GO-IDs) to find out the functions and pathways",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de", "Yazhini A. yazhini@mpinat.mpg.de",
        "<i:queryFastaFile[.gz]> <i:targetDB> <o:outputPath> <tmpDir>",
        NO_CITATION, {}

    },

    {"createdb",    createdb, &localPar.createdb, COMMAND_MAIN,
        "Create MMseqs database from assembled sequences (with transannot annotate or other tool)",
        "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de", "Yazhini A. yazhini@mpinat.mpg.de",
        "<i:fastaFile> <o:sequenceDB> <tmpDir>",
        NO_CITATION, {}
    }

    
};