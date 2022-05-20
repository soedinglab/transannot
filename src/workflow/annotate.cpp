#include "LocalParameters.h"
#include "Debug.h"
#include "Util.h"
#include "FileUtil.h"
#include "CommandCaller.h"
#include "annotate.sh.h" 

#include <cassert>

struct TransAnnotAnnotationOptions {
    const char *name;
    const char *description;
    const char *citation;
    enum InfoType {
        FUNCTION,
        FAMILY,
        STRUCTURE
    } type;

    static const char* formatType(InfoType type) {
        switch (type) {
            case FUNCTION:
                return "Function";
            case FAMILY:
                return "Family";
            case STRUCTURE:
                return "Structure";
            default:
                return "-";
        }
    }
}; 

std::vector<TransAnnotAnnotationOptions> annotationOptions = {
    {
        "KEGG",
        "KEGG - Kyoto Encyclopedia of Genes and Genomes. Used to map biological objects to molecular incteractions/ relations/ networks.",
        "Kanehisa, M. and Goto, S.; KEGG: Kyoto Encyclopedia of Genes and Genomes. Nucleic Acids Res. 28, 27-30 (2000). doi:10.1093/nar/28.1.27",
            TransAnnotAnnotationOptions::FUNCTION,
    },
    
    {
        "ExPASy",
        "ExPASy returns information relative to the nomenclature of enzymes. Describes each type of characterized enzyme with provided EC (Enzyme Comission) number.",
        "Gasteiger E., Gattiker A., Hoogland C., Ivanyi I., Appel R.D., Bairoch A. ExPASy: the proteomics server for in-depth protein knowledge and analysis. Nucleic Acids Res. doi:31:3784-3788(2003).",
            TransAnnotAnnotationOptions::FUNCTION,
    },

    {
        "Pfam",
        "Pfam - collection of Protein Families, each represented by multiple sequence allignment and HMMs.",
        "Mistry, J., Chuguransky, S., Williams, L., Qureshi, M., Salazar, G. A., Sonnhammer, E., Tosatto, S., Paladin, L., Raj, S., Richardson, L. J., Finn, R. D., & Bateman, A. (2021). Pfam: The protein families database in 2021. Nucleic acids research, 49(D1), D412–D419. doi: 10.1093/nar/gkaa913. PMID: 33125078; PMCID: PMC7779014.",
            TransAnnotAnnotationOptions::FAMILY,
    },

    {
        "EggNOG",
        "EggNOG - database of orthology relationships, functional annotation and evolutionary histories.",
        "Huerta-Cepas J, Szklarczyk D, Heller D, Hernández-Plaza A, Forslund SK, Cook H, Mende DR, Letunic I, Rattei T, Jensen LJ, von Mering C, Bork P. eggNOG 5.0: a hierarchical, functionally and phylogenetically annotated orthology resource based on 5090 organisms and 2502 viruses. Nucleic Acids Res. 2019 Jan 8;47(D1):D309-D314. doi: 10.1093/nar/gky1085. PMID: 30418610; PMCID: PMC6324079.",
            TransAnnotAnnotationOptions::FAMILY,
    },

    {
        "SCOP",
        "SCOP - Structural Classification Of Proteins. Provides classification of protein structures into a hierarchy e.g classes and folds.",
        "Lo Conte L, Ailey B, Hubbard TJ, Brenner SE, Murzin AG, Chothia C. SCOP: a structural classification of proteins database. Nucleic Acids Res. (2000);28(1):257-259. doi:10.1093/nar/28.1.257.",
            TransAnnotAnnotationOptions::STRUCTURE,
    },

    {
        "AlphaFold",
        "AlphaFold - AI system developed by DeepMind that predicts a protein's 3D structure based on its amino acid sequence.",
        "Jumper, J., Evans, R., Pritzel, A. et al. Highly accurate protein structure prediction with AlphaFold. Nature 596, 583–589 (2021). doi:10.1038/s41586-021-03819-2",
            TransAnnotAnnotationOptions::STRUCTURE,
    },
};

extern void appendPadded(std::string& dst, const std::string& values, size_t n);

std::string listAnnotationOptions(const Command &command, bool detailed) {
    size_t nameWidth = 4, infoWidth = 4;

    for (size_t i = 0; i < annotationOptions.size(); ++i) {
        nameWidth = std::max(nameWidth, strlen(annotationOptions[i].name));
        nameWidth = std::max(nameWidth, strlen(TransAnnotAnnotationOptions::formatType(annotationOptions[i].type)));
    }
    
    std::string description;
    description.reserve((1024));
    if (detailed) {
        description += " By ";
        description += command.author;
        description += "\n";
    }

    description += "\n ";
    appendPadded(description, "Name", nameWidth);
    description.append(1, '\t');
    appendPadded(description, "Information", infoWidth);
    description.append(1, '\n');

    for (size_t i = 0; i < annotationOptions.size(); ++i) {
        description.append("- ");
        appendPadded(description, annotationOptions[i].name, nameWidth);
        description.append(1, '\t');
        description.append(annotationOptions[i].type, infoWidth);
        description.append(1, '\n');
        if (detailed == false) {
            continue;
        }
        if (strlen(annotationOptions[i].description) > 0) {
            description.append(2,' ');
            description.append(annotationOptions[i].description);
            description.append(1, '\n');
        }
        if (strlen(annotationOptions[i].citation) > 0) {
            description.append(" Cite: ");
            description.append(annotationOptions[i].citation);
            description.append(1, '\n');
        }
    }
    description.append(1, '\n');
    return description;
}

// void setAnnotateDefault (Parameters *p){
    // p ->;

// }

// void setAnnotateMode (Parameters *p){
    // p ->;
// }



int annotate(int argc, const char **argv, const Command &command){
    LocalParameters &par = LocalParameters::getLocalInstance();
    par.parseParameters(argc, argv, command, false, Parameters::PARSE_ALLOW_EMPTY, 0);

    par.PARAM_COMPRESSED.removeCategory(MMseqsParameter::COMMAND_EXPERT);
    par.PARAM_THREADS.removeCategory(MMseqsParameter::COMMAND_EXPERT);
    par.PARAM_V.removeCategory(MMseqsParameter::COMMAND_EXPERT);

    std::string description =listAnnotationOptions(command, par.help);
    if (par.filenames.size() == 0 || par.help) {
        par.printUsageMessage(command, par.help ? MMseqsParameter::COMMAND_EXPERT : 0, description.c_str());
        EXIT(EXIT_SUCCESS);
    }

    ssize_t infoIdx = -1;
    for (ssize_t i = 0; i < annotationOptions.size(); ++i) {
        if (par.db1 == std::string(annotationOptions[i].name)) {
            infoIdx = i;
            break;
        }
    }

    if (infoIdx == -1) {
        par.printUsageMessage(command, par.help ? MMseqsParameter::COMMAND_EXPERT : 0, description.c_str());
        Debug(Debug::ERROR) << "Selected information " << par.db1 << " is not available\n";
        EXIT(EXIT_FAILURE);
    }

    // check whether tmp exists and try to create it if not
    std::string tmpDir = par.filenames.back();
    par.filenames.pop_back(); //removes the last element of the vector
    std::string hash = SSTR(par.hashParameter(command.databases, par.filenames, par.annotateworkflow));
    if (par.reuseLatest) {
        hash = FileUtil::getHashFromSymLink(tmpDir + "/latest");
    }
    tmpDir = FileUtil::createTemporaryDirectory(tmpDir, hash);
    par.filenames.pop_back();


    CommandCaller cmd;
    cmd.addVariable("TMP_PATH", tmpDir.c_str());
    cmd.addVariable("REMOVE_TMP", par.removeTmpFiles ? "TRUE" : NULL);
    cmd.addVariable("SEARCH_PAR", par.createParameterString(par.searchworkflow, true).c_str());
    cmd.addVariable("INFOSELECT_PAR", par.infoSelect == 1 ? "TRUE" : NULL);
    cmd.addVariable("CREATETSV_PAR", par.createParameterString(par.createtsv).c_str());
    // cmd.addVariable("THREADS_PAR", par.createParameterString(par.onlythreads).c_str());
    cmd.addVariable("VERBOSITY_PAR", par.createParameterString(par.onlyverbosity).c_str());

    std::string program(tmpDir + "/annotate.sh");
    FileUtil::writeFile(program.c_str(), annotate_sh, annotate_sh_len);
    cmd.execProgram(program.c_str(), par.filenames);
    
    return EXIT_SUCCESS;
}
