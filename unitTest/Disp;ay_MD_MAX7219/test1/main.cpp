// Header file includes
#include <WiFi.h>
#include <time.h>
#include <MD_Parola.h>
#include <SPI.h>
#include "Font.h"

void getTimentp();

#define HARDWARE_TYPE MD_MAX72XX::FC16_HW
#define MAX_DEVICES 4

#define CLK_PIN 18   // or SCK
#define DATA_PIN 23  // or MOSI
#define CS_PIN 5     // or SS
#define INPUT_PIN 39 // or VN

// Arbitrary output pins
MD_Parola myDisplay = MD_Parola(HARDWARE_TYPE, DATA_PIN, CLK_PIN, CS_PIN, MAX_DEVICES);

#define SPEED_TIME 75
#define PAUSE_TIME 0
#define MAX_MESG 20

/**********  User Config Setting   ******************************/
char *ssid = "tabri";
char *password = "0507428601";
// calculate your timezone in seconds, 1 hour = 3600 seconds
const int timezoneinSeconds = 3 * 3600;
/***************************************************************/

int dst = 0;
uint16_t h, m, s;
uint8_t dow;
int day;
uint8_t month;
String year;
// Global variables
char szTime[9];   // mm:ss\0
char szsecond[4]; // ss
char szMesg[MAX_MESG + 1] = "";

void getsec(char *psz)
{
  sprintf(psz, "%02d", s);
}

void getTime(char *psz, bool f = true)
{
  time_t now = time(nullptr);
  struct tm *p_tm = localtime(&now);
  h = p_tm->tm_hour;
  m = p_tm->tm_min;
  s = p_tm->tm_sec;
  // sprintf(psz, "%02d%c%02d", h, (f ? ':' : ' '), m); // for pulsing effect
  sprintf(psz, "%02d%c%02d", h, ':', m);
  Serial.println(psz);
}

void getTimentp()
{
  configTime(timezoneinSeconds, dst, "pool.ntp.org", "time.nist.gov");
  while (!time(nullptr))
  {
    delay(500);
    Serial.print(".");
  }
  Serial.print("Time Update");
}

void setup(void)
{
  Serial.begin(9600);
  delay(10);

  Serial.println();
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
  delay(3000);
  WiFi.mode(WIFI_STA);
  getTimentp();

  myDisplay.begin(3);
  // myDisplay.setInvert(true);
  myDisplay.setZone(0, 0, 0);
  myDisplay.setZone(1, 1, 3);
  myDisplay.setFont(0, numeric7Seg);
  myDisplay.setFont(1, numeric7Se);
  myDisplay.displayZoneText(0, szsecond, PA_CENTER, SPEED_TIME, 0, PA_PRINT, PA_NO_EFFECT);
  myDisplay.displayZoneText(1, szTime, PA_CENTER, SPEED_TIME, PAUSE_TIME, PA_PRINT, PA_NO_EFFECT);

  getTime(szTime);
}

void loop(void)
{
  static uint32_t lastTime = 0; // millis() memory
  static uint8_t display = 0;   // current display mode
  static bool flasher = false;  // seconds passing flasher

  // for the input
  int val = analogRead(INPUT_PIN);
  myDisplay.setIntensity(15 - (val / (4095 / 15)));
  delay(1000);

  myDisplay.displayAnimate();

  if (millis() - lastTime >= 1000)
  {
    lastTime = millis();
    getsec(szsecond);
    getTime(szTime, flasher);
    flasher = !flasher;

    myDisplay.displayReset(0);
    myDisplay.displayReset(1);
  }
}
