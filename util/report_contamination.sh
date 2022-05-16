#!/usr/bin/awk -f
awk '{
    if($2 < 0.8) {
        print "Input sequence may be contaminated, for more information see", "tophit_report_sorted", "\n"
    }
    else {
        print "No contamination detected, possible taxonomical assignment is ", $6,"\n"
        print "For more information see", "tophit_report_sorted", "\n"
    }
}' $1

