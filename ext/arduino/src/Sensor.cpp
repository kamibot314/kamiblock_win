#include "Sensor.h"

float getUltrasonic(int trig,int echo){
	pinMode(trig,OUTPUT);
	digitalWrite(trig,LOW);
	delayMicroseconds(2);
	digitalWrite(trig,HIGH);
	delayMicroseconds(10);
	digitalWrite(trig,LOW);
	pinMode(echo, INPUT);
	return pulseIn(echo,HIGH,30000)/58.0;
}

byte getIR(byte pin) {
	unsigned long stopTime = micros() + IR_ON;
	unsigned long prevMicros = micros();
	pinMode(pin, OUTPUT);
	digitalWrite(pin, HIGH);
	delayMicroseconds(100);
	pinMode(pin, INPUT);
	digitalWrite(pin, LOW);
	do {
	if (micros() > stopTime)break;
	} while (digitalRead(pin));
	if (micros() >= stopTime) return 1;
	else return 0;
}