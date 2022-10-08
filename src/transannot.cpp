#include "LocalCommandDeclarations.h"
#include "LocalParameters.h"
#include "DownloadDatabase.h"

const int NO_CITATION = 0;
const char* binary_name = "transannot";
const char* tool_name = "TransAnnot";
const char* tool_introduction =
"TransAnnot: An annotation pipeline that predicts functions of de novo assembled transcripts based on homology search using MMSeqs2";
const char* main_author = "";
const char* show_extended_help = "1";
const char* show_bash_info = NULL;
extern const char* MMSEQS_CURRENT_INDEX_VERSION;
const char* index_version_compatible = MMSEQS_CURRENT_INDEX_VERSION;
bool hide_base_commands = true;
bool hide_base_downloads = false;
void (*validatorUpdate)(void) = 0;
std::vector<DatabaseDownload> externalDownloads = {};

LocalParameters& localPar = LocalParameters::getLocalInstance();

std::vector<struct Command> commands = {
      {"assemblereads",    assemblereads,   &localPar.assemblereads, COMMAND_MAIN,
            "Assembly of de novo transcriptomes on protein level with PLASS",
            "It is also possible to give already assembled (e.g. obtained from Trinity) files as input",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:fast(a|q)File[.gz|bz]> | <i:fastqFile1_1[.gz]> ... <i:fastqFileN_1[.gz]> <o:fastaFile> <seqDB> <tmpDir>",
            NO_CITATION, {{"fast[a|q]File[.gz|bz]", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA | DbType::VARIADIC,  &DbValidator::flatfile},
                        {"fastaFile", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"seqDB", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


    {"downloaddb",  downloaddb,     &localPar.downloaddb, COMMAND_MAIN,
            "Download protein database to run search against",
            "We recommend to download eggNOG (profiles database), but there are more possible protein databases (see mmseqs databases) \n"
            "transannot downloaddb eggNOG outpath/eggNOGDB tmp",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:selection> <o:outDB> <tmpDir>",
            NO_CITATION, {{"selection", 0, DbType::ZERO_OR_ALL, &DbValidator::empty},
                        {"outDB", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


    {"annotate",    annotate, &localPar.annotateworkflow, COMMAND_MAIN,
            "Run RBH of MMseqs2 to find homology, depending on UniProtID get further information about transcriptome functions",
            "Information from KEGG, ExPASy, Pfam, EggNOG and other databases may be assigned. For details call annotate -h or --help",
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
            "Only ID mapping database should be downloaded in advance, for MMseqs2 databases just provide name of the profile database",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:fast(a|q)File[.gz|bz]> | <i:fastqFile1_1[.gz]> ... <i:fastqFileN_1[.gz]> <i:targetDB> <i:idMappingDB> <o:outFile> <tmpDir>",
            NO_CITATION, {{"fast[a|q]File[.gz|bz]", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA | DbType::VARIADIC,  &DbValidator::flatfile},
                        {"targetDB", 0, DbType::ZERO_OR_ALL, &DbValidator::empty},
                        {"idMappingDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"outFile", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


    {"annotateprofiles", annotateprofiles, &localPar.annotateprofiles, COMMAND_EXPERT,
            "Build profiles and run profile-against-profile search",
            "Profile-against-profile search may be more sensitive than profile-against-sequence or sequence-against-sequence",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:queryDB> <i:targetDB> <o:outFile> <tmpDir>",
            NO_CITATION, {{"queryDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"targetDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"outFile", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


    {"createquerydb",    createquerydb, &localPar.createquerydb, COMMAND_MAIN,
            "Create MMseqs database from assembled sequences (with transannot annotate or other tool)",
            "MMseqs uses its own database format to avoid slowing down of the system, that is why if transcriptome is assembled not with PLASS, it is obligatory to create using MMseqs DB",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:fast[a|q]File> <o:sequenceDB> <tmpDir>",
            NO_CITATION, {{"fast[a|q]File", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"sequenceDB", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}},


    {"contamination",   contamination, &localPar.contaminationworkflow, COMMAND_EXPERT,
            "Check for the contamination using MMseqs taxonomy",
            "Assigns taxaIDs and then finds organisms with minor frequency",
            "Mariia Zelenskaia mariia.zelenskaia@mpinat.mpg.de & Yazhini A. yazhini@mpinat.mpg.de",
            "<i:queryDB>",
            NO_CITATION, {{"queryDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA, &DbValidator::sequenceDb},
                        {"targetDB", DbType::ACCESS_MODE_INPUT, DbType::NEED_DATA|DbType::NEED_HEADER|DbType::NEED_TAXONOMY, &DbValidator::taxSequenceDb},
                        {"taxReports", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::flatfile},
                        {"tmpDir", DbType::ACCESS_MODE_OUTPUT, DbType::NEED_DATA, &DbValidator::directory}}}
};
