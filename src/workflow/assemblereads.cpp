#include "Parameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
#include "assemblereads.sh.h"
#include "LocalParameters.h"


 int assemblereads(int argc, const char **argv, const Command& command) {
    LocalParameters &par = LocalParameters::getLocalInstance();
    par.parseParameters(argc, argv, command, true, 0, 0);
    
    std::string tmpDir = par.filenames.back();
    // std::string hash = SSTR(par.hashParameter(command.databases, par.filenames, *command.params));
    // if (par.reuseLatest) {
    //     hash = FileUtil::getHashFromSymLink(tmpDir + "/latest");
    // }

    // tmpDir = FileUtil::createTemporaryDirectory(tmpDir, hash);
    par.filenames.pop_back();
    std::string outDb = par.filenames.back();
    par.filenames.pop_back();
    std::string assembly = par.filenames.back();
    par.filenames.pop_back();

    CommandCaller cmd;
    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);
    cmd.addVariable("TMP_PATH", tmpDir.c_str());
    cmd.addVariable("RESULTS", outDb.c_str());
    cmd.addVariable("ASSEMBLY", assembly.c_str());

    std::string program = tmpDir + "/assemblereads.sh";
    FileUtil::writeFile(program, assemblereads_sh, assemblereads_sh_len);
    cmd.execProgram(program.c_str(), par.filenames);

    return EXIT_SUCCESS;
 }