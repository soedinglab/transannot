#include "LocalCommandDeclarations.h"
#include "LocalParameters.h"
#include "DownloadDatabase.h"
#include "Prefiltering.h"

const int NO_CITATION = 0;
const char* binary_name = "transannot";
const char* tool_name = "TransAnnot";
const char* tool_introduction =
"TransAnnot - a fast transcriptome annotation pipeline";
const char* main_author = "Mariia Zelenskaia <mariia.zelenskaia@mpinat.mpg.de>";
const char* show_extended_help = "1";
const char* show_bash_info = NULL;
extern const char* MMSEQS_CURRENT_INDEX_VERSION;
const char* index_version_compatible = MMSEQS_CURRENT_INDEX_VERSION;
bool hide_base_commands = true;
bool hide_base_downloads = false;
void (*validatorUpdate)(void) = 0;
std::vector<DatabaseDownload> externalDownloads = {};
std::vector<KmerThreshold> externalThreshold = {};

LocalParameters& localPar = LocalParameters::getLocalInstance();

std::vector<struct Command> transannotcommands = {
      {"assemblereads",    assemblereads,   &localPar.assemblereads, COMMAND_MAIN,
            "Assembly of de novo transcriptomes on protein level with PLASS \n",
            "It is also possible to give already assembled (e.g. obtained from Trinity) files as input \n",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:fast(a|q)File[.gz|bz]> | <i:fastqFile1_1[.gz]> ... <i:fastqFileN_1[.gz]> <o:fastaFile> <o:seqDB> <tmpDir>",
            NO_CITATION, {{"fast[a|q]File[.gz|bz]", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA | DbType::VARIADIC,  &DbValidator::flatfile},
                        {"fastaFile", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"seqDB", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


    {"downloaddb",  downloaddb,     &localPar.downloaddb, COMMAND_MAIN,
            "Download protein database to run search against \n"
            "User should download 3 databases: 2 profile DBs and 1 sequence DB.(see mmseqs databases) \n"
            "Our recommendations are Pfam-A.full, eggNOG (profile DBs) and SwissProt (sequence DB) \n",
            "transannot downloaddb eggNOG outpath/eggNOGDB tmp \n",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:selection> <o:outDB> <tmpDir>",
            NO_CITATION, {{"selection", 0, DbType::ZERO_OR_ALL, &DbValidator::empty},
                        {"outDB", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


    {"annotate",    annotate, &localPar.annotateworkflow, COMMAND_MAIN,
            "Run MMseqs2 searches to find homology, depending on obtained IDs get further information about transcriptome functions",
            NULL,
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:queryDB> <i:profile1TargetDB> <i:profile2TargetDB> <i:seqTargetDB> <o:outFile> <tmpDir>",
            NO_CITATION, {{"queryDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"profile1TargetDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::profileDb},
                        {"profile2TargetDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::profileDb},
                        {"seqTargetDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"outFile", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


    {"easytransannot",    easytransannot, &localPar.easytransannot, COMMAND_EASY,
            "Easy module for simple one-step reads assembly and transcriptome annotation",
            NULL,
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de \n",
            "<i:fast(a|q)File[.gz|bz]> | <i:fastqFile1_1[.gz]> ... <i:fastqFileN_1[.gz]> <i:targetDB> <i:targetDB> <i:targetDB> <o:outFile> <tmpDir>",
            NO_CITATION, {{"fast[a|q]File[.gz|bz]", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA | DbType::VARIADIC,  &DbValidator::flatfile},
                        {"targetDB", 0, DbType::ZERO_OR_ALL, &DbValidator::empty},
                        {"targetDB", 0, DbType::ZERO_OR_ALL, &DbValidator::empty},
                        {"targetDB", 0, DbType::ZERO_OR_ALL, &DbValidator::empty},
                        {"outFile", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


//     {"annotateprofiles", annotateprofiles, &localPar.annotateprofiles, COMMAND_EXPERT,
//             "Build profiles and run profile-against-profile search\n",
//             "Profile-against-profile search may be more sensitive than profile-against-sequence or sequence-against-sequence\n",
//             "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
//             "<i:queryDB> <i:targetDB> <o:outFile> <tmpDir>",
//             NO_CITATION, {{"queryDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
//                         {"targetDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
//                         {"outFile", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
//                         {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


    {"createquerydb",    createquerydb, &localPar.createquerydb, COMMAND_MAIN,
            "Create MMseqs database from assembled sequences (with transannot annotate or other tool) \n",
            "MMseqs uses its own database format to avoid slowing down of the system, that is why if transcriptome is assembled not with PLASS, it is obligatory to create using MMseqs DB",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:fast[a|q]File> <o:sequenceDB> <tmpDir>",
            NO_CITATION, {{"fast[a|q]File", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"sequenceDB", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},

   {"annotatecustom", annotatecustom, &localPar.annotatecustom, COMMAND_MAIN,
            "Annotate using a custom, user-provided DB",
            "Provided custom DB will be converted into the MMseqs format which is followed by a search.",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de",
            "<i:queryDB> <i:customDB> <o:outFile> <tmpdir>",
            NO_CITATION, {{"queryDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"customDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"outFile", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}}

extern std::vector<Command> baseCommands;
 void init() {
     registerCommands(&baseCommands);
     registerCommands(&metaeukCommands);
 }

 void (*initCommands)(void) = init;
 void initParameterSingleton() { new LocalParameters; }


//     {"contamination",   contamination, &localPar.contaminationworkflow, COMMAND_EXPERT,
//             "Check for the contamination using MMseqs taxonomy \n",
//             "Assigns taxaIDs and then finds organisms with minor frequency",
//             "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
//             "<i:queryDB>",
//             NO_CITATION, {{"queryDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
//                         {"targetDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA|DbType::NEED_HEADER|DbType::NEED_TAXONOMY, &DbValidator::taxSequenceDb},
//                         {"taxReports", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
//                         {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}}
};
