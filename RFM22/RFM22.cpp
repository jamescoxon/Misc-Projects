//RFM22 Lib - edited by James Coxon jacoxon@googlemail.com 2011
#include "RFM22.h"

uint8_t rfm22::read(uint8_t addr) const {
	//write ss low to start
	digitalWrite(pin, LOW);
	
	// make sure the msb is 0 so we do a read, not a write
	addr &= 0x7F;
	SPI.transfer(addr);
	uint8_t val = SPI.transfer(0x00);
	
	//write ss high to end
	digitalWrite(pin, HIGH);
	
	return val;
}

void rfm22::write(uint8_t addr, uint8_t data) const {
	//write ss low to start
	digitalWrite(pin, LOW);
	
	// make sure the msb is 1 so we do a write
	addr |= 0x80;
	SPI.transfer(addr);
	SPI.transfer(data);
	
	//write ss high to end
	digitalWrite(pin, HIGH);
}

void rfm22::read(uint8_t start_addr, uint8_t buf[], uint8_t len) {
	//write ss low to start
	digitalWrite(pin, LOW);

	// make sure the msb is 0 so we do a read, not a write
	start_addr &= 0x7F;
	SPI.transfer(start_addr);
	for (int i = 0; i < len; i++) {
		buf[i] = SPI.transfer(0x00);
	}

	//write ss high to end
	digitalWrite(pin, HIGH);
}
void rfm22::write(uint8_t start_addr, uint8_t data[], uint8_t len) {
	//write ss low to start
	digitalWrite(pin, LOW);

	// make sure the msb is 1 so we do a write
	start_addr |= 0x80;
	SPI.transfer(start_addr);
	for (int i = 0; i < len; i++) {
		SPI.transfer(data[i]);
	}

	//write ss high to end
	digitalWrite(pin, HIGH);
}

void rfm22::resetFIFO() {
	write(0x08, 0x03);
	write(0x08, 0x00);
}

// Returns true if centre + (fhch * fhs) is within limits
// Caution, different versions of the RF22 suport different max freq
// so YMMV
boolean rfm22::setFrequency(float centre)
{
    uint8_t fbsel = 0x40;
    if (centre < 240.0 || centre > 960.0) // 930.0 for early silicon
		return false;
    if (centre >= 480.0)
    {
		centre /= 2;
		fbsel |= 0x20;
    }
    centre /= 10.0;
    float integerPart = floor(centre);
    float fractionalPart = centre - integerPart;
	
    uint8_t fb = (uint8_t)integerPart - 24; // Range 0 to 23
    fbsel |= fb;
    uint16_t fc = fractionalPart * 64000;
    write(0x73, 0);  // REVISIT
    write(0x74, 0);
    write(0x75, fbsel);
    write(0x76, fc >> 8);
    write(0x77, fc & 0xff);
}

void rfm22::init() {
	// disable all interrupts
	write(0x06, 0x00);
	
	// move to ready mode
	write(0x07, 0x01);
	
	// set crystal oscillator cap to 12.5pf (but I don't know what this means)
	write(0x09, 0x7f);
	
	// GPIO setup - not using any, like the example from sfi
	// Set GPIO clock output to 2MHz - this is probably not needed, since I am ignoring GPIO...
	write(0x0A, 0x05);//default is 1MHz
	
	// GPIO 0-2 are ignored, leaving them at default
	write(0x0B, 0x00);
	write(0x0C, 0x00);
	write(0x0D, 0x00);
	// no reading/writing to GPIO
	write(0x0E, 0x00);
	
	// ADC and temp are off
	write(0x0F, 0x70);
	write(0x10, 0x00);
	write(0x12, 0x00);
	write(0x13, 0x00);
	
	// no whiting, no manchester encoding, data rate will be under 30kbps
	// subject to change - don't I want these features turned on?
	write(0x70, 0x20);
	
	// RX Modem settings (not, apparently, IF Filter?)
	// filset= 0b0100 or 0b1101
	// fuck it, going with 3e-club.ru's settings
	write(0x1C, 0x04);
	write(0x1D, 0x40);//"battery voltage" my ass
	write(0x1E, 0x08);//apparently my device's default
	
	// Clock recovery - straight from 3e-club.ru with no understanding
	write(0x20, 0x41);
	write(0x21, 0x60);
	write(0x22, 0x27);
	write(0x23, 0x52);
	// Clock recovery timing
	write(0x24, 0x00);
	write(0x25, 0x06);
	
	// Tx power to max
	write(0x6D, 0x04);//or is it 0x03?
	
	// Tx data rate (1, 0) - these are the same in both examples
	write(0x6E, 0x27);
	write(0x6F, 0x52);
	
	// "Data Access Control"
	// Enable CRC
	// Enable "Packet TX Handling" (wrap up data in packets for bigger chunks, but more reliable delivery)
	// Enable "Packet RX Handling"
	write(0x30, 0x8C);
	
	// "Header Control" - appears to be a sort of 'Who did i mean this message for'
	// we are opting for broadcast
	write(0x32, 0xFF);
	
	// "Header 3, 2, 1, 0 used for head length, fixed packet length, synchronize word length 3, 2,"
	// Fixed packet length is off, meaning packet length is part of the data stream
	write(0x33, 0x42);
	
	// "64 nibble = 32 byte preamble" - write this many sets of 1010 before starting real data. NOTE THE LACK OF '0x'
	write(0x34, 64);
	// "0x35 need to detect 20bit preamble" - not sure why, but this needs to match the preceeding register
	write(0x35, 0x20);
	
	// synchronize word - apparently we only set this once?
	write(0x36, 0x2D);
	write(0x37, 0xD4);
	write(0x38, 0x00);
	write(0x39, 0x00);
	
	// 4 bytes in header to send (note that these appear to go out backward?)
	write(0x3A, 's');
	write(0x3B, 'o');
	write(0x3C, 'n');
	write(0x3D, 'g');
	
	// Packets will have 1 bytes of real data
	write(0x3E, 1);
	
	// 4 bytes in header to recieve and check
	write(0x3F, 's');
	write(0x40, 'o');
	write(0x41, 'n');
	write(0x42, 'g');
	
	// Check all bits of all 4 bytes of the check header
	write(0x43, 0xFF);
	write(0x44, 0xFF);
	write(0x45, 0xFF);
	write(0x46, 0xFF);
	
	//No channel hopping enabled
	write(0x79, 0x00);
	write(0x7A, 0x00);
	
	// FSK, fd[8]=0, no invert for TX/RX data, FIFO mode, no clock
	write(0x71, 0x22);
	
	// "Frequency deviation setting to 45K=72*625"
	write(0x72, 0x48);
	
	// "No Frequency Offet" - channels?
	write(0x73, 0x00);
	write(0x74, 0x00);
	
	// "frequency set to 434MHz" board default
	write(0x75, 0x53);		
	write(0x76, 0x64);
	write(0x77, 0x00);
	
	resetFIFO();
}

void rfm22::initSPI() {
	SPI.begin();
	// RFM22 seems to speak spi mode 0
	SPI.setDataMode(SPI_MODE0);
	// Setting clock speed to 8mhz, as 10 is the max for the rfm22
	SPI.setClockDivider(SPI_CLOCK_DIV2);
	// MSB first
	//SPI.setBitOrder(MSBFIRST);
}