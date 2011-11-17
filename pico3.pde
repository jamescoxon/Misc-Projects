#include <avr/sleep.h>
#include <avr/wdt.h>
#include <SPI.h>
#include <RFM22.h>
#include "TinyGPS.h"

#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

volatile boolean f_wdt=1;

rfm22 radio1(10); // radio 1 with NSEL on pin 10

//Initiate GPS
TinyGPS gps;

int count = 0, j, q, n, hour = 0 , minute = 0 , second = 0, battV = 0, dataloop = 10, gpsonoff = 0, solarV = 0, i = 0, x = 0, slowfeld = 0, daynight = 0;
unsigned long date, time, chars, age;
long int ialt = 123, lat = 5200, lon = 100;

char latbuf[12] = "0", lonbuf[12] = "0", countbuf[12] = "0";

char superbuffer [80];
char message[4] = {'P', 'I', 'C', 'O'};

struct t_htab { char c; int hellpat[5]; } ;

struct t_htab helltab[] = {

  {'1', { B00000100, B00000100, B01111100, B00000000, B00000000 } },
  {'2', { B01001000, B01100100, B01010100, B01001100, B01000000 } },
  {'3', { B01000100, B01000100, B01010100, B01010100, B00111100 } },
  {'4', { B00011100, B00010000, B00010000, B01111100, B00010000 } },
  {'5', { B01000000, B01011100, B01010100, B01010100, B00110100 } },
  {'6', { B00111100, B01010010, B01001010, B01001000, B00110000 } },
  {'7', { B01000100, B00100100, B00010100, B00001100, B00000100 } },
  {'8', { B00111100, B01001010, B01001010, B01001010, B00111100 } },
  {'9', { B00001100, B01001010, B01001010, B00101010, B00111100 } },
  {'0', { B00111000, B01100100, B01010100, B01001100, B00111000 } },
  {'A', { B01111000, B00101100, B00100100, B00101100, B01111000 } },
  {'B', { B01000100, B01111100, B01010100, B01010100, B00101000 } },
  {'C', { B00111000, B01101100, B01000100, B01000100, B00101000 } },
  {'D', { B01000100, B01111100, B01000100, B01000100, B00111000 } },
  {'E', { B01111100, B01010100, B01010100, B01000100, B01000100 } },
  {'F', { B01111100, B00010100, B00010100, B00000100, B00000100 } },
  {'G', { B00111000, B01101100, B01000100, B01010100, B00110100 } },
  {'H', { B01111100, B00010000, B00010000, B00010000, B01111100 } },
  {'I', { B00000000, B01000100, B01111100, B01000100, B00000000 } },
  {'J', { B01100000, B01000000, B01000000, B01000000, B01111100 } },
  {'K', { B01111100, B00010000, B00111000, B00101000, B01000100 } },
  {'L', { B01111100, B01000000, B01000000, B01000000, B01000000 } },
  {'M', { B01111100, B00001000, B00010000, B00001000, B01111100 } },
  {'N', { B01111100, B00000100, B00001000, B00010000, B01111100 } },
  {'O', { B00111000, B01000100, B01000100, B01000100, B00111000 } },
  {'P', { B01000100, B01111100, B01010100, B00010100, B00011000 } },
  {'Q', { B00111000, B01000100, B01100100, B11000100, B10111000 } },
  {'R', { B01111100, B00010100, B00010100, B00110100, B01011000 } },
  {'S', { B01011000, B01010100, B01010100, B01010100, B00100100 } },
  {'T', { B00000100, B00000100, B01111100, B00000100, B00000100 } },
  {'U', { B01111100, B01000000, B01000000, B01000000, B01111100 } },
  {'V', { B01111100, B00100000, B00010000, B00001000, B00000100 } },
  {'W', { B01111100, B01100000, B01111100, B01000000, B01111100 } },
  {'X', { B01000100, B00101000, B00010000, B00101000, B01000100 } },
  {'Y', { B00000100, B00001000, B01110000, B00001000, B00000100 } },
  {'Z', { B01000100, B01100100, B01010100, B01001100, B01100100 } },
  {'.', { B01000000, B01000000, B00000000, B00000000, B00000000 } },
  {',', { B10000000, B10100000, B01100000, B00000000, B00000000 } },
  {'/', { B01000000, B00100000, B00010000, B00001000, B00000100 } },
  {'*', { B00000000, B00000000, B00000100, B00001110, B00000100 } }

};

#define N_HELL  (sizeof(helltab)/sizeof(helltab[0]))

void helldelay()
{
  if(slowfeld == 1){
  //Slow
  delay(64);
  delayMicroseconds(900);
  }
  else
  {
  //Feld-Hell
  delay(8);
  delayMicroseconds(160);
  }

}



void on()
{
  radio1.write(0x07, 0x08);
  helldelay();
  radio1.write(0x07, 0x01);
}

void hellsend(char c)
{
  int i ;
  if (c == ' ') {
      for (int d=0; d<14; d++){
        helldelay();  
      }
    return ;
  }
  for (i=0; i<N_HELL; i++) {
    if (helltab[i].c == c) {
      //Serial.print(helltab[i].c) ;
      
      for (j=0; j<=4; j++) 
      {
        byte mask = B10000000;
        for (q=0; q<=6; q++)
        {      
          if(helltab[i].hellpat[j] & mask) {
            on();
          } else {
            helldelay();
          }
          mask >>= 1;
        }
      }
      for (int d=0; d<14; d++){
        helldelay();  
      }
      return ;
    }
  }
  /* if we drop off the end, then we send a space */
  //Serial.print("?") ;
}

void hellsendmsg(char *str)
{
  while (*str)
    hellsend(*str++) ;
  //Serial.println("");
}

void setupGPS() {
    //Turning off all GPS NMEA strings apart on the uBlox module
  Serial.println("$PUBX,40,GLL,0,0,0,0*5C");
  delay(1000);
  Serial.println("$PUBX,40,GGA,0,0,0,0*5A");
  delay(1000);
  Serial.println("$PUBX,40,GSA,0,0,0,0*4E");
  delay(1000);
  Serial.println("$PUBX,40,RMC,0,0,0,0*47");
  delay(1000);
  Serial.println("$PUBX,40,GSV,0,0,0,0*59");
  delay(1000);
  Serial.println("$PUBX,40,VTG,0,0,0,0*5E");
  delay(3000); // Wait for the GPS to process all the previous commands
  
  wdt_reset();
  delay(1000);
  
  //set GPS to Eco mode (reduces current by 4mA)
  uint8_t setEco[] = {0xB5, 0x62, 0x06, 0x11, 0x02, 0x00, 0x00, 0x04, 0x1D, 0x85};
  sendUBX(setEco, sizeof(setEco)/sizeof(uint8_t));
  
}

unsigned int gps_checksum (char * string)
{	
	unsigned int i;
	unsigned int XOR;
	unsigned int c;
	// Calculate checksum ignoring any $'s in the string
	for (XOR = 0, i = 0; i < strlen(string); i++)
	{
		c = (unsigned char)string[i];
		if (c != '$') XOR ^= c;
	}
	return XOR;
}

//****************************************************************  
// set system into the sleep state 
// system wakes up when wtchdog is timed out
void system_sleep() {

  cbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter OFF

  set_sleep_mode(SLEEP_MODE_PWR_DOWN); // sleep mode is set here
  sleep_enable();

  sleep_mode();                        // System sleeps here

    sleep_disable();                     // System continues execution here when watchdog timed out 
    sbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter ON

}

//****************************************************************
// 0=16ms, 1=32ms,2=64ms,3=128ms,4=250ms,5=500ms
// 6=1 sec,7=2 sec, 8=4 sec, 9= 8sec
void setup_watchdog(int ii) {

  byte bb;
  int ww;
  if (ii > 9 ) ii=9;
  bb=ii & 7;
  if (ii > 7) bb|= (1<<5);
  bb|= (1<<WDCE);
  ww=bb;
  //Serial.println(ww);


  MCUSR &= ~(1<<WDRF);
  // start timed sequence
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  // set new watchdog timeout value
  WDTCSR = bb;
  WDTCSR |= _BV(WDIE);


}

//****************************************************************  
// Watchdog Interrupt Service / is executed when  watchdog timed out
ISR(WDT_vect) {
  f_wdt=1;  // set global flag
}

void gpsOn(){
   digitalWrite(2, HIGH);
   delay(1000);
   setupGPS();
   gpsonoff = 1;
}

void gpsOff(){
   digitalWrite(2, LOW);
   gpsonoff = 0;
   dataloop = 10;
}

// Send a byte array of UBX protocol to the GPS
void sendUBX(uint8_t *MSG, uint8_t len) {
  for(int i=0; i<len; i++) {
    Serial.print(MSG[i], BYTE);
  }
  Serial.println();
}

void setup() {
  pinMode(2, OUTPUT); //GPS Pwr
  digitalWrite(2, LOW); 
  Serial.begin(9600);
  rfm22::initSPI();

  radio1.init();
  
  radio1.write(0x71, 0x00); // unmodulated carrier
  
  radio1.write(0x07, 0x08); // turn tx on
  delay(1000);
  radio1.write(0x07, 0x01); // turn tx off
  
    // CPU Sleep Modes 
  // SM2 SM1 SM0 Sleep Mode
  // 0    0  0 Idle
  // 0    0  1 ADC Noise Reduction
  // 0    1  0 Power-down
  // 0    1  1 Power-save
  // 1    0  0 Reserved
  // 1    0  1 Reserved
  // 1    1  0 Standby(1)

  cbi( SMCR,SE );      // sleep enable, power down mode
  cbi( SMCR,SM0 );     // power down mode
  sbi( SMCR,SM1 );     // power down mode
  cbi( SMCR,SM2 );     // power down mode

  setup_watchdog(9);
}

void loop()
{  
  if (f_wdt==1) {  // wait for timed out watchdog / flag is set when a watchdog timeout occurs
    f_wdt=0;       // reset flag
    
     count++;
     
     battV = analogRead(1);
     solarV = analogRead(2);
     
     //Serial.print("TEST");
     //Serial.println(battV);
     
     //Turn GPS off after 50 loops even if no lock
     if(gpsonoff == 1 && (count % 50) == 0){
       gpsOff();
     }
     
     //DAYTIME
     if(solarV > 300){
       daynight = 0;
       //Daytime so GPS on more often
       if((count % 100) == 0) {
         if(gpsonoff == 0 && battV > 350){
           gpsOn();
         }
       }
       //Normal gap between transmissions
       dataloop = 10;
     }
     
     //NIGHT
     if(solarV < 300){
       daynight = 1;
       //Longer gap between gps as at night
       if((count % 400) == 0) {
         if(gpsonoff == 0 && battV > 350){
           gpsOn();
         }
       }
       //Increase gap between transmissions
       if(gpsonoff == 1 ){
         dataloop = 10;
       }
       else {
         dataloop = 50;
       }
     }
     
     //Emergency Low Power
     if(battV < 330) {
       gpsOff();
       dataloop = 50;
     }
   
   if((count % dataloop) == 0) {
   Serial.println("$PUBX,00*33"); //Poll GPS
      while (Serial.available())
      {
        int c = Serial.read();
        if (gps.encode(c))
        {
          //Get Data from GPS library
          //Get Time and split it
          gps.get_datetime(&date, &time, &age);
          hour = (time / 1000000);
          minute = ((time - (hour * 1000000)) / 10000);
          second = ((time - ((hour * 1000000) + (minute * 10000))));
          second = second / 100;
          
          //Get Position
          gps.get_position(&lat, &lon, &age);
          
          // +/- altitude in meters
          ialt = (gps.altitude() / 100);
         
          if(gpsonoff == 1 && lat != 0){
                gpsOff();
          }
         
        }
      }
    
    n=sprintf (superbuffer, "PICO,%d,%02d:%02d:%02d,%ld,%ld,%ld,%d,%d,%d", count, hour, minute, second, lat, lon, ialt, battV, solarV, gpsonoff);
    n = sprintf (superbuffer, "%s*%02X\n", superbuffer, gps_checksum(superbuffer));
    hellsendmsg(superbuffer);
    radio1.write(0x07, 0x01); //make sure radio is not txing

    delay(1000);
   }
   else {
     if (daynight == 0) {
       if((count % 2) == 0) {
         if(x == 0) {
          hellsendmsg("P");
          x++;
         }
         else if (x == 1) {
          hellsendmsg("I");
          x++;
         }
         else if (x == 2) {
          hellsendmsg("C");
          x++;
         }
         else if (x == 3) {
          hellsendmsg("O");
          x = 0;
         }
       }
     }
     else{
       if((count % 25) == 0){
         slowfeld = 1;
         hellsendmsg("PICO");
         slowfeld = 0;
       }
     }
     radio1.write(0x07, 0x01); //make sure radio is not txing
   }
  }
  
  system_sleep();
}
