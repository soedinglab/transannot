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

    std::vector<MMseqsParameter*> assembly;
    std::vector<MMseqsParameter*> annotateworkflow;
    std::vector<MMseqsParameter*> downloaddb;
    std::vector<MMseqsParameter*> contaminationworkflow;
    std::vector<MMseqsParameter*> createdb;

    PARAMETER(PARAM_INFORMATION_SELECTION)


    std::vector<MMseqsParameter*> combineList(const std::vector<MMseqsParameter*> &par1,
                                            const std::vector<MMseqsParameter*> &par2);

    int infoSelect;

private:
    LocalParameters() :
        Parameters(),
        PARAM_INFORMATION_SELECTION(PARAM_INFORMATION_SELECTION_ID, "--information-selection", "Information about sequence", "What information about the input sequence should be provided, KEGG: 0, ExPASy: 1, Pfam: 2, eggNOG: 3, SCOP: 4, AlphaFold: 5, all: 6 ", typeid(int), (void *) &infoSelect, "^[0-6]{1}$")


    {
        annotateworkflow.push_back(&PARAM_HELP);
        annotateworkflow.push_back(&PARAM_HELP_LONG);
        annotateworkflow.push_back(&PARAM_INFORMATION_SELECTION);


        infoSelect = 6;
    }
    LocalParameters(LocalParameters const&);
    ~LocalParameters() {};
    void operator=(LocalParameters const&);
};

#endif