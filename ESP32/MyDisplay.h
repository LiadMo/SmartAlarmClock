#ifndef DISPLAY_H
#define DISPLAY_H

// Include Libraries
#include <MD_Parola.h>
#include <MD_MAX72xx.h>
#include <SPI.h>
#include "Font.h"

// Define PINs
#define HARDWARE_TYPE MD_MAX72XX::FC16_HW
#define MAX_DEVICES 4

#define CLK_PIN   14
#define DATA_PIN  13
#define CS_PIN    12

// Define Display
MD_Parola _Display = MD_Parola(HARDWARE_TYPE, DATA_PIN, CLK_PIN, CS_PIN, MAX_DEVICES);

void DisplayInit() {
  _Display.begin();
  _Display.setFont(0, numeric7Se);
  _Display.setTextAlignment(PA_CENTER);
}
#endif