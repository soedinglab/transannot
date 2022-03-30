//
// Created by mad on 9/22/15.
//
#include "EvaluateResults.h"
#include <cstddef>
#include <iostream>
#include <fstream>
#include <unistd.h>
#include <iomanip>
#include <algorithm>
#include <getopt.h>

#include "PatternCompiler.h"
#include "EvaluateResults.h"
#include "kseq.h"

#define MAX_FILENAME_LIST_FILES 4096
KSEQ_INIT(int, read)

int main(int argc, char ** argv){
    const char* short_options = "isx:r:";
    static struct option long_options[] = {
        {"res-size", required_argument, NULL, 'r'},
        {"rocx", required_argument, NULL, 'x'},
        {"super-fam", no_argument, NULL, 's'},
        {"ignore-fp", no_argument, NULL, 'i'},
        {NULL, 0, NULL, 0}
    };

    const double defaultResSize = 1000.0;
    double resSize = defaultResSize;
    const size_t defaultRocX = 1;
    size_t rocx = defaultRocX;
    bool superFam = false;
    bool ignoreFP = false;
    while (1) {
        int option_index = 0;

        int opt;
        if ((opt = getopt_long(argc, argv, short_options, long_options, &option_index)) == -1) {
            break;
        }

        switch (opt) {
            case 'r':
                resSize = strtod(optarg, NULL);
                break;
            case 'x':
                rocx = strtoull(optarg, NULL, 10);
                break;
            case 's':
                superFam = true;
                break;
            case 'i':
                ignoreFP = true;
                break;
            default:
                break;
        }
    }

    const int remaining_arguments = argc - optind;
    if (remaining_arguments < 4) {
        std::cerr << "Please provide input and output files." << std::endl;
        return EXIT_FAILURE;
    }

    std::string queryFasta(argv[optind++]);
    std::string targetFasta(argv[optind++]);
    std::string resultFile(argv[optind++]);
    std::string outputResultFile(argv[optind++]);

    // legacy parameters, use new parameters
    if (remaining_arguments >= 5 && resSize == defaultResSize) {
        std::cerr << "Please port the script to new parameters." << std::endl;
        resSize = strtod(argv[optind++], NULL);

        if (remaining_arguments == 6 && rocx == defaultRocX) {
            rocx = strtoull(argv[optind++], NULL, 10);
        } else {
            std::cerr << "Too many parameters!" << std::endl;
            exit(EXIT_FAILURE);
        }
    }

    std::unordered_map<std::string, std::vector<SCOP>*> scopLoopup;
    std::cout << "Read query fasta" << std::endl;
    std::unordered_map<std::string, size_t> whatever;
    readFamDefFromFasta(queryFasta, scopLoopup, whatever, false);
    whatever.clear();
    std::cout << std::endl;

    std::cout << "Read target fasta " << std::endl;
    std::unordered_map<std::string, size_t> scopSizeLoopup;
    //std::cout << scopLoopup["d12asa_"]->at(0) << " " << famSizeLoopup[scopLoopup["d1acfa_"]->at(0)] <<std::endl;
    readFamDefFromFasta(targetFasta, scopLoopup, scopSizeLoopup, true);
    std::cout << std::endl;

    std::cout << "Read result fasta " << std::endl;
    std::vector<std::pair<size_t, std::string>> supFam;
    for (std::unordered_map<std::string, size_t>::const_iterator it = scopSizeLoopup.cbegin();
         it != scopSizeLoopup.cend(); ++it) {
        size_t n = std::count(it->first.begin(), it->first.end(), '.');
        if(n == 2) {
            supFam.push_back(std::make_pair(it->second, it->first));
        }
    }
    std::sort(supFam.begin(), supFam.end());
    double sum = 0.0;
    for(size_t i = 0; i < supFam.size(); i++){
        sum += (double)supFam[i].first;
//        std::cout << supFam[i].second << "\t" << supFam[i].first << std::endl;
    }
    std::cout << "N=" << supFam.size() << " Sum=" << sum << " Avg=" << (sum/ supFam.size());
    std::cout << " Median=" << supFam[supFam.size()/2].first;
    std::cout << " 1/4=" << supFam[supFam.size()/4].first;
    std::cout << " 3.5/4=" << supFam[(supFam.size()/4) * 3.5].first << std::endl;

    FILE * fasta_file = fopen(queryFasta.c_str(), "r");
    kseq_t *seq = kseq_init(fileno(fasta_file));
    size_t entries_num = 0;
    double overall_ignore_cnt =0.0;
    double overall_fp =0.0;
    double overall_tp =0.0;
    double early_break_cnt=0.0;
    std::vector<Roc5Value> roc5Vals;
    std::vector<Hits> allHits;
    // iterate over all queries
    size_t queryCount = 0;
    while (kseq_read(seq) >= 0) {
        std::string query = seq->name.s;
        queryCount++;
//        std::cout << query << std::endl;
        std::vector<SCOP> * qFams = scopLoopup[query];
        std::vector<std::pair<std::string, double>> resIds = readResultFile(query, resultFile, resSize);
        EvaluateResult eval = evaluateResult(query, qFams, scopLoopup, allHits, resIds, rocx, superFam, ignoreFP);
//            if(query.compare("d2py5a2") == 0){
//                for(size_t j = 0; j < resIds.size(); j++){
//                    std::cout << resIds[j] << " " << scopLoopup[resIds[j]]->at(0) << std::endl;
//                }
//            }
        overall_ignore_cnt +=eval.ignore_cnt;
        overall_fp += eval.fp_cnt;
        overall_tp += eval.tp_cnt;

        if(eval.fp_cnt < rocx) {
            early_break_cnt++;
        }

        double all_auc = eval.auc + (rocx - eval.fp_cnt) * eval.tp_cnt;

        double qFamSize = 0.0;
        std::string qFamStr;
        for(size_t i = 0; i < qFams->size(); i++) {
            SCOP qFam = qFams->at(i);
            if (superFam) {
                qFamSize = std::min(qFamSize + scopSizeLoopup[qFam.superFam], resSize);
                qFamStr.append(qFams->at(i).superFam).append(",");
            } else {
                qFamSize = std::min(qFamSize + scopSizeLoopup[qFam.fam], resSize);
                qFamStr.append(qFams->at(i).fam).append(",");
            }
        }
        if(qFamSize > 0){
            double roc5val = all_auc / (rocx * qFamSize);
            if (roc5val > 1.0){
                std::cout << "ROC5 = " << roc5val << " for query " << query << std::endl;
                std::cout << "Fam = " << qFamStr << " # family members: " << qFamSize << std::endl;
                std::cout << "Results size: " << resIds.size() << std::endl;
                std::cout << "TPs: " << eval.tp_cnt << ", FPs: " << eval.fp_cnt << ", AUC: " << eval.auc  << std::endl;
            }else{
                roc5Vals.push_back(Roc5Value(query, qFamStr, qFamSize, roc5val,
                                             eval.tp_cnt, eval.fp_cnt, eval.ignore_cnt, resIds.size()));
            }
        }else {
            std::cout << "Fam = " << qFamStr << " for query " << query << ", # family members: " << qFamSize << std::endl;
        }
    }

    std::sort(roc5Vals.begin(), roc5Vals.end(), sortDescByRoc5());

    printf("Query\t\tFam\t\t\t\tRoc5\tFamSize\tTPs\tFP\tResSize\tIGN)\n");
    for(size_t i = 0; i < roc5Vals.size(); i++) {
        Roc5Value roc5Value = roc5Vals[i];
        printf("%s\t\t%-30.30s\t%.7f\t%5zu\t%5zu\t%5zu\t%5zu\t%5zu\n", roc5Value.query.c_str(), roc5Value.qFams.c_str(),
               roc5Value.roc5val, roc5Value.qFamSize, roc5Value.tp_cnt, roc5Value.fp_cnt,
               roc5Value.resultSize, roc5Value.ignore_cnt);
    }
    double fpsWithSmallEvalue=0;
    double EVAL_THRESHOLD = 1E-3;
    std::map<std::string, size_t > mostQueriesWithSmallEval;
    for(size_t i = 0; i < allHits.size(); i++) {
        if(allHits[i].evalue < EVAL_THRESHOLD && allHits[i].status == Hits::FP){
            fpsWithSmallEvalue++;
            mostQueriesWithSmallEval[allHits[i].query]++;
        }
    }
//    std::cout << "Top high scoring queries:" << std::endl;
    std::vector<std::pair<size_t, std::string>> mostQueriesWithSmallEvalVec;
    for (std::map<std::string, size_t >::iterator it = mostQueriesWithSmallEval.begin();
         it != mostQueriesWithSmallEval.end(); it++ ) {
        mostQueriesWithSmallEvalVec.push_back(std::make_pair(it->second, it->first));
    }
    std::sort(mostQueriesWithSmallEvalVec.begin(), mostQueriesWithSmallEvalVec.end());
/*    for (int i = mostQueriesWithSmallEvalVec.size(); i > 0; i--) {
        std::cout << mostQueriesWithSmallEvalVec[i-1].second << " " << mostQueriesWithSmallEvalVec[i-1].first << std::endl;
    }
*/
    std::sort(allHits.begin(), allHits.end(), sortFalsePositvesByEval());

    std::cout << "Top 50 FP:" << std::endl;
    size_t cnt=0;
    for(size_t i = 0; i < allHits.size(); i++) {
        if(allHits[i].status == Hits::FP){
            std::cout << cnt + 1 << ": " << allHits[i].query << " " << allHits[i].target << " " << allHits[i].evalue << std::endl;
            std::vector<SCOP> * scopTarget;
            if(scopLoopup.find(allHits[i].target) == scopLoopup.end()){
                scopTarget = NULL;
            }else {
                scopTarget =  scopLoopup[allHits[i].target];
            }
            std::vector<SCOP> * scopQuery =  scopLoopup[allHits[i].query];
            std::cout << "Q=";
            for(size_t j = 0; j < scopQuery->size(); j++){
                if (superFam) {
                    std::cout << " " << scopQuery->at(j).superFam << "(" << scopQuery->at(j).evalue << ")";
                } else {
                    std::cout << " " << scopQuery->at(j).fam << "(" << scopQuery->at(j).evalue << ")";
                }
            }
            std::cout << std::endl;
            std::cout << "T=";
            if(scopTarget == NULL){
                std::cout << " Inverse";
            }else {
                for(size_t j = 0; j < scopTarget->size(); j++){
                    if (superFam) {
                        std::cout << " " << scopTarget->at(j).superFam << "(" << scopTarget->at(j).evalue << ")";
                    } else {
                        std::cout << " " << scopTarget->at(j).fam << "(" << scopTarget->at(j).evalue << ")";
                    }
                }
            }
            std::cout << std::endl;
            std::cout << std::endl;

            cnt++;
            if(cnt==50) {
                break;
            }
        }
    }
    kseq_destroy(seq);
    fclose(fasta_file);

    writeAnnoatedResultFile(outputResultFile, allHits);

//    size_t res_cnt = 0;
//    std::cout << res_cnt  << " result lists checked." << std::endl;
    std::cout << early_break_cnt << " result lists did not contain " << rocx << " FPs." << std::endl;
    std::cout << "Results contains " << overall_tp << " TPs and " << overall_fp << " FPs." << std::endl;
    std::cout << "Total FPs " << fpsWithSmallEvalue << " of " << mostQueriesWithSmallEvalVec.size() << " queries have an eval < " << EVAL_THRESHOLD << "." << std::endl;
    std::cout << overall_ignore_cnt << " sequence pairs ignored (different family, same fold)" << std::endl;

    writeRoc5Data(outputResultFile, roc5Vals, 0.01);

    std::sort(allHits.begin(), allHits.end(), sortFalsePositvesByEval());
    writeRocData(outputResultFile, allHits, 10000);
    writeFDRData(outputResultFile, allHits, roc5Vals, 1E-50);
    writeEvalueData(outputResultFile, allHits, roc5Vals, queryCount, 1E-50);

    return EXIT_SUCCESS;
}

void writeAnnoatedResultFile(std::string resultFile, std::vector<Hits> & hits) {
    std::ofstream outFile(resultFile + ".annotated_result");
    for (size_t i = 0; i < hits.size(); i++) {
        outFile << hits[i].query << "\t" << hits[i].target << "\t" << hits[i].evalue << "\t" << hits[i].status  << "\n";
    }
    outFile.close();
}

void parseM8(std::string query, std::string resFileName, std::vector<std::pair<std::string, double>> &resultVector, double resSize) {
    static bool isReadIn = false;
    static std::map<std::string, std::vector<std::pair<std::string, double>>> resLookup;
    if(isReadIn == false){
        std::cout << "Read in m8 " << resFileName << std::endl;
        size_t resSizeInt = resSize;
        std::ifstream infile(resFileName);
        std::string line;
        while (std::getline(infile, line)) {
            std::vector<std::string> tmpRes = split(line, "\t");
            std::string& key = tmpRes[0];
            if(resLookup.find(key) == resLookup.end()) {
                resLookup[key] = std::vector<std::pair<std::string, double>>();
            }
            if(resLookup[key].size() < resSizeInt){
                std::string& targetkey = tmpRes[1];
                std::string& evalStr = tmpRes[10];
                double eval = strtod(evalStr.c_str(), NULL);
                resLookup[key].emplace_back(targetkey, eval);
            }
        }
        infile.close();
        std::map<std::string, std::vector<std::pair<std::string, double>>>::iterator it;

        std::vector<std::pair<std::string, double>> single;
        std::set<std::string> removeDub;
        for (it = resLookup.begin(); it != resLookup.end(); it++ ) {
            for(size_t i = 0; i < it->second.size(); i++){
                if(removeDub.find(it->second[i].first) == removeDub.end()){
                    single.push_back(it->second[i]);
                }
                removeDub.insert(it->second[i].first);
            }
            it->second.clear();
            removeDub.clear();
            for(size_t i = 0; i < single.size(); i++){
                it->second.emplace_back(single[i]);
            }
            single.clear();
        }
        isReadIn = true;
    }

    resultVector.swap(resLookup[query]);
}

std::vector<std::pair<std::string, double>> readResultFile(std::string query, std::string resFileName, double resSize) {
    std::vector<std::pair<std::string, double>> resultVector;
    parseM8(query, resFileName, resultVector, resSize);
    return resultVector;
}

void printProgress(int id){
    if (id % 1000000 == 0 && id > 0){
        std::cout << "\t" << (id/1000000) << " Mio. sequences processed\n";
        fflush(stdout);
    }
    else if (id % 10000 == 0 && id > 0) {
        std::cout  << ".";
        fflush(stdout);
    }
}

void readFamDefFromFasta(std::string fasta_path, std::unordered_map<std::string, std::vector<SCOP> *> &queryScopLookup,
                         std::unordered_map<std::string, size_t > &supFamSizeLookup, bool readEval) {
    size_t entries_num = 0;

    static PatternCompiler scopDomainRegex("[a-z]+\\.[0-9]+\\.[0-9]+\\.[0-9]+");
    std::set<std::string> scopSuperFam;

    FILE * fasta_file = fopen(fasta_path.c_str(), "r");
    kseq_t *seq = kseq_init(fileno(fasta_file));
    while (kseq_read(seq) >= 0) {
        if (seq->name.l == 0) {
            std::cout << "Fasta entry: " << entries_num << " is invalid." << std::endl;
            exit(EXIT_FAILURE);
        }

        const std::string currQuery(seq->name.s);

        if(queryScopLookup.find(currQuery) == queryScopLookup.end()) {
            queryScopLookup[currQuery] = new std::vector<SCOP>();
        }
        std::vector<SCOP> * queryDomainVector = queryScopLookup[currQuery];

        std::vector<std::string> splits = split(std::string(seq->comment.s), "|");
        std::vector<std::string> evals;
        if(readEval == true){
            evals = split(splits[1]," ");
        }

        std::string s(splits[0].c_str(), splits[0].size());
        std::vector<std::string> domains = scopDomainRegex.getAllMatches(s.c_str(), splits[0].size());
        std::set<std::string> scopDomains(domains.begin(), domains.end());

        int i = 0;
        for(std::set<std::string>::const_iterator it = scopDomains.cbegin(); it != scopDomains.cend(); it++) {
            const std::string &currScopDomain = *it;
            double eval = (readEval == true) ? strtod(evals[i].c_str(), NULL) : 0.0;
            // increase the scop domain count
            SCOP domain = SCOP(currScopDomain, eval);
            supFamSizeLookup[domain.fam]++;

            // count the superfamily only once per protein, to remove a possible repeat bias
            if (scopSuperFam.find(domain.superFam) == scopSuperFam.end()){
                supFamSizeLookup[domain.superFam]++;
                scopSuperFam.insert(domain.superFam);
            }

            supFamSizeLookup[domain.fold]++;
            queryDomainVector->push_back(domain);
            i++;
        }
        scopSuperFam.clear();

        entries_num++;
        printProgress(entries_num);

    }
    kseq_destroy(seq);
    fclose(fasta_file);
}

EvaluateResult evaluateResult(std::string query, std::vector<SCOP> *qScopIds,
                              std::unordered_map<std::string, std::vector<SCOP> *> &scopLoopup,
                              std::vector<Hits> &allHitsVec, std::vector<std::pair<std::string, double>> results,
                              size_t rocx, bool superFam, bool ignoreFP) {
    double fp_cnt = 0.0;
    double tp_cnt = 0.0;
    double ignore_cnt = 0.0;
    double auc = 0.0;

    static PatternCompiler ignore_superfam("^b\\.(67|68|69|70).*");
    static PatternCompiler ignoreClass("^e\\..*");

//    std::string qSupFam = qFam;
//    qSupFam = qSupFam.erase(qSupFam.find_last_of("."), std::string::npos);
    for (size_t i = 0; i < results.size(); i++) {
        const std::string &rKey = results[i].first;
        const double evalue = results[i].second;

        bool tp = false;
        bool fp = false;
        bool ignore = false;
        std::vector<SCOP> * rfamVec;

        // if sequence does not have annotations it is a FP
        if (scopLoopup.find(rKey) == scopLoopup.end()) {
            tp = false;
            ignore = false;
            fp = true;
            goto outer;
        }
        rfamVec = scopLoopup[rKey];

        for(size_t j = 0; j < rfamVec->size(); j++) {
            for(size_t i = 0; i < qScopIds->size(); i++) {
                const SCOP &qScopId = qScopIds->at(i);
                const SCOP &rScopId = rfamVec->at(j);
                if (superFam) {
                    // not family but same super family
                    tp = (rScopId.fam.compare(qScopId.fam) != 0) && (rScopId.superFam.compare(qScopId.superFam) == 0);
                } else {
                    tp = rScopId.fam.compare(qScopId.fam) == 0;
                }
                if (tp) {
                    goto outer;
                } else {
                    bool qSuperFamIgnore = ignore_superfam.isMatch(qScopId.fam.c_str());
                    bool rSuperFamIgnore = ignore_superfam.isMatch(rScopId.fam.c_str());

                    bool qFoldIgnore = ignoreClass.isMatch(qScopId.fam.c_str());
                    bool rFoldIgnore = ignoreClass.isMatch(rScopId.fam.c_str());

                    if ((rScopId.fold.compare(qScopId.fold) == 0)
                        || (qSuperFamIgnore && rSuperFamIgnore)
                        || qFoldIgnore
                        || rFoldIgnore) {
                        ignore = true;
                    } else if (ignoreFP == false) {
                        fp = true;
                    }
                }
            }
        }
        outer:

//        if(tp){
//            std::cout << rKey << "\n";
//        }
        // counter for ROC5 values

        if (fp_cnt < rocx) {
            if (tp == true) {
                tp_cnt++;
                allHitsVec.push_back(Hits(query, rKey, evalue, Hits::TP ));
            } else if (ignore == true) {
                ignore_cnt++;
                allHitsVec.push_back(Hits(query, rKey, evalue, Hits::IGN ));
            } else if(fp == true){
                fp_cnt++;
                allHitsVec.push_back(Hits(query, rKey, evalue, Hits::FP ));
                auc = auc + tp_cnt;
            }
        } else {
            if (tp == true) {
                allHitsVec.push_back(Hits(query, rKey, evalue, Hits::TP ));
            } else if(ignore == true) {
                allHitsVec.push_back(Hits(query, rKey, evalue, Hits::IGN ));
            } else if(fp == true) {
                allHitsVec.push_back(Hits(query, rKey, evalue, Hits::FP ));
            }
        }
    }
    return EvaluateResult(tp_cnt, fp_cnt, ignore_cnt, auc);
}


void writeFDRData(std::string roc5ResultFile,
                  std::vector<Hits> & hits,
                  std::vector<Roc5Value> & rocVal,
                  double stepSize) {
    int i = 0;
    std::ofstream fdrOut;
    fdrOut.open (roc5ResultFile + ".fdr");
    double tp = 0;
    double fp = 0;
    size_t cnt = 0;
    std::map<std::string, size_t > queryToResSize;
    for(size_t i = 0; i < rocVal.size(); i++){
        queryToResSize[rocVal[i].query] = rocVal[i].resultSize;
    }

    for(double step = 0.0; step <= 10000.0; step = stepSize ){
        while ((i < hits.size()) && (hits[i].evalue <= step)){
            double size = static_cast<double>(std::max((size_t )1, queryToResSize[hits[i].query]));
            tp += ((hits[i].status == Hits::TP)/size);
            fp += ((hits[i].status == Hits::FP)/size);
            i++;
        }
        fdrOut << std::fixed << std::setprecision(1) << std::scientific  << std::max(0.0, step) << "\t" << std::fixed << std::setprecision(6) << (tp) / (fp + tp) << "\t" << (fp) / (fp + tp) << "\n";
        cnt++;
        stepSize *= 1.5;
    }
    fdrOut.close();
}

void writeEvalueData(std::string roc5ResultFile,
                  std::vector<Hits> & hits,
                  std::vector<Roc5Value> & rocVal,
                  double queryCount,
                  double stepSize) {
    int i = 0;
    std::ofstream fdrOut;
    fdrOut.open (roc5ResultFile + ".eval");
    double fp = 0;
    size_t cnt = 0;
    std::map<std::string, size_t > queryToResSize;
    for(size_t i = 0; i < rocVal.size(); i++){
        queryToResSize[rocVal[i].query] = rocVal[i].resultSize;
    }

    for(double step = 0.0; step <= 10000.0; step = stepSize ){
        while ((i < hits.size()) && (hits[i].evalue <= step)){
            fp += hits[i].status == Hits::FP;
            i++;
        }
        fdrOut << std::fixed << std::setprecision(1) << std::scientific  << std::max(0.0, step) << "\t" << std::fixed << std::setprecision(6) << std::max(0.0, step) * queryCount << "\t" << fp << "\n";
        cnt++;
        stepSize *= 1.5;
    }
    fdrOut.close();
}



void writeRoc5Data(std::string roc5ResultFile,
                   std::vector<Roc5Value> & roc5Vals,
                   double stepSize) {
    int i = 0;
    std::ofstream roc5Out;
    roc5Out.open (roc5ResultFile+".rocx");
    double auc = 0.0;

    for(double step = 1.0; step >= 0.0-stepSize; step-=stepSize){
        while ((i < roc5Vals.size()) && (roc5Vals[i].roc5val >= step)){
            i++;
        }
        roc5Out << std::max(0.0, step) << " " << ((float)i)/((float)roc5Vals.size()) << "\n";
        auc = auc + stepSize*((float)i)/((float)roc5Vals.size());
        //std::cout <<  "i = " << i << " x = " << std::max(0.0, step)  << " auc = " << auc << std::endl;
    }
    std::cout << "ROC5 AUC: " << auc << std::endl;
    roc5Out.close();
}

void writeRocData(std::string rocFilePath, std::vector<Hits> & hits, size_t binSize) {
    std::ofstream roc5Out;
    roc5Out.open(rocFilePath + ".roc");
    size_t tp_cnt = 0;
    size_t fp_cnt = 0;
    size_t step_size = hits.size() / binSize;
    step_size = std::max(step_size, (size_t ) 1 );
    for (size_t i = 0; i < hits.size(); i++) {
        if (hits[i].status == Hits::TP) {
            tp_cnt++;
        } else if (hits[i].status == Hits::FP) {
            fp_cnt++;
        }

        if (i % step_size == 0) {
            roc5Out << fp_cnt << "\t" << tp_cnt << "\n";
        }

    }
    roc5Out.close();
}

std::vector <std::string> split(const std::string& str, const std::string& delimiter = " ") {
    std::vector <std::string> tokens;

    std::string::size_type lastPos = 0;
    std::string::size_type pos = str.find(delimiter, lastPos);

    while (std::string::npos != pos) {
        // Found a token, add it to the vector.
        tokens.push_back(str.substr(lastPos, pos - lastPos));
        lastPos = pos + delimiter.size();
        pos = str.find(delimiter, lastPos);
    }

    tokens.push_back(str.substr(lastPos, str.size() - lastPos));
    return tokens;
}

