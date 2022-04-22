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
        "<i:selection> <outPath> <tmpDir>",
        NO_CITATION, {}
        
    },

    {}

};