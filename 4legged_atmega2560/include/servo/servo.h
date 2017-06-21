#ifndef _SERVO_H_
#define _SERVO_H_

#include <stdint.h>			// uint8_t, uint16_t


struct Servo
{
	static const uint16_t timer_prescaler = 8;
	
	const uint16_t		deg_range;
	volatile uint8_t  &	port_reg;
	const    uint8_t	pin_bitmap;
	
	/* PWM values to servo */
	static const uint16_t	disabled = 0xffff;
	/*const*/ uint16_t		tick_min, tick_max;
	uint16_t				tick;
	
	/* ADC values from potentiometer */
	uint16_t pot_min, pot_max;
	uint16_t pot;


	Servo(uint16_t deg_range, volatile uint8_t & port_reg, uint8_t pin_bitmap, uint16_t tick_min, uint16_t tick_max, uint16_t pot_min, uint16_t pot_max);
	
	
	uint16_t checkPositionInTick(uint32_t new_position);
	void setPositionInTick(uint16_t new_position);
	void setPositionInDeg(float new_position);
	//void setPositionInDeg(uint8_t new_position);
	
	// microseconds -> ...
	uint16_t micros2Tick(uint16_t value_micros);

	// timer ticks -> ...
	uint16_t tick2Micros(uint16_t value_tick);
	uint16_t tick2Micros();

	float  tick2Deg(uint16_t value_tick);
	float  tick2Deg();

	uint16_t tick2Pot(uint16_t value_tick);
	uint16_t tick2Pot();

	// potentiometer value -> ...
	float  pot2Deg(uint16_t value_pot);
	float  pot2Deg();

	uint16_t pot2Tick(uint16_t value_pot);
	uint16_t pot2Tick();
	
	// degrees -> ...
	//uint16_t deg2Tick(uint8_t value_deg);
	//uint16_t deg2Pot(uint8_t value_deg);
	uint16_t deg2Tick(float value_deg);
	uint16_t deg2Pot(float value_deg);

	Servo & operator = (const Servo & right);
};
#pragma region defining relational operators  

#define COMPARISON_OP(OP)									\
	inline bool operator OP (Servo & left, Servo & right)	\
	{														\
		return left.tick OP right.tick;						\
	}
	COMPARISON_OP(<)
	COMPARISON_OP(>)
	COMPARISON_OP(==)
	COMPARISON_OP(!=)
	COMPARISON_OP(<=)
	COMPARISON_OP(>=)
#undef COMPARISON_OP

#pragma endregion



#endif // _SERVO_H_