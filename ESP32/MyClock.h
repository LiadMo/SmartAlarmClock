#ifndef MYCLOCK_H
#define MYCLOCK_H

#include <time.h>
#include <string>
#include <sstream>
#include <map>

using std::string;

const char* ntpServer1 = "pool.ntp.org";
const char* ntpServer2 = "time.nist.gov";
const long gmtOffset_sec = 3600 * 2;
const int daylightOffset_sec = 3600;

std::map<int, string> int_to_string_days = {
    {0, "Sunday"},
    {1, "Monday"},
    {2, "Tuesday"},
    {3, "Wednesday"},
    {4, "Thursday"},
    {5, "Friday"},
    {6, "Saturday"}
};

#endif