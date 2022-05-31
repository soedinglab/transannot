#ifndef LOCALCOMMANDDECLARATIONS_H
#define LOCALCOMMANDDECLARATIONS_H
#include "Command.h"

extern int assemble(int argc, const char **argv, const Command& command);
extern int annotate(int argc, const char **argv, const Command& command);
extern int contamination(int argc, const char **argv, const Command& command);
extern int downloaddb(int argc, const char **argv, const Command& command);
extern int createdb(int argc, const char **argv, const Command& command);
#endif