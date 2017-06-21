#include "servo.h"
#include "io_reg_conversions.h"	// ddrFromPin(), portFromPin()

Servo::Servo(uint16_t deg_range, volatile uint8_t & port_reg, uint8_t pin_bitmap, uint16_t tick_min, uint16_t tick_max, uint16_t pot_min, uint16_t pot_max)
	:	deg_range(deg_range),
		port_reg(port_reg),
		pin_bitmap(pin_bitmap),
		tick_min(tick_min),
		tick_max(tick_max),
		tick(Servo::disabled),
		pot_min(pot_min),
		pot_max(pot_max),
		pot(pot_min)
{
	ddrFromPort(port_reg) |= pin_bitmap; // DDRx.y = 1, configured as output
}

inline static uint16_t mapValue(int16_t x, int16_t in_min, int16_t in_max, int16_t out_min, int16_t out_max) 	__attribute__((always_inline));

inline static uint16_t mapValue(int16_t x, int16_t in_min, int16_t in_max, int16_t out_min, int16_t out_max)
{
	if(x <  in_min)	return out_min;
	if(x >  in_max)	return out_max;
	return uint32_t(x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

uint16_t Servo::checkPositionInTick(uint32_t new_position)
{
	if ((new_position >= tick_min  &&
		 new_position <= tick_max) ||
		 new_position == Servo::disabled)
	{
		return new_position;
	}
	else if (new_position < tick_min)
	{
		return tick_min;
	}
	else // if (new_position > tick_max)
	{
		return tick_max;
	}
}
void Servo::setPositionInTick(uint16_t new_position)
{
	tick = checkPositionInTick(new_position);
}
void Servo::setPositionInDeg(float new_position)
{
	if(new_position >= 0)
		setPositionInTick( deg2Tick(new_position) );
	else
		setPositionInTick( Servo::disabled );
}

// microseconds -> ...
uint16_t Servo::micros2Tick(uint16_t value_micros)
{
	return uint32_t(value_micros) * (F_CPU / 1000000) / timer_prescaler;
}

// timer ticks -> ...
uint16_t Servo::tick2Micros(uint16_t value_tick)
{
	return uint32_t(value_tick) * timer_prescaler / (F_CPU / 1000000);
}
uint16_t Servo::tick2Micros()
{
	return tick2Micros(tick);
}

float  Servo::tick2Deg(uint16_t value_tick)
{
	// map [tick_min, tick_max] to [0, deg_range]
	//return uint32_t(value_tick - tick_min) * deg_range / (tick_max - tick_min);
	if(value_tick != Servo::disabled)
		return mapValue(value_tick,  tick_min, tick_max,  0, deg_range);
	else
		return -1;
}
float  Servo::tick2Deg()
{
	return tick2Deg(tick);
}

uint16_t Servo::tick2Pot(uint16_t value_tick)
{
	// map [tick_min, tick_max] to [pot_min, pot_max]
	//return uint32_t(value_tick - tick_min) * (pot_max - pot_min) / (tick_max - tick_min) + pot_min;
	return mapValue(value_tick,  tick_min, tick_max,  pot_min, pot_max);
}
uint16_t Servo::tick2Pot()
{
	return tick2Pot(tick);
}

// potentiometer value -> ...
float  Servo::pot2Deg(uint16_t value_pot)
{
	// map [pot_min, pot_max] to [0, deg_range]
	//return uint32_t(value_pot - pot_min) * deg_range / (pot_max - pot_min);
	return mapValue(value_pot,  pot_min, pot_max,  0, deg_range);
}
float  Servo::pot2Deg()
{
	return pot2Deg(pot);
}

uint16_t Servo::pot2Tick(uint16_t value_pot)
{
	// map [pot_min, pot_max] to [tick_min, tick_max]
	//return uint32_t(value_pot - pot_min) * (tick_max - tick_min) / (pot_max - pot_min) + tick_min;
	return mapValue(value_pot,  pot_min, pot_max,  tick_min, tick_max);
}
uint16_t Servo::pot2Tick()
{
	return pot2Tick(pot);
}

// degrees -> ...
uint16_t Servo::deg2Tick(float value_deg)
{
	// map [0, deg_range] to [tick_min, tick_max]
	return uint32_t(value_deg * (tick_max - tick_min)) / deg_range + tick_min;
}
uint16_t Servo::deg2Pot(float value_deg)
{
	// map [0, deg_range] to [pot_min, pot_max]
	return uint32_t(value_deg * (pot_max - pot_min)) / deg_range + pot_min;
}


Servo & Servo::operator = (const Servo & right)
{
	if (this == &right)
		return *this;
	this->tick = right.tick;
	return *this;
}