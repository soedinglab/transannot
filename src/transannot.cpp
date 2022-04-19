#include "Command.h"
#include "LocalCommandDeclarations.h"
#include "LocalParameters.h"

const char* binary_name = "transannot";
const char* tool_name = "TransAnnot";
const char* tool_introduction =
"TransAnnot: An annotation pipeline that predicts functions of de novo assembled transcripts based on homology search using MMSeqs2";

LocalParameters& localPar = LocalParameters::getLocalInstance();
std::vector<Command> commands = {
    {"assembly",    assembly,   &localPar.assembly, COMMAND_MAIN,
        "Assembly of de novo transcriptomes on protein level with PLASS",
        NULL,

    },

    {"downloaddb",  downloaddb,     &localPar.downloaddb, COMMAND_MAIN,
        "Download database to run reciprocal best hit (RBH) against",
        NULL,
        
    }
};