
#ifndef rfm22_h
#define rfm22_h
#include <SPI.h>

#define RFM_INT_FFERR		(1 << 16)
#define RFM_INT_TXFFAFULL	(1 << 14)
#define RFM_INT_XTFFAEM		(1 << 13)
#define RFM_INT_RXFFAFULL	(1 << 12)
#define RFM_INT_EXT		(1 << 11)
#define RFM_INT_PKSENT		(1 << 10)
#define RFM_INT_PKVALID		(1 << 9)
#define RFM_INT_CRERROR		(1 << 8)

#define RFM_INT_SWDET		(1 << 7)
#define RFM_INT_PREAVAL		(1 << 6)
#define RFM_INT_PREAINVAL	(1 << 5)
#define RFM_INT_RSSI		(1 << 4)
#define RFM_INT_WUT		(1 << 3)
#define RFM_INT_LBD		(1 << 2)
#define RFM_INT_CHIPRDY		(1 << 1)
#define RFM_INT_POR		(1)

class rfm22
{
	int pin;
public:
	rfm22(uint8_t pin) : pin(pin) 
	{
		pinMode(pin, OUTPUT);
		digitalWrite(pin, HIGH);
	}
	
	uint8_t read(uint8_t addr) const;
	void write(uint8_t addr, uint8_t data) const;
	
	void read(uint8_t start_addr, uint8_t buf[], uint8_t len);
	void write(uint8_t start_addr, uint8_t data[], uint8_t len);
	void resetFIFO();
	
	boolean setFrequency(float centre);
	void init();
	
	static void initSPI();
};

#endif