#ifndef LEG_TOUCH_SENSOR_H_
#define LEG_TOUCH_SENSOR_H_

#include <stdint.h>				// uint8_t, uint16_t

#include "io_reg_conversions.h"	// ddrFromPin(), portFromPin()

enum {lifted, lowered};

struct TouchSensor
{
	bool state;
	volatile uint8_t  &	pin_reg;
	const    uint8_t	pin_bitmap;
	
	TouchSensor(volatile uint8_t & port, uint8_t pin);
	void poll();
	bool getState();
};

TouchSensor::TouchSensor(volatile uint8_t & pin_reg, uint8_t pin_bitmap) : pin_reg(pin_reg), pin_bitmap(pin_bitmap)
{
	ddrFromPin(pin_reg)  &= ~pin_bitmap; // DDRx.y = 0,  configured as input
	portFromPin(pin_reg) &= ~pin_bitmap; // PORTx.y = 0, pullup is disabled
	poll();
}
void TouchSensor::poll()
{
	state = pin_reg & pin_bitmap;
}
bool TouchSensor::getState()
{
	return state;
}



template
<
	uint8_t leg_count,
	TouchSensor (&sensor)[leg_count]	// static array
>
struct TouchSensorControl
{
	void Poll()
	{
		for(uint8_t i = 0; i < leg_count; i++)
		{
			sensor[i].Poll();
		}
	}
	bool getState(uint8_t i)
	{
		return sensor[i].getState();
	}
};


#endif /* LEG_TOUCH_SENSOR_H_ */