#ifndef MMSEQS_PATTERNCOMPILER_H
#define MMSEQS_PATTERNCOMPILER_H
#include <regex.h>
#include <iostream>

#include "PatternCompiler.h"

#include <string>
#include <vector>


class PatternCompiler {
public:
    PatternCompiler(const char* pattern)  {
        if (regcomp(&regex, pattern, REG_EXTENDED | REG_NEWLINE) != 0 ){
            std::cerr << "Error in regex " << pattern << std::endl;
            exit(EXIT_FAILURE);
        }
    }

    ~PatternCompiler() {
        regfree(&regex);
    }

    bool isMatch(const char *target) {
        return regexec(&regex, target, 0, NULL, 0) == 0;
    }


    std::vector<std::string> getCaptureGroups(const char* target, size_t groupCount, bool matchFirst = true) {
        std::vector<std::string> result;
    
        size_t maxGroups = groupCount + 1;
        regmatch_t groupArray[maxGroups];
    

        int status = regexec(&regex, target, maxGroups, groupArray, 0);
        if (status == 0) {
            size_t start = matchFirst ? 0 : 1;
            for (unsigned int i = start; i < maxGroups; ++i) {

                if (groupArray[i].rm_so == (size_t) -1)
                    break;
    
                result.emplace_back(target + groupArray[i].rm_so,  groupArray[i].rm_eo - groupArray[i].rm_so);
            }
        }
    
        return result;
    }

    std::vector<std::string> getAllMatches(const char* target, unsigned int maxMatches, unsigned int groupCount = 0) {
        std::vector<std::string> result;
    
        size_t maxGroups = groupCount + 1;
        regmatch_t groupArray[maxGroups];
    
        unsigned int offset = 0;

        const char *cursor = target;
        for (unsigned int m = 0; m < maxMatches; m ++) {
            if (regexec(&regex, cursor, maxGroups, groupArray, 0) != 0)
                continue; 

            for (size_t g = 0; g < maxGroups; g++) {
                if (groupArray[g].rm_so == (size_t)-1) {
                    break;
                }

                if (g == 0) {
                    offset = groupArray[g].rm_eo;
                }

               result.emplace_back(cursor + groupArray[g].rm_so,  groupArray[g].rm_eo - groupArray[g].rm_so);
            }   
            cursor += offset;
        }

    
        return result;
    }

private:
    regex_t regex;
};


#endif //MMSEQS_PATTERNCOMPILER_H
