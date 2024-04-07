

#if defined(ESP32)
#include <WiFi.h>
#elif defined(ESP8266)
#include <ESP8266WiFi.h>
#endif

#include "secrets.h"

#include <Firebase_ESP_Client.h>

// Provide the token generation process info.
#include <addons/TokenHelper.h>

// Provide the RTDB payload printing info and other helper functions.
#include <addons/RTDBHelper.h>

#define LED_PIN 2

// Define Firebase Data object
FirebaseData stream;
FirebaseData fbdo;

FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
unsigned long blocking_call_millis = 0;
unsigned int taskDuration = 0;

// int count = 0;

String parentPath = "/command";
String childPath[2] = {"/type", "/runningCount"};

volatile bool dataChanged = false;

int incomingData [2] = {3,0};

enum Status {
    IDLE = 1,
    RUNNING = 2
};
Status currentStatus = IDLE; // currently - 1 = idle, 2 = running

enum Command {
    ERROR =0,
    TURN = 1,
    FORWARD = 2,
    STOP=3
};
Command currentCommand = STOP; // currently - 1 = turn, 2 = forward, 3 = stop


void streamCallback(MultiPathStream stream)
{
  size_t numChild = sizeof(childPath) / sizeof(childPath[0]);
for (size_t i = 0; i < numChild; i++)
  {
    if (stream.get(childPath[i]))
    {
      // Serial.printf("path: %s, event: %s, type: %s, value: %s%s", stream.dataPath.c_str(), stream.eventType.c_str(), stream.type.c_str(), stream.value.c_str(), i < numChild - 1 ? "\n" : "");
      incomingData[i] = atoi(stream.value.c_str()); //atoi converts string to int
    }
  }

    int eventType = incomingData[0];
  int runningCount = incomingData[1];
  Serial.printf("\neventType: %d , runningCount: %d \n", eventType,runningCount);

  Serial.printf("Received stream payload size: %d (Max. %d)\n\n", stream.payloadLength(), stream.maxPayloadLength());

  if(eventType < IDLE || eventType > STOP) {
    currentCommand = ERROR;
  }
  else {
    currentCommand = static_cast<Command>(eventType);
  }
  
  // Due to limited of stack memory, do not perform any task that used large memory here especially starting connect to server.
  // Just set this flag and check it status later.
  dataChanged = true;
}

void streamTimeoutCallback(bool timeout)
{
  if (timeout)
    Serial.println("stream timed out, resuming...\n");

  if (!stream.httpConnected())
    Serial.printf("error code: %d, reason: %s\n\n", stream.httpCode(), stream.errorReason().c_str());
}

void setup()
{

  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);

  /* Assign the api key (required) */
  config.api_key = API_KEY;

  /* Assign the user sign in credentials */
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  /* Assign the RTDB URL (required) */
  config.database_url = DATABASE_URL;

  /* Assign the callback function for the long running token generation task */
  config.token_status_callback = tokenStatusCallback; // see addons/TokenHelper.h

  // To connect without auth in Test Mode, see Authentications/TestMode/TestMode.ino

  Firebase.begin(&config, &auth);

  Firebase.reconnectWiFi(true);

  if (!Firebase.RTDB.beginMultiPathStream(&stream, parentPath))
    Serial.printf("stream begin error, %s\n\n", stream.errorReason().c_str());
  else {
    digitalWrite(LED_PIN, HIGH); // turn on LED to indicate that stream is connected
  }
  Firebase.RTDB.setMultiPathStreamCallback(&stream, streamCallback, streamTimeoutCallback);

}

void update_status_blocking(int status) //this is a blocking call that takes on average 0.2 seconds to complete on a decent wifi connection. But can take up to 1 second on a bad connection
{
  blocking_call_millis = millis();
  Serial.printf("Set status to %d... %s\n", status, Firebase.RTDB.setInt(&fbdo, F("/status"), status) ? "ok" : fbdo.errorReason().c_str());
  Serial.print ("duration of blocking call - ms: "); 
  Serial.println (millis()-blocking_call_millis);
}

void update_status_async(int status) 
//this is a blocking call that takes on average 0.2 seconds to complete. 
// the action is done 'in the background' so the advantage is that other code can be executed while the update is performed
{
  blocking_call_millis = millis();
  Serial.printf("Set status to %d... \n", status, Firebase.RTDB.setIntAsync(&fbdo, F("/status"), status) );
  Firebase.RTDB.setIntAsync(&fbdo, F("/status"), status); //TODO for some reason the last call is not performed, so need to call twice
  Firebase.RTDB.setIntAsync(&fbdo, F("/status"), status);
  Serial.print ("duration of async call - ms: "); 
  Serial.println (millis()-blocking_call_millis);
}

void printCommand(Command command) {
  Serial.print("\nCommand received: ");
    switch(command) {
        case TURN:
            Serial.println("TURN");
            taskDuration = 5000;
            break;
        case FORWARD:
            Serial.println("FORWARD");
            taskDuration = 5000;
            break;
        case STOP:
            Serial.println("STOP");
            taskDuration = 10;
            break;
        default:
            Serial.println("ERROR");
            taskDuration = 10;
    }
}

void loop()
{

  Firebase.ready(); // should be called repeatedly to handle authentication tasks.

  if (dataChanged) //this funcion runs when a new command is received from the server
  {
    dataChanged = false;
    currentStatus=RUNNING; // set status to 2 when data is received to symbolize that we are performing an action
    printCommand(currentCommand);
    digitalWrite(LED_PIN, LOW);
    update_status_async(currentStatus);  
    sendDataPrevMillis = millis();
  }

    if ((millis() - sendDataPrevMillis > taskDuration) && currentStatus==RUNNING) // if 6 seconds have passed since action started, update status back to idle
  {
    currentStatus=IDLE; // set status to 1 when action is complete to symbolize return to idle state
    digitalWrite(LED_PIN, HIGH);
    update_status_blocking(currentStatus);
  }

}
