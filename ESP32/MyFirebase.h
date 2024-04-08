#ifndef MYFIREBASE_H
#define MYFIREBASE_H

#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <set>
#include <unordered_map>
#include <vector>
#include <map>
#include <utility>
#include <string>
#include <ArduinoJson.h>

// Define Firebase
#define DATABASE_URL "*****"
#define API_KEY "AIzaSy*********NohLhBR5bkA"
#define USER_EMAIL "*****@technion.ac.il"
#define USER_PASSWORD "*****"

using std::string;
using std::vector;
using std::set;
using std::pair;
using std::unordered_map;

FirebaseAuth auth;
FirebaseConfig config;

FirebaseData streamRoot;
FirebaseData fbdo;
FirebaseData fbdo1;

std::map<string, int> string_to_int_days1 = {
    {"Sunday", 0},
    {"Monday", 1},
    {"Tuesday", 2},
    {"Wednesday", 3},
    {"Thursday", 4},
    {"Friday", 5},
    {"Saturday", 6}
};

std::map<string, int> string_to_int_days2 = {
    {"Sun", 0},
    {"Mon", 1},
    {"Tue", 2},
    {"Wed", 3},
    {"Thu", 4},
    {"Fri", 5},
    {"Sat", 6}
};

vector<set<pair<String,String> > > alarms(7);
unordered_map<string,vector<int>> map_id_to_days;

#endif
