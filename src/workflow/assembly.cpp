#include "Parameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
#include "assembly.sh.h"
#include "LocalParameters.h"


 int assembly(int argc, const char **argv, const Command& command) {
    LocalParameters &par = LocalParameters::getLocalInstance();
    std::string outDb = par.filenames.back();
    std::string tmpDir = par.filenames.back();

    std::string hash = SSTR(par.hashParameter(command.databases, par.filenames, *command.params));
    if (par.reuseLatest) {
        hash = FileUtil::getHashFromSymLink(tmpDir + "/latest");
    }

    tmpDir = FileUtil::createTemporaryDirectory(tmpDir, hash);

    char *p = realpath(tmpDir.c_str(), NULL);
    if (p == NULL) {
        Debug(Debug::ERROR) << "Could not get the real path of " << tmpDir << "!\n";
    }

    CommandCaller cmd;
    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);
    cmd.addVariable("TMP_PATH", p);
    par.filenames.pop_back();
    free(p);

    FileUtil::writeFile(tmpDir + "assembly.sh", assembly_sh, assembly_sh_len);
    std::string program(tmpDir + "assembly.sh");
    cmd.execProgram(program.c_str(), par.filenames);

    return EXIT_SUCCESS;
 }