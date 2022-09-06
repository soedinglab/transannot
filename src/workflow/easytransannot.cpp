#include "Parameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
#include "DownloadDatabase.h"
#include "easytransannot.sh.h"
#include "LocalParameters.h"

extern std::vector<DatabaseDownload> downloads;
int easytransannot(int argc, const char **argv, const Command& command) {
    LocalParameters &par = LocalParameters::getLocalInstance();
    par.parseParameters(argc, argv, command, true, 0, 0);

    std::string tmpDir = par.filenames.back();
    par.filenames.pop_back();
    std::string hash = SSTR(par.hashParameter(command.databases, par.filenames, par.easytransannot));
    if (par.reuseLatest) {
        hash = FileUtil::getHashFromSymLink(tmpDir + "/latest");
    }
    tmpDir = FileUtil::createTemporaryDirectory(tmpDir, hash);


    CommandCaller cmd;
    cmd.addVariable("TMP_PATH", tmpDir.c_str());
    std::string resDb = par.filenames.back();
    cmd.addVariable("RESULTS", resDb.c_str());
    par.filenames.pop_back();
    std::string mapDb = par.filenames.back();
    cmd.addVariable("MAPPING_DB", mapDb.c_str());
    par.filenames.pop_back();
    std::string targetDb = par.filenames.back();
    cmd.addVariable("TARGET", targetDb.c_str());
    par.filenames.pop_back();
    
    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);
    cmd.addVariable("VERBOSITY_PAR", par.createParameterString(par.onlyverbosity).c_str());
    cmd.addVariable("THREADS_PAR", par.createParameterString(par.onlythreads).c_str());

    std::string program = tmpDir + "/easytransannot.sh";
    FileUtil::writeFile(program, easytransannot_sh, easytransannot_sh_len);
    cmd.execProgram(program.c_str(), par.filenames);
    
    return EXIT_SUCCESS;
} 