#include "LocalParameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
#include "annotate.sh.h" 

extern const char *binary_name;

int annotate(int argc, const char **argv, const Command &command){
    LocalParameters &par = LocalParameters::getLocalInstance();
    par.parseParameters(argc, argv, command, true, 0, 0);

    // check whether tmp exists and try to create it if not
    std::string tmpDir = par.filenames.back();
    std::string hash = SSTR(par.hashParameter(command.databases, par.filenames, par.annotateworkflow));
    if (par.reuseLatest) {
        hash = FileUtil::getHashFromSymLink(tmpDir + "/latest");
    }
    tmpDir = FileUtil::createTemporaryDirectory(tmpDir, hash);

    CommandCaller cmd;

    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);
    cmd.addVariable("SIMPLE_OUTPUT", par.simpleOutput ? "TRUE" : NULL);
    cmd.addVariable("NO_LINCLUST", par.noPerformClust ? "TRUE" : NULL);
    cmd.addVariable("SEARCH_PAR", par.createParameterString(par.searchworkflow, true).c_str());
    cmd.addVariable("SUMMARIZE_PAR", par.createParameterString(par.summarizeresult).c_str());
    // cmd.addVariable("INFOSELECT_PAR", infoSelection.c_str());
    // cmd.addVariable("TAXONOMY_ID", par.taxId == 1 ? "TRUE" : NULL);
    cmd.addVariable("CLUSTER_PAR", par.createParameterString(par.linclustworkflow, true).c_str());
    if (par.noPerformClust==false){
        std::vector<MMseqsParameter*> clustwithoudidentparam;
        for (size_t i=0; i<par.linclustworkflow.size(); i++){
            if (par.linclustworkflow[i]->uniqid != par.PARAM_MIN_SEQ_ID.uniqid){
                clustwithoudidentparam.push_back(par.linclustworkflow[i]);
            }
        }
        cmd.addVariable("CLUSTER_PAR", par.createParameterString(clustwithoudidentparam).c_str());
    }
    cmd.addVariable("RESULT2REPSEQ_PAR", par.createParameterString(par.result2repseq).c_str());
    cmd.addVariable("CREATETSV_PAR", par.createParameterString(par.createtsv).c_str());
    // cmd.addVariable("MIN_SEQ_ID", SSTR(par.seqIdThr).c_str()); 
    cmd.addVariable("THREADS_PAR", par.createParameterString(par.onlythreads).c_str());
    cmd.addVariable("VERBOSITY_PAR", par.createParameterString(par.onlyverbosity).c_str());

    FileUtil::writeFile(tmpDir + "/annotate.sh", annotate_sh, annotate_sh_len);
    std::string program(tmpDir + "/annotate.sh");
    cmd.execProgram(program.c_str(), par.filenames);
    
    return EXIT_SUCCESS;
}
