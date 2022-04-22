#include "Parameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
// #include "assembly.sh.h"
#include "LocalParameters.h"

// const char* binary_name = "Transannot";
// const char* tool_name = "Transannot";
// const char* tool_introduction = "Transannot: An annotation pipeline that predicts functions of de novo assembled transcripts based on homology search using MMseqs2";

 int assembly(int argc, const char **argv, const Command& command) {
    LocalParameters &par = LocalParameters::getLocalInstance();
    std::string outDb = par.filenames.back();
    std::string tmpDir = par.filenames.back();

    par.filenames.pop_back();
    std::string hash = SSTR(par.hashParameter(command.databases, par.filenames, par.assembly));
    if (par.reuseLatest) {
        hash = FileUtil::getHashFromSymLink(tmpDir + "/latest");
    }



    tmpDir = FileUtil::createTemporaryDirectory(tmpDir, hash);
    par.filenames.pop_back();
    par.filenames.push_back(tmpDir);

     CommandCaller cmd;
    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);

 }