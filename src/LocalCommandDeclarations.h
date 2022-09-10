#ifndef LOCALCOMMANDDECLARATIONS_H
#define LOCALCOMMANDDECLARATIONS_H
#include "Command.h"

extern int assemblereads(int argc, const char **argv, const Command& command);
extern int annotate(int argc, const char **argv, const Command& command);
extern int annotateprofiles(int argc, const char **argv, const Command& command);
extern int contamination(int argc, const char **argv, const Command& command);
extern int downloaddb(int argc, const char **argv, const Command& command);
extern int createquerydb(int argc, const char **argv, const Command& command);
extern int easytransannot(int argc, const char **argv, const Command& command);
extern int getorthologs(int argc, const char **argv, const Command& command);
#endif