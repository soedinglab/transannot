#ifndef LOCALPARAMETERS_H
#define LOCALPARAMETERS_H

#include <Parameters.h>

class LocalParameters : public  Parameters {
public:
    static void initInstance() {
        //new LocalParameters;
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

private:

    LocalParameters(LocalParameters const&);
    ~LocalParameters() {};
    void operator=(LocalParameters const&);
};

#endif