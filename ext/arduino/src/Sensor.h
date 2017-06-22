/*
Kamibot Basic  Program Ver0.3
2016.01.30  Ver0.3
- Servo noise modification
- IR Read Modification
- line Block Funtion Addtion

- Ver 0.2 : Motor Speed control protocol insert update
*/

#ifndef _SENEOR_h
#define _SENEOR_h

#if defined(ARDUINO) && ARDUINO >= 100
	#include "arduino.h"
#else
	#include "WProgram.h"
#endif

#define IR_ON 300

float getUltrasonic(int trig,int echo);
byte getIR(byte pin);

#endif

