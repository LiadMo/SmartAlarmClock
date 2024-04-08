#include <Arduino.h>
#include <string>
#include <WiFi.h>
#include "MyDisplay.h"
#include "MyFirebase.h"
#include "MyAudio.h"
#include "MyButtons.h"
#include "MyClock.h"
#include <sstream>
#include <iomanip>
#include <WiFiManager.h>

using std::string;
using std::string;
using std::vector;
using std::set;
using std::pair;
using std::unordered_map;

WiFiManager wifiManager;
bool res123;

// Settings
String _Language = "english";
String _Ringtone = "ringtone1";
int _Volume = 10;
int _Brightness = 10;

// Time
String _Date; 
String _Time; 
String _Day;


// WiFi settings
const char *ssid = "Liads";
const char *password = "12345678";

// helper var
int numTaskToday = 0;
uint32_t sec = millis();
uint32_t sec_wifi = millis();
uint32_t sec_test = millis() + 20000;

bool isAlarm = false;
bool stopAlarm = false;
bool isTask = false;


bool wifiConnected = false;
bool radio = false;
unsigned long startAlarm;
char buffer[64];
// Firebase - tasks
unordered_map<string,pair<String,String>> tasks_map;// id->(task_date,task_message)
bool is_first_call_root = true;
String msg;
bool changedTasks = false;
bool tts = false;
char buffer_tasks[100];
string tasks_for_today = "";
string tasks_to_say="";
string task_id="";

// put function declarations here:
void freeHeap(int num);
void configTime();
void showTime();
void updateStopAlarm();
void WiFiEvent(WiFiEvent_t event);
void InitWiFi();
void updateMode();
void showRadio();

void InitSDCard();
void InitAudio();
void DestroyAudio();
void playFile(std::string filename);
//void playAudio();

void configNTP();
void showTime();
void showDate();
void updateTime();
void playTime();
void playDate();
void playDay();


bool isGetClock();
bool isGetAlarm();
pair<String,String> get_pair(String& alarm_id , int day);
void removeAlarmsId(String& alarm_id);
void insertAlarmsId(String& alarm_id,String& clock);
void update_alarmID(String alarm_id, String& updated_json_str);
void insert_alarm(String& alarm_id, String& days_doc_str, String& clock);
void clear_alarmId(String alarm_id);
void delete_alarm(String alarm_id);
void iterateJson(String& str_document);
void print_map();
void print_vector();
void showReminders();


void streamCallbackAlarms(FirebaseStream& data, bool first_call, String alarms_doc_str);
void StreamCallBackTasks(FirebaseStream& data, bool is_first_call_tasks, String str_doc_tasks);
void StreamCallBackSettings(String& setting_doc_str);
void StreamCallBackRoot(FirebaseStream data);


void DemoStreamCallback(FirebaseStream data);
void DemoStreamTimeoutCallback(bool timeout);
void FirebaseInit();

unsigned long getCurrentTimeMillis();
std::string formatDate();
bool isGetTask();

void showMessage();
void playTasks();


// ############################## Setup ##############################

void setup()
{
  // Initialize Serial
  Serial.begin(9600);
  freeHeap(1);  // Free heap size 1: 181488 bytes // Free heap size 1: 179536 bytes

  // Initialize Display
  DisplayInit();
  freeHeap(2); // Free heap size 2: 181256 bytes // Free heap size 2: 184288 bytes


  // Initialize WiFi
  //_Display.displayReset();
  //Serial.println("***** Display Cleared *****");
  InitWiFi();
  freeHeap(3); // Free heap size 3: 133920 bytes // Free heap size 3: 136188 bytes // new ESP Free heap size 3: 150436 bytes

  // Initialize Clock
  _Display.displayClear();
  _Display.print("ntp sync");
  configNTP();
  

  // Initialize Firebase
   FirebaseInit();
   FirebaseStreamRoot();
   freeHeap(4); // Free heap size 4: 108460 bytes // Free heap size 4: 111368 bytes // new Free heap size 4: 123248 bytes

  // Initialize Audio
  //DestroyAudio();
  InitAudio();
  InitSDCard();

  // Initialize Buttons
  initButtons();
  freeHeap(5); // Free heap size 5: 80748 bytes // Free heap size 5: 83652 bytes // new ESP Free heap size 5: 127056 bytes

}


// ############################## Loop ##############################

void loop()
{
  if (isTask) {
    if(_Display.displayAnimate()) _Display.displayText(msg.c_str(), PA_CENTER, 30, 100, PA_SCROLL_LEFT, PA_SCROLL_LEFT);
  }
  updateTime();
  updateMode();
  // if (isTask) {
  //   showMessage();
  // }

  switch (mode)
  {
    case 1:
    if (!isTask && !isAlarm)
      showTime();
      modeChanged = false;
      radio = false;
      break;
    case 2:
    if (!isTask && !isAlarm)
      showDate();
      modeChanged = false;
      radio = false;
      break;
    case 3:
    if (!isTask && !isAlarm)
      showDay();
      modeChanged = false;
      radio = false;
      break;
    case 4:
    if (!isTask && !isAlarm)
      showReminders();
      modeChanged = false;
      break;
  }


  if ((!isAlarm && !isTask) && isButtonPressed(BUTTON_DO_PIN) == SHORT_PRESS)
  {
    if (mode == 1) {
      playTime();
    }
    else if (mode == 2) {
      playDate();
    }
    else if (mode == 3) {
      playDay();
    }
    else if (mode == 4) {
      playTasks();
    }
  }
  // playAudio();
  if (sec < millis()) {
    if(isTask) Serial.println("isTask is true");
    else Serial.println("prsent task is false");
    if(stopAlarm) Serial.println("stopAlarm is true");
    else Serial.println("stopAlarm is false");
    if(isAlarm) Serial.println("isAlarm is true");
    else Serial.println("isAlarm is false");
    Firebase.RTDB.setTimestampAsync(&fbdo, "/online");
    sec = millis() + 1000;
    
    if (mode == 1) {
      Serial.print("Mode 1 - Time is: ");
      Serial.println(_Time);
    }
    else if (mode == 2) {
      Serial.print("Mode 2 - Date is: ");
      Serial.println(_Date);
    }
    else if (mode == 3) {
      Serial.print("Mode 3 - Day is: ");
      Serial.println(_Day);
    }
    else if (mode == 4) {
      Serial.print("Mode 4 - Taks have: ");
      Serial.println(numTaskToday);
    }

    if (!stopAlarm && (isGetAlarm() || isGetTask())) {
      Serial.println("Alarm\Task  is on !");
      if (!isAlarm && isGetAlarm()) { // new alarm
        startAlarm = millis();
        isAlarm = true;
      }
      if(!isTask && isGetTask()){ // new task
        isTask=true;
         startAlarm = millis();
      }
      if(isTask){
        //_Display.print("Task");
        sprintf(buffer, "You have task now: %s", msg.c_str());
        if(!audio.isRunning()) audio.connecttospeech(buffer, "en");
      }
      else {
      _Display.print("Alarm");
      sprintf(buffer,"Alarms/%s.mp3",_Ringtone.c_str());
      playFile(buffer);
      }
    }
    else {
      if(isTask){
        isTask = false;
      }
      else {
        isAlarm = false;
      }
    }
  }

  // if (sec_test < millis()) {
  //   sec_test = millis() + 20000;
  //       if (audio.isRunning() == false) {
  //       audio.connecttospeech("Wenn die Hunde schlafen, kann der Wolf gut Schafe stehlen.", "de"); // Google TTS
  //   }
  // }

  if (!isAlarm && !isTask && sec_wifi < millis() && WiFi.status() != WL_CONNECTED) {
    sec_wifi = millis() + 7000;
    Serial.println("No WiFi");
    is_first_call_root = true;
    _Display.print("No WiFi");
    unsigned long startTime = millis();
    while (!audio.isRunning() && millis() - startTime < 3000) {
    updateMode();
    if (modeChanged) {
      break;
    }
    }
  }

    if (audio.isRunning())
    {
      audio.loop();
      if ((isAlarm || isTask) &&  isButtonPressed(BUTTON_DO_PIN) == SHORT_PRESS) {
      audio.stopSong();
        if (isTask) {
        sprintf(buffer,"App/Tasks/%s",task_id.c_str());
        Firebase.RTDB.deleteNode(&fbdo1, buffer);
      }
      isAlarm = false;
      stopAlarm = true;
      isTask = false;
     }
    }
    if ((isTask || isAlarm) && isButtonPressed(BUTTON_DO_PIN) == SHORT_PRESS){
        if (isTask){
        sprintf(buffer,"App/Tasks/%s",task_id.c_str());
        Firebase.RTDB.deleteNode(&fbdo1, buffer);
      }
      stopAlarm = true;
      isTask = false;
      isAlarm = false;
    }


    // if (isAlarm && isButtonPressed(BUTTON_DO_PIN) == SHORT_PRESS) {
    //   audio.stopSong();
    //   isAlarm = false;
    //   stopAlarm = true;
    // }



    updateStopAlarm();

    
}

// optional
void audio_info(const char *info){
    Serial.print("info        "); Serial.println(info);
}
void audio_id3data(const char *info){  //id3 metadata
    Serial.print("id3data     ");Serial.println(info);
}
void audio_eof_mp3(const char *info){  //end of file
    Serial.print("eof_mp3     ");Serial.println(info);
}
void audio_showstation(const char *info){
    Serial.print("station     ");Serial.println(info);
}
void audio_showstreamtitle(const char *info){
    Serial.print("streamtitle ");Serial.println(info);
}
void audio_bitrate(const char *info){
    Serial.print("bitrate     ");Serial.println(info);
}
void audio_commercial(const char *info){  //duration in sec
    Serial.print("commercial  ");Serial.println(info);
}
void audio_icyurl(const char *info){  //homepage
    Serial.print("icyurl      ");Serial.println(info);
}
void audio_lasthost(const char *info){  //stream URL played
    Serial.print("lasthost    ");Serial.println(info);
}
void audio_eof_speech(const char *info){
    Serial.print("eof_speech  ");Serial.println(info);
}

void freeHeap(int num)
{
  size_t freeHeap = esp_get_free_heap_size();
  Serial.print("Free heap size ");
  Serial.print(num);
  Serial.print(": ");
  Serial.print(freeHeap);
  Serial.print(" bytes\n");
}

void InitWiFi() {
  // WiFi.begin(ssid, password);
  // Serial.println("Connecting to WiFi...");
    // while (WiFi.status() != WL_CONNECTED)
    // {
    //   if (_Display.displayAnimate()) _Display.displayText("Connecting to WiFi", PA_CENTER, 30, 0, PA_SCROLL_LEFT,PA_SCROLL_LEFT);
    // }
  // wifiConnected = true;
  // Serial.println("WiFi Connedted");
    _Display.print("WiFi");
    Serial.print(111);
    res123 = wifiManager.autoConnect("SmartAlarmClock"); // password protected ap
    Serial.print(222);
    if (res123) {
    Serial.println("Connected to Wi-Fi");
    Serial.print(333);
    wifiConnected = true;
  } else {
    Serial.println("Failed to connect to Wi-Fi");
    Serial.print(444);
  }

}

void updateStopAlarm() {
  if (millis() - startAlarm > 59800) {
    stopAlarm = false;
    //isTask = false;
  } 
}

void updateMode() {
    if (isButtonPressed(BUTTON_NEXT_PIN) == SHORT_PRESS) // if pressed change mode
  {
    mode = mode == 4 ? 1 : mode + 1;
    modeChanged = true;
    Serial.print("mode = ");
    Serial.println(mode);
  }
  else if (isButtonPressed(BUTTON_PREV_PIN) == SHORT_PRESS) // if pressed change mode
  {
    mode = mode == 1 ? 4 : mode - 1;
    modeChanged = true;
    Serial.print("mode = ");
    Serial.println(mode);
  }
  else if (isButtonPressed(BUTTON_RESET_PIN) == LONG_PRESS) { // reset
    Serial.println("****** Reset *******");
    _Display.print("Reset");
    delay(1500);
    wifiManager.resetSettings();
    ESP.restart();
  }

  // if (isButtonPressed(BUTTON_DO_PIN) == SHORT_PRESS)
  // {
  //   if (mode == 1) {
  //     playTime();
  //   }
  //   else if (mode == 2) {
  //     playDate();
  //   }
  //   else if (mode == 3) {
  //     playDay();
  //   }
  //   else if (mode == 4) {
  //     playTasks();
  //   }
  // }
}

// void WiFiEvent(WiFiEvent_t event) {
//   switch(event) {
//     // case SYSTEM_EVENT_STA_CONNECTED:
//     //   Serial.println("WiFi reconnected");
//     //   if (!wifiConnected) {
//     //     //sprintf(buffer,"Wifi/connected_%s.mp3",_Language.c_str());
//     //     //playFile(buffer);
//     //     audio.connecttospeech("Wenn die Hunde schlafen, kann der Wolf gut Schafe stehlen.", "de");
//     //     wifiConnected = true;
//     //   }
//     //   break;

//     case SYSTEM_EVENT_STA_DISCONNECTED:
//       Serial.println("Disconnected from WiFi!!!!");
//       if (wifiConnected) {
//         sprintf(buffer,"Wifi/disconnected_%s.mp3",_Language.c_str());
//         playFile(buffer);
//         wifiConnected = false;
//       }
//     default:
//       break;
//   }
// }

// ############################## Audio ##############################
void InitSDCard()
{
    pinMode(SD_CS, OUTPUT);
    digitalWrite(SD_CS, HIGH);
    SPI.begin(SPI_SCK, SPI_MISO, SPI_MOSI);
    SPI.setFrequency(1000000);
    if (!SD.begin(SD_CS, SPI))
    {
        Serial.println("SD Card Mount Failed");
    }
}

void InitAudio()
{
    audio.setPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
    audio.setVolume(20);
}


void playFile(std::string filename)
{   
      if (!audio.isRunning()) audio.connecttoFS(SD, filename.c_str());
      Serial.println("play file");
}


// ############################## Time / Clock ##############################
void configNTP()
{
  //sntp_set_time_sync_notification_cb();
  if (_Display.displayAnimate()) _Display.displayText("Sync Time (NTP)", PA_CENTER, 5, 0, PA_SCROLL_LEFT,PA_SCROLL_LEFT);
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer1, ntpServer2);
}


void showTime()
{
    _Display.print(_Time);
}

void showDate() {
    _Display.print(_Date.c_str());
}

void updateTime() { 
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo))
    {
        Serial.println("Failed to obtain time");
        return;
    }
    int day = timeinfo.tm_wday;
    _Day = int_to_string_days[day].c_str();
    _Day = int_to_string_days[day].substr(0, 3).c_str();

    // Format day, month, and year
    if (timeinfo.tm_mday < 10 && timeinfo.tm_mon < 10) {
        sprintf(buffer, "%1d.%1d.%02d", timeinfo.tm_mday, timeinfo.tm_mon + 1, timeinfo.tm_year % 100);
    } else if (timeinfo.tm_mday < 10) {
        sprintf(buffer, "%1d.%02d.%02d", timeinfo.tm_mday, timeinfo.tm_mon + 1, timeinfo.tm_year % 100);
    } else if (timeinfo.tm_mon < 10) {
        sprintf(buffer, "%02d.%1d.%02d", timeinfo.tm_mday, timeinfo.tm_mon + 1, timeinfo.tm_year % 100);
    } else {
        sprintf(buffer, "%02d.%02d.%02d", timeinfo.tm_mday, timeinfo.tm_mon + 1, timeinfo.tm_year % 100);
    }

    _Date = buffer;

    sprintf(buffer, "%02d:%02d", timeinfo.tm_hour, timeinfo.tm_min);
    _Time = buffer;
}

void showDay() {
    _Display.print(_Day.c_str());
}

void playTime() {
    String hh=_Time.substring(0,2);
    String mm=_Time.substring(3);
    sprintf(buffer,"Alarms/%s/%s/%s_%s.mp3",_Language.c_str() ,hh.c_str(),hh.c_str(),mm.c_str());
    playFile(buffer);
    Serial.print("path: ");
    Serial.println(buffer);
}

void playDate() {
    int day, month, year;
    sscanf(_Date.c_str(), "%d.%d.%d", &day, &month, &year);
    year += 2000;
    sprintf(buffer, "Dates/%02d%02d%d_%s.mp3", day, month, year, _Language.c_str());
    playFile(buffer);
    Serial.print("path: ");
    Serial.println(buffer);
}

void playDay() {
  sprintf(buffer, "Days/%s/%s.mp3",_Language.c_str() ,_Day.c_str());
  playFile(buffer);
  Serial.print("path: ");
  Serial.println(buffer);
}

// ############################## Firebase ##############################
void StreamCallBackSettings(String& setting_doc_str){
  JsonDocument doc;
  deserializeJson(doc, setting_doc_str);
  _Language = doc["language"].as<String>();
  _Volume = doc["volume"].as<int>();
  _Volume *= 2;
  _Brightness = doc["brightness"].as<int>();
  _Ringtone = doc["ringtone"].as<String>();
  Serial.println(_Ringtone);
  _Display.setIntensity(_Brightness);
  audio.setVolume(_Volume);
}
// ####### end of settings ######


bool isGetClock() {
    int currentDay = string_to_int_days2[_Day.c_str()];
    for(pair<String,String> p : alarms[currentDay]){
        if(p.first == _Time) {
            return true;
        }
    }
    return false;
}

bool isGetAlarm() {
    int currentDay = string_to_int_days1[_Day.c_str()];
    return currentDay >=0 && currentDay <7 && isGetClock();
}

pair<String,String> get_pair(String& alarm_id , int day) {
    for(pair<String,String> p : alarms[day]){
        if(p.second == alarm_id){
            return p;
        }
    }
    return pair<String,String>("","");
}

void removeAlarmsId(String& alarm_id){
  string alarm_id_str = alarm_id.c_str();
  for(int d : map_id_to_days[alarm_id_str]){
    pair<String,String> p = get_pair(alarm_id,d);
    alarms[d].erase(p);
  }
}

void insertAlarmsId(String& alarm_id,String& clock){
  string alarm_id_str = alarm_id.c_str();
  for(int d : map_id_to_days[alarm_id.c_str()]){
    pair<String,String> new_pair_clock(clock,alarm_id);
    alarms[d].insert(new_pair_clock);
  }
}

void update_alarmID(String alarm_id, String& updated_json_str){
    string alarm_id_str = alarm_id.c_str();
    JsonDocument update_doc;
    deserializeJson(update_doc, updated_json_str);
    String clock = update_doc["dateTime"].as<String>();
    if(clock == "null"){
      int d = map_id_to_days[alarm_id_str][0];
      clock = get_pair(alarm_id,d).first;
    }
    removeAlarmsId(alarm_id);
    String str_days = update_doc["selectedDays"].as<String>();
    if(str_days == "null"){
     insertAlarmsId(alarm_id,clock);
    }
    else{
      map_id_to_days[alarm_id_str].clear();
      JsonDocument days_doc;
      deserializeJson(days_doc, str_days);
      for(JsonPair kv : days_doc.as<JsonObject>() ){
          if(kv.value().as<bool>()){
              int day = string_to_int_days1[kv.key().c_str()];
              map_id_to_days[alarm_id_str].push_back(day);
              pair<String,String> new_pair_clock(clock,alarm_id);
              alarms[day].insert(new_pair_clock);
        }
      }
        insertAlarmsId(alarm_id,clock);
    }
}


void insert_alarm(String& alarm_id, String& days_doc_str, String& clock){
    vector<int> vec_days;
    JsonDocument days_doc;
    deserializeJson(days_doc, days_doc_str);
    for(JsonPair kv : days_doc.as<JsonObject>() ){
        if(kv.value().as<bool>()){
            int day = string_to_int_days1[kv.key().c_str()];
            vec_days.push_back(day);
            pair<String,String> new_pair_clock(clock,alarm_id);
            alarms[day].insert(new_pair_clock);
      }
    }
    string str_alarm_id = alarm_id.c_str();
    map_id_to_days[str_alarm_id] = vec_days;
}



void clear_alarmId(String alarm_id) {
  string alarm_id_str = alarm_id.c_str();
  for(int d : map_id_to_days[alarm_id_str]) {
    pair<String,String> p = get_pair(alarm_id,d);
    alarms[d].erase(p);
  }
  map_id_to_days[alarm_id_str].clear();
}

void delete_alarm(String alarm_id){
  string alarm_id_str = alarm_id.c_str();
    for(int d : map_id_to_days[alarm_id_str]) {
        pair<String,String> p = get_pair(alarm_id,d);
        alarms[d].erase(p);
    }
    map_id_to_days.erase(alarm_id_str);
}

void iterateJson(String& str_document){
  JsonDocument jdoc;
  deserializeJson(jdoc, str_document);  
  String clock = jdoc["dateTime"].as<String>();
  String str_days = jdoc["selectedDays"].as<String>();
  String alarm_id = jdoc["id"].as<String>();
  string str_alarm_id = alarm_id.c_str();
  Serial.print("alarm id is : ");
  Serial.println(alarm_id);

  if (map_id_to_days.find(str_alarm_id) != map_id_to_days.end()){
      clear_alarmId(alarm_id);
  }
  insert_alarm(alarm_id, str_days, clock);
}

void print_map() {
  Serial.println("printing map");
    for(auto it = map_id_to_days.begin(); it != map_id_to_days.end(); it++) {
        Serial.print(it->first.c_str());
        Serial.print(" : ");
        for(int d : it->second){
            Serial.print(d);
            Serial.print(" ");
        }
        Serial.println();
    }

}

void print_vector() {
    Serial.println("printing vector");
    for(int i = 0; i < 7; i++) {
        Serial.print("day ");
        Serial.print(i);
        Serial.print(" : ");
        for(pair<String,String> p : alarms[i]){
          Serial.print("the id ");
            Serial.print(p.first.c_str());
            Serial.print(" have clock : ");
            Serial.print(p.second.c_str());
            Serial.print(" :) ");
        }
        Serial.println();
    }
}

// Define Firebase Stream Callback
void DemoStreamCallback(FirebaseStream data)
{
  Serial.printf("sream path, %s\nevent path, %s\ndata type, %s\nevent type, %s\n\n",
                data.streamPath().c_str(),
                data.dataPath().c_str(),
                data.dataType().c_str(),
                data.eventType().c_str());
  printResult(data); // see addons/RTDBHelper.h
  Serial.println();
}

void streamCallbackAlarms(FirebaseStream& data, bool first_call, String alarms_doc_str)
{ 
  if(first_call){
      JsonDocument doc;
      deserializeJson(doc, alarms_doc_str);
      for(JsonPair kv : doc.as<JsonObject>()){
          String jval = kv.value().as<String>();
          String alarm_id = kv.key().c_str();
          iterateJson(jval);
      }
  }
   else{
      if(data.dataType() == "null"){
        String alarm_id = data.dataPath().substring(8);
        delete_alarm(alarm_id.c_str());
      }
      else if(data.eventType() == "patch"){
        String alarm_id = data.dataPath().substring(8);
        String str_data = data.jsonString();
        update_alarmID(alarm_id,str_data); 
      }
      else{
        String str_data = data.jsonString();
        iterateJson(str_data); 
      }
        
   }

  Serial.println();
  //print_map();
  //Serial.println("#####");
  //print_vector();
  //Serial.println("#####");
}


void DemoStreamTimeoutCallback(bool timeout) {
    if (timeout)
        Serial.println("Stream timeout, resume streaming...");
}

void FirebaseInit()
{
    // Initialize Firebase
    config.host = DATABASE_URL;
    config.api_key = API_KEY;
    config.token_status_callback = tokenStatusCallback;

    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;

    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
}

void FirebaseStreamRoot()
{
    Firebase.RTDB.beginStream(&streamRoot, "/App");
    Firebase.RTDB.setStreamCallback(&streamRoot,StreamCallBackRoot , DemoStreamTimeoutCallback);
}

void insertTask(string& id_task, String& str_doc_task){
        JsonDocument doc_task;
        deserializeJson(doc_task, str_doc_task);
        string date_task = doc_task["date"].as<String>().c_str();
        if(date_task == formatDate().c_str()){
          numTaskToday+=1;
        }
        String message_task = doc_task["msg"].as<String>();
        string clock_task = doc_task["time"].as<String>().c_str();
        date_task+=clock_task;
        String time_task = date_task.c_str();
        pair<String,String> new_pair_task(time_task,message_task);
        tasks_map[id_task] = new_pair_task;
}



void printMapTasks(){
  for(auto it = tasks_map.begin(); it != tasks_map.end(); it++){
    Serial.print("id = ");
    Serial.print(it->first.c_str());
    Serial.print(" --> date_task: ");
    Serial.print(it->second.first.c_str());
    Serial.print(" , message_task:");
    Serial.println(it->second.second.c_str());
  }

}


void StreamCallBackTasks(FirebaseStream& data, bool is_first_call_tasks, String str_doc_tasks){
  if (is_first_call_tasks){
    JsonDocument doc;
    deserializeJson(doc, str_doc_tasks);
    for(JsonPair kv : doc.as<JsonObject>()){
        string id_task = kv.key().c_str();
        String str_doc_task = kv.value().as<String>();
        //numTaskToday+=1;
        insertTask(id_task,str_doc_task);
    }
  }
  else{
    if(data.dataType() == "null"){
      string id_task = data.dataPath().substring(7).c_str();
      String date_task = tasks_map[id_task].first;
      if(date_task.startsWith(formatDate().c_str())){
        numTaskToday-=1;
      }
      tasks_map.erase(id_task);
    } else{
      string id_task = data.dataPath().substring(7).c_str();
      String str_doc_task = data.jsonString();
      //numTaskToday+=1;
      insertTask(id_task,str_doc_task);
    }
  }
  changedTasks = true;
  printMapTasks();
}

void StreamCallBackRoot(FirebaseStream data){
  Serial.printf("sream path, %s\nevent path, %s\ndata type, %s\nevent type, %s\n\n",
                 data.streamPath().c_str(),
                 data.dataPath().c_str(),
                 data.dataType().c_str(),
                 data.eventType().c_str());
  if (is_first_call_root){
     is_first_call_root = false;
      String str_data = data.jsonString();
      JsonDocument doc_root;
      deserializeJson(doc_root, str_data);
      for(JsonPair kv : doc_root.as<JsonObject>()){
          String root_child = kv.key().c_str();
          if(root_child == "alarms"){
              String alarms_doc_str = kv.value().as<String>();
              streamCallbackAlarms(data, true, alarms_doc_str);
          } else if (root_child == "settings"){
            String settings_doc_str = kv.value().as<String>();
            StreamCallBackSettings(settings_doc_str);
          } else {
            String tasks_doc_str = kv.value().as<String>();
            StreamCallBackTasks(data, true, tasks_doc_str);
          }
          
      }
  }
  else{
      if(data.dataPath().startsWith("/alarms")){
        String str_data = data.jsonString();
        streamCallbackAlarms(data, false, str_data);
    } else if ( data.dataPath().startsWith("/settings")){
      String str_data = data.jsonString();
      StreamCallBackSettings(str_data);
    } else {
      String str_data = data.jsonString();
      StreamCallBackTasks(data, false, str_data);
    }
  }
}

std::string formatDate() {
    int d, m, y;
    sscanf(_Date.c_str(), "%d.%d.%d", &d, &m, &y);

    char formattedDate[7]; // 6 characters for the date + 1 for the null terminator
    sprintf(formattedDate, "%02d%02d%d",d , m, y);
    // Serial.print("formatted_date = ");
    // Serial.println(formattedDate);
    return formattedDate;
}

unsigned long getCurrentTimeMillis() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (unsigned long)(tv.tv_sec) * 1000 + (unsigned long)(tv.tv_usec) / 1000;
}

void showReminders() {
  if(changedTasks){
    int num_msg=0;
    tasks_for_today = "Tasks for today: ";
    for(auto it = tasks_map.begin(); it != tasks_map.end(); it++){
        if(it->second.first.startsWith(formatDate().c_str())){
          //char buff[30];
          num_msg++;
           sprintf(buffer,"task%d is  %s  ",num_msg,it->second.second.c_str());
           //_Display.displayClear();
           Serial.println(buffer);
           tasks_for_today+=buffer;
      }
  }

      if (num_msg == 0){
      tasks_for_today = "No tasks for today - have fun";
    }
    changedTasks = false;
  }

    if(_Display.displayAnimate()) _Display.displayText(tasks_for_today.c_str(), PA_CENTER, 30, 100, PA_SCROLL_LEFT, PA_SCROLL_LEFT);
}

bool isGetTask() {
  string tmp_current_time = formatDate();
  // Serial.print("current date = ");
  // Serial.println(tmp_current_time.c_str());
  tmp_current_time+=_Time.c_str();
  String current_time = tmp_current_time.c_str();
  // Serial.print("current date = ");
  // Serial.println(current_time);
  for(auto it = tasks_map.begin(); it != tasks_map.end(); it++){
    if(it->second.first == current_time) {
      msg = it->second.second;
      task_id = it->first;
      //isTask = true;
      return true;
    }
  }
  task_id="";
  msg="";
  return false;
}


void showMessage(){
    sprintf(buffer,"you have a task now : %s. ",msg.c_str());
    if (_Display.displayAnimate()) _Display.displayText(buffer, PA_CENTER, 50, 100, PA_SCROLL_LEFT, PA_SCROLL_LEFT);
// }
}

void playTasks() {
  sprintf(buffer, "You have %d tasks for today", numTaskToday );
  audio.connecttospeech(buffer, "en");
}
