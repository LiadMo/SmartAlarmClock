#ifndef MYAUDIO_H
#define MYAUDIO_H

#include "Audio.h"

// SD Card Pins
#define SD_CS          5
#define SPI_MOSI      23 
#define SPI_MISO      19 //
#define SPI_SCK       18

// Audio Pins
#define I2S_BCLK 26
#define I2S_LRC 25
#define I2S_DOUT 22

// Define Audio
Audio audio;

#endif