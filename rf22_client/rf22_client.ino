  // rf22_client.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple messageing client
// with the RF22 class. RF22 class does not provide for addressing or reliability.
// It is designed to work with the other example rf22_server

#include <SPI.h>
#include <RF22.h>

// Singleton instance of the radio
RF22 rf22(10,0);

int intTemp = 0, count = 1, n;
char superbuffer [80]; //Telem string buffer
byte data [80];

//Taken from RFM22 library + navrac
uint8_t adcRead(uint8_t adcsel)
{
    uint8_t configuration = adcsel;
    rf22.spiWrite(0x0f, configuration | 0x80);
    rf22.spiWrite(0x10, 0x00);

    // Conversion time is nominally 305usec
    // Wait for the DONE bit
    while (!(rf22.spiRead(0x0f) & 0x80))
	;
    // Return the value  
    return rf22.spiRead(0x11);
}

uint8_t temperatureRead(uint8_t tsrange, uint8_t tvoffs)
{
    rf22.spiWrite(0x12, tsrange | 0x20);
    rf22.spiWrite(0x13, tvoffs);
    return adcRead(0x00 | 0x00); 
}

void CharToByte(char* chars, byte* bytes, unsigned int count){
    for(unsigned int i = 0; i < count; i++)
    	bytes[i] = (byte)chars[i];
}

void prepData() {
  count++;
  intTemp = temperatureRead( 0x00,0 ) / 2;  //from RFM22
  intTemp = intTemp - 64;
  n=sprintf (superbuffer, "$$DOOR,%d,%d**\n", count, intTemp);
}

void setup() 
{
  pinMode(A3,OUTPUT);
  digitalWrite(A3, LOW);
  Serial.begin(9600);
  if (!rf22.init())
    Serial.println("RF22 init failed");
  // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
  rf22.setModemConfig(RF22::GFSK_Rb2Fd5);
  rf22.setTxPower(RF22_TXPOW_14DBM);
  rf22.setFrequency(434.150);
}

void loop()
{
  delay(1000);  
  
  prepData();
  CharToByte(superbuffer, data, sizeof(superbuffer));
  Serial.println("Sending to rf22_server");
    
    rf22.send(data, sizeof(data));
   
    rf22.waitPacketSent();
    Serial.println("Done");
    
    count++;
}

