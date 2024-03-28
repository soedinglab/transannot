#include "LocalParameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
#include "annotatecustom.sh.h" 

extern const char *binary_name;

int annotatecustom(int argc, const char **argv, const Command& command) {
    LocalParameters &par = LocalParameters::getLocalInstance();
    par.parseParameters(argc, argv, command, true, 0, 0);

    //check whether tmp exists and try to create it if not
    std::string tmpDir = par.filenames.back();
    std::string hash = SSTR(par.hashParameter(command.databases, par.filenames, par.createquerydb));
    if (par.reuseLatest) {
        hash = FileUtil::getHashFromSymLink(tmpDir + "/latest");
    }
    tmpDir = FileUtil::createTemporaryDirectory(tmpDir, hash);

    CommandCaller cmd;
    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);
    cmd.addVariable("VERBOSITY", par.createParameterString(par.onlyverbosity).c_str());
    cmd.addVariable("RESULT2REPSEQ_PAR", par.createParameterString(par.result2repseq).c_str());
    cmd.addVariable("CREATETSV_PAR", par.createParameterString(par.createtsv).c_str());
    cmd.addVariable("THREADS_PAR", par.createParameterString(par.onlythreads).c_str());
    cmd.addVariable("SIMPLE_OUTPUT", par.simpleOutput ? "TRUE" : NULL);
    cmd.addVariable("NO_LINCLUST", par.noPerformClust ? "TRUE" : NULL);

    std::string program = tmpDir + "/annotatecustom.sh";
    FileUtil::writeFile(program, annotatecustom_sh, annotatecustom_sh_len);
    cmd.execProgram(program.c_str(), par.filenames);
    
    return EXIT_SUCCESS;
}
