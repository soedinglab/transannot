#include "Parameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
//#include "downloaddb.sh.h"
#include "LocalParameters.h"

int downloaddb(int argc, const char **argv, const Command& command) {
    LocalParameters &par = LocalParameters::getLocalInstance();

    std::string outDb = par.filenames.back();
    std::string tmpDir = par.filenames.back();
    
    par.filenames.pop_back();
    std::string hash = SSTR(par.hashParameter(command.databases, par.filenames, par.downloaddb));
    if (par.reuseLatest) {
        hash = FileUtil::getHashFromSymLink(tmpDir + "/latest");
    }
    tmpDir = FileUtil::createTemporaryDirectory(tmpDir, hash);

    CommandCaller cmd;
    cmd.addVariable("TMP_PATH", tmpDir.c_str());
    cmd.addVariable("OUTDB", outDb.c_str());
    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);
    //cmd.addVariable("");

    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);

    std::string program(tmpDir + "/downloaddb.sh");
    FileUtil::writeFile(program, downloaddb_sh, downloaddb_sh_len);
    cmd.execProgram(program.c_str(), par.filenames);

    // never get here
    assert(false);
    EXIT(EXIT_FAILURE);
}
