#include <Adafruit_NeoPixel.h>
#include "TinyWireS.h"                  // wrapper class for I2C slave routines

#define PIN 4
Adafruit_NeoPixel strip = Adafruit_NeoPixel(6, PIN, NEO_GRB + NEO_KHZ800);

#define I2C_SLAVE_ADDR  0x26            // i2c slave address (38)


#define CMD_SETPIXEL      1
#define CMD_SHOW          2
#define CMD_STOPBLINK     3
#define CMD_LEDON         4
#define CMD_LEDOFF        5
#define CMD_MAX           7

void setup() {
  strip.begin();
  strip.show(); // Initialize all pixels to 'off'

  for(int i = -64; i < 255+32; i++)
  {
    for(int l = 0; l < strip.numPixels(); l++)
    {
      int dist = min(255, abs(i - (255 / 6) * l) * 4);
      strip.setPixelColor(l, strip.Color(255-dist,255-dist,255-dist));
    }
    strip.show();
    delay(2);
  }
  TinyWireS.begin(I2C_SLAVE_ADDR);      // init I2C Slave mode
}


byte command[4];
int index = 0;
unsigned long lastrecv = millis();
int intensity = 0;
int inc = 1;

void loop() {
  if(intensity >= 0)
  {
    intensity += inc;
    if(intensity > 1280 || intensity == 0)
      inc = -inc;
    for(int l = 0; l < strip.numPixels(); l++)
    {
      strip.setPixelColor(l, strip.Color(intensity/100,intensity/100,intensity/100));
    }
    strip.show();
  
  }
  
  // put your main code here, to run repeatedly:
  byte byteRcvd = 0;
  if (TinyWireS.available()){           // got I2C input!
    unsigned long time = millis();
    if(time-lastrecv > 1000)
      index = 0;
    lastrecv = time;
    command[index++] = TinyWireS.receive();     // get the byte from master
    if(index >= 1)
    {
      intensity = -1;
      int opcode = command[0]&0x7;
      if(opcode == CMD_SETPIXEL)
      {
        if(index != 4)
          return;
        int pixel = command[0]>>3;
        strip.setPixelColor(pixel, strip.Color(command[1],command[2],command[3]));
      }
      else if(opcode == CMD_SHOW)
      {
        intensity = -1;
        strip.show();
      }
      else if(opcode == CMD_STOPBLINK)
      {
        for(int l = 0; l < strip.numPixels(); l++)
        {
          strip.setPixelColor(l, 0);
        }
        intensity = -1;
        strip.show();
      }
      else if(opcode == CMD_LEDON)
      {
        digitalWrite(3, HIGH);
      }
      else if(opcode == CMD_LEDOFF)
      {
        digitalWrite(3, LOW);
      }
      index = 0;
    }
  }

}



void Blink(byte led, byte times){
  for (byte i=0; i< times; i++){
    digitalWrite(led,HIGH);
    delay (250);
    digitalWrite(led,LOW);
    delay (175);
  }
}
