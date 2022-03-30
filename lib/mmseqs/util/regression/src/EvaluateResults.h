//
// Created by mad on 9/22/15.
//
#ifndef EVALUATE_RESULTS_H_
#define EVALUATE_RESULTS_H_
#include <string>
#include <vector>
#include <set>
#include <unordered_map>
#include <map>
#include <cstdio>


struct EvaluateResult{
    double tp_cnt;
    double fp_cnt;
    double ignore_cnt;
    double auc;
    EvaluateResult(double tp_cnt,
                   double fp_cnt,
                   double ignore_cnt,
                   double auc): tp_cnt(tp_cnt),
                                fp_cnt(fp_cnt), ignore_cnt(ignore_cnt), auc(auc) {};
};

struct SCOP{
    std::string fold;
    std::string superFam;
    std::string fam;
    double evalue;
    SCOP(std::string scop, double eval){
        fam = scop;
        superFam = scop;
        superFam = superFam.erase(superFam.find_last_of("."), std::string::npos);
        fold = scop;
        fold     = fold.erase(fold.find_last_of("."), std::string::npos);
        fold     = fold.erase(fold.find_last_of("."), std::string::npos);
        evalue = eval;
    }
};

struct Roc5Value{
    std::string query;
    std::string qFams;
    size_t qFamSize;
    double roc5val;
    size_t tp_cnt;
    size_t fp_cnt;
    size_t ignore_cnt;
    size_t resultSize;
    Roc5Value(std::string query, std::string qFams, size_t qFamSize,
              double roc5val, size_t tp_cnt, size_t fp_cnt,
              size_t ignore_cnt, size_t resultSize):
            query(query), qFams(qFams), qFamSize(qFamSize), roc5val(roc5val), tp_cnt(tp_cnt), fp_cnt(fp_cnt), ignore_cnt(ignore_cnt), resultSize(resultSize){};


};

struct sortDescByRoc5 {
    bool operator()(const Roc5Value left, const Roc5Value right) {
        return left.roc5val > right.roc5val;
    }
};

struct Hits {
    std::string query;
    std::string target;
    double evalue;
    int status;

    Hits(std::string query, std::string target, double evalue, int status)
            : query(query), target(target), evalue(evalue), status(status)
    {}

    const static int TP = 0;
    const static int FP = 1;
    const static int IGN = 2;
};

struct sortFalsePositvesByEval {
    bool operator()(const Hits left, const Hits right) {
        return left.evalue < right.evalue;
    }
};

void parseM8(std::string query, std::string resFileName, std::vector<std::pair<std::string, double>> &resultVector, double resSize);

std::vector<std::pair<std::string, double>> readResultFile(std::string query, std::string resFileName, double resSize);

void printProgress(int id);

std::vector <std::string> split(const std::string& str, const std::string& delimiter);

void readFamDefFromFasta(std::string fasta_path, std::unordered_map<std::string, std::vector<SCOP> *> &queryScopLookup,
                         std::unordered_map<std::string, size_t > &supFamSizeLookup, bool readEval);

EvaluateResult evaluateResult(std::string query, std::vector<SCOP> *qScopIds, std::unordered_map<std::string,
        std::vector<SCOP> *> &scopLoopup, std::vector<Hits> &allHitsVec,
                              std::vector<std::pair<std::string, double>> results, size_t rocx,
                              bool superFam, bool ignoreFP);

void writeRoc5Data(std::string roc5ResultFile,
                   std::vector<Roc5Value> & roc5Vals,
                   double stepSize);

void writeRocData(std::string rocFilePath, std::vector<Hits> & hits, size_t binSize);
void writeFDRData(std::string rocFilePath, std::vector<Hits> & hits, std::vector<Roc5Value> & rocVal, double stepSize);
void writeEvalueData(std::string rocFilePath, std::vector<Hits> & hits, std::vector<Roc5Value> & rocVal, double queryCount, double stepSize);
void writeAnnoatedResultFile(std::string basic_string, std::vector<Hits> & vector);

#endif
