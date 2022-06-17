#include "Parameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
#include "downloaddb.sh.h"
#include "LocalParameters.h"

int downloaddb(int argc, const char **argv, const Command& command) {
    LocalParameters &par = LocalParameters::getLocalInstance();
    par.parseParameters(argc, argv, command, true, 0, 0);

    std::string tmpDir = par.filenames.back();
    std::string hash = SSTR(par.hashParameter(command.databases, par.filenames, par.downloaddb));
    if (par.reuseLatest) {
        hash = FileUtil::getHashFromSymLink(tmpDir + "/latest");
    }
    tmpDir = FileUtil::createTemporaryDirectory(tmpDir, hash);
    par.filenames.pop_back();

    CommandCaller cmd;
    cmd.addVariable("TMP_PATH", tmpDir.c_str());
    cmd.addVariable("OUTDB", par.filenames.back().c_str());
    par.filenames.pop_back();
    cmd.addVariable("CREATESUBDB_PAR", par.createParameterString(par.createsubdb).c_str());
    cmd.addVariable("TAXONOMY_ID", par.taxId == 1 ? "TRUE" : NULL);
    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);
    cmd.addVariable("THREADS_PAR", par.createParameterString(par.onlythreads).c_str());
    cmd.addVariable("VERBOSITY", par.createParameterString(par.onlyverbosity).c_str());

    std::string program(tmpDir + "/downloaddb.sh");
    FileUtil::writeFile(program, downloaddb_sh, downloaddb_sh_len);
    cmd.execProgram(program.c_str(), par.filenames);

    return(EXIT_SUCCESS);
}
