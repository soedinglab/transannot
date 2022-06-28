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
    std::string outDB = par.filenames.back();
    par.filenames.pop_back();
    std::string targetDB = par.filenames.back();
    par.filenames.pop_back();
    // int i=0
    // while (downloads[i].name == targetDB && downloads[i].dbtype == Parameters::DBTYPE_HMM_PROFILE) {
    //     i++
    // }
    // if (i > downloads.size()) {
    // }

    CommandCaller cmd;
    cmd.addVariable("TMP_PATH", tmpDir.c_str());

    // TODO check for the DBtype Parameters::DBTYPE_HMM_PROFILE,
    return EXIT_SUCCESS;
}