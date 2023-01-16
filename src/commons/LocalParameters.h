#ifndef LOCALPARAMETERS_H
#define LOCALPARAMETERS_H

#include <Parameters.h>

class LocalParameters : public  Parameters {
public:
    static void initInstance() {
        new LocalParameters;
    }

    static LocalParameters& getLocalInstance() {
        if (instance == nullptr) {
            initInstance();
        }
        return static_cast<LocalParameters&>(LocalParameters::getInstance());
    }

    std::vector<MMseqsParameter*> assemblereads;
    std::vector<MMseqsParameter*> annotateworkflow;
    std::vector<MMseqsParameter*> downloaddb;
    // std::vector<MMseqsParameter*> contaminationworkflow;
    std::vector<MMseqsParameter*> createquerydb;
    // std::vector<MMseqsParameter*> annotateprofiles;
    std::vector<MMseqsParameter*> easytransannot;

    // annotate
    PARAMETER(PARAM_OUTPUT_SIMPLE)
    PARAMETER(PARAM_NO_PERFORM_CLUST)

    // not yet implemented
    // PARAMETER(PARAM_INFORMATION_SELECTION)
    // PARAMETER(PARAM_TAXONOMYID)

    // int infoSelect;
    // int taxId;
    int simpleOutput;
    int noPerformClust;

private:
    LocalParameters() :
        Parameters(),
        // PARAM_INFORMATION_SELECTION(PARAM_INFORMATION_SELECTION_ID, "--information-selection", "Information about sequence", "What information about the input sequence should be provided, KEGG: 0, ExPASy: 1, Pfam: 2, eggNOG: 3, SCOP: 4, AlphaFold: 5, all: 6 ", typeid(int), (void *) &infoSelect, "^[0-6]{1}$"),
        // PARAM_TAXONOMYID(PARAM_TAXONOMYID_ID, "--taxid", "Taxonomy ID", "Taxonomy ID to run search against proteins from particular organism. 10-digits unique number", typeid(int), (void *) &taxId, "^[0-9]{7}$")
        PARAM_OUTPUT_SIMPLE(PARAM_OUTPUT_SIMPLE_ID, "--simple-output", "Simplified output", "Provide only query, target IDs and information from UniProt in the output file. No information about alignment (eg. sequence identity and bit score)", typeid(bool), (void *) &simpleOutput, "", MMseqsParameter::COMMAND_COMMON | MMseqsParameter::COMMAND_EXPERT),
        PARAM_NO_PERFORM_CLUST(PARAM_NO_PERFORM_CLUST_ID, "--no-run-clust", "Don't linclust for the redundancy reduction", "Per default there is linclust of mmseqs performed for the redundancy reduction. If you don't want it, provide this tag", typeid(bool), (void *) &noPerformClust, "", MMseqsParameter::COMMAND_COMMON)
    {
        assemblereads.push_back(&PARAM_CREATEDB_MODE);
        assemblereads.push_back(&PARAM_COMPRESSED);
        assemblereads.push_back(&PARAM_REMOVE_TMP_FILES);
        assemblereads.push_back(&PARAM_THREADS);
        assemblereads.push_back(&PARAM_V);

        annotateworkflow.push_back(&PARAM_HELP);
        annotateworkflow.push_back(&PARAM_HELP_LONG);
        annotateworkflow.push_back(&PARAM_S); //sensitivity
        annotateworkflow.push_back(&PARAM_OUTPUT_SIMPLE);
        annotateworkflow.push_back(&PARAM_NO_PERFORM_CLUST);
        // annotateworkflow.push_back(&PARAM_INFORMATION_SELECTION);
        // annotateworkflow.push_back(&PARAM_TAXONOMYID);
        annotateworkflow.push_back(&PARAM_REMOVE_TMP_FILES);
        annotateworkflow.push_back(&PARAM_COMPRESSED);
        annotateworkflow.push_back(&PARAM_C);
        annotateworkflow.push_back(&PARAM_MIN_SEQ_ID);
        annotateworkflow.push_back(&PARAM_THREADS);
        annotateworkflow.push_back(&PARAM_V);

        // annotateprofiles = annotateworkflow; //same parameters so far, but later combineList() may be used

        downloaddb.push_back(&PARAM_THREADS);
        downloaddb.push_back(&PARAM_V);
        // downloaddb.push_back(&PARAM_TAXONOMYID);

        // contaminationworkflow.push_back(&PARAM_COMPRESSED);
        // contaminationworkflow.push_back(&PARAM_REMOVE_TMP_FILES);
        // contaminationworkflow.push_back(&PARAM_THREADS);
        // contaminationworkflow.push_back(&PARAM_V);

        createquerydb.push_back(&PARAM_REMOVE_TMP_FILES);
        createquerydb.push_back(&PARAM_THREADS);
        createquerydb.push_back(&PARAM_V);

        easytransannot = combineList(assemblereads, annotateworkflow);
        easytransannot = combineList(easytransannot, downloaddb);
        easytransannot = combineList(easytransannot, createquerydb);

        // default values
        // infoSelect = 6;
        createdbMode = 1;
        simpleOutput = false; 
        noPerformClust = false;
        seqIdThr = 0.6;

    }
    LocalParameters(LocalParameters const&);
    ~LocalParameters() {};
    void operator=(LocalParameters const&);
};

#endif