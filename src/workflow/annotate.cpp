#include "Parameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
// #include "annotate.sh"  // add sh.h later

void setAnnotateDefault (Parameters *p){
    // p ->;

}

void setAnnotateMode (Parameters *p){
    // p ->;
}

int annotate(int argc, const char **argv, const Command &command){
    Parameters &par = Parameters::getInstance();
    par.PARAM_DB_OUTPUT.addCategory(MMseqsParameter::COMMAND_EXPERT);

    CommandCaller cmd;

    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);
    return EXIT_SUCCESS;
}