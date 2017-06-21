#ifndef SERVO_CONTROLLER_H_
#define SERVO_CONTROLLER_H_

#include <stdint.h>			// uint8_t, uint16_t
#include <string.h>			// memcpy()
#include <stdlib.h>			// abs()
#include <avr/io.h>			// avr/iom2560.h - timer 1
#include <avr/cpufunc.h>	// _MemoryBarrier()
#include <util/delay.h>		// _delay_ms()
#include <stdio.h>			// printf()

#include "servo.h"
#include "static_sort.h"
#include "adc_control.h"
#include "io_reg_conversions.h"	// ddrFromPin(), portFromPin()



#ifdef DEBUG
#define DEBUG_PRINTF(flash_format_str, ...)	printf(flash_format_str, ##__VA_ARGS__)
#else
#define DEBUG_PRINTF(...)
#endif


void pregenerated_sort(Servo *arr[]);
void pregenerated_sort(Servo *arr[])
{
#define SWAP(a,b)			\
if(a>b)						\
{							\
	Servo *tmp = arr[a];	\
	arr[a] = arr[b];		\
	arr[b] = tmp;			\
}
	
	if(arr[0]->tick > arr[1]->tick)
	{
		Servo *tmp = arr[0];
		arr[0] = arr[1];
		arr[1] = tmp;
		DEBUG_PRINTF("swap\n");
	}
	{
		
	}
	//SWAP(0, 1);

#undef SWAP
}

template
<
	uint8_t servo_count,
	Servo (&servo)[servo_count],	// static array
	class T,						// ADC controller type (AdcController<sample_count>)
	T &adc							// reference to ADC controller
>
class ServoControl
{
public://private:
/* Servos */
	// uint8_t		servo_count			- remember about template parameter
	// Servo	  (&servo)[servo_count]	- remember about template parameter
	Servo		   *servo_sorted[servo_count];
	uint16_t		new_data[servo_count];
	volatile bool	data_can_be_changed;
	uint8_t			servo_idx; // it seems that it is not volatile, not used outside the ISR
/* Sorting */
	struct ServoPtrFunctor
	{
		bool operator()(Servo *left, Servo *right)
		{
			return left->tick < right->tick;
		}
	};
	static StaticSort<servo_count, ServoPtrFunctor> static_sort;

	uint16_t mapValue(int32_t x, int32_t in_min, int32_t in_max, int32_t out_min, int32_t out_max);
public:
	ServoControl();
	
	void			set(uint16_t my_new_data[]);
	uint16_t*		set();
	const uint16_t*	get();

	
	constexpr uint8_t getServoCount()
	{
		return servo_count;
	}
	constexpr Servo (&getServo()) [servo_count] // or set return type to ServoRef: using ServoRef=Servo(&)[servo_count];
	{
		return servo;
	}

	void update();
	
	void toCurrentPosition(uint8_t n);
	void tickCalibrate(uint8_t n, uint16_t initial_magnification_min, uint16_t initial_magnification_max);
	void potCalibrate(uint8_t n);
	void potCalibrate(uint8_t n, uint8_t point1_in_deg, uint8_t point2_in_deg);
	
	inline void pulse_start_handler()		__attribute__((always_inline));
	inline void pulse_continue_handler()	__attribute__((always_inline));
};


#define TMPL	template<uint8_t servo_count, Servo (&servo)[servo_count], class T, T &adc>
#define S_C		ServoControl<servo_count, servo, T, adc>


TMPL S_C::ServoControl() : servo_idx(0)
{
	for(uint8_t i = 0; i < servo_count; i++)
		servo_sorted[i] = &servo[i];
}

TMPL void			 S_C::set(uint16_t my_new_data[])
{
	data_can_be_changed = true;
	memcpy(new_data, my_new_data, sizeof(new_data));  // new_data = my_new_data;
}
TMPL uint16_t*		 S_C::set()
{
	data_can_be_changed = true;
	return new_data;
}
TMPL const uint16_t* S_C::get()
{
	return new_data;
}


TMPL void S_C::update()
{
	if(adc.isConversionsFinished())
	{
		for(uint8_t i = 0; i < servo_count; i++)
			servo[i].pot = adc.getResult()[i];
	}
}

TMPL uint16_t S_C::mapValue(int32_t x, int32_t in_min, int32_t in_max, int32_t out_min, int32_t out_max)
{
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}


TMPL void S_C::toCurrentPosition(uint8_t n)
{
	data_can_be_changed = true; // ?
	new_data[n] = servo[n].pot2Tick();
}

TMPL void S_C::tickCalibrate(uint8_t n, uint16_t initial_magnification_min, uint16_t initial_magnification_max)
{
	enum {t_min, t_max};
	uint16_t pot_old = 0xffff;
	uint16_t new_tick[2] = {initial_magnification_min, initial_magnification_max};
	uint8_t epsilon = 3;
	uint8_t tick_step;
	// find minimum(first iteration) and maximum(seconf iteration) tick value
	for(int8_t i = t_min, sign = -1;   i <= t_max;   i++, sign = +1)
	{
		DEBUG_PRINTF(" --- step %d --- \n", i);

		// move to initial magnification
		set()[n] = new_tick[i];
		_delay_ms(2000);
		
		tick_step = 40;
		do // move towards the limit
		{
			pot_old = servo[n].pot;
			new_tick[i] += sign*tick_step;
			set()[n] = new_tick[i];
			_delay_ms(30);
			_MemoryBarrier();
			update();

			DEBUG_PRINTF("1\t%d\t%d\t%d\n", pot_old, servo[n].pot, new_tick[i]);
			for(uint8_t j = 0; j < 5 && abs(servo[n].pot - pot_old) <= epsilon; j++)
			{
				_delay_ms(30);
				update();
				DEBUG_PRINTF("1\t%d\t%d\t%d\n", pot_old, servo[n].pot, new_tick[i]);
			}
		} while(abs(servo[n].pot - pot_old) > epsilon);
		// we are crossed the limit on some small value
		DEBUG_PRINTF("\n\n\n");

		tick_step = 1;
		pot_old = servo[n].pot;
		do // and slowly move back
		{
			new_tick[i] -= sign*tick_step;
			set()[n] = new_tick[i];
			_delay_ms(30);
			update();

			DEBUG_PRINTF("2\t%d\t%d\t%d\n", pot_old, servo[n].pot, new_tick[i]);
		} while(abs(servo[n].pot - pot_old) < epsilon); // until potentiometer value begins to change
		DEBUG_PRINTF("\n\n\n");
		new_tick[i] += sign*tick_step;
	}
	
	servo[n].tick_min = new_tick[t_min];
	servo[n].tick_max = new_tick[t_max];
	printf("%d\t%d\n", new_tick[t_min], new_tick[t_max]);
}
TMPL void S_C::potCalibrate(uint8_t n)
{
	uint16_t saved_pos = servo[n].tick;
	
	// move to point 1
	set()[n] = servo[n].tick_min;
	_delay_ms(2000);
	update();
	servo[n].pot_min = servo[n].pot;
	
	// move to point 2
	set()[n] = servo[n].tick_max;
	_delay_ms(2000);
	update();
	servo[n].pot_max = servo[n].pot;
	
	// return to saved point
	set()[n] = saved_pos;
}
TMPL void S_C::potCalibrate(uint8_t n, uint8_t point1_in_deg, uint8_t point2_in_deg)
{
	uint16_t saved_pos = servo[n].tick;
	uint16_t tick[2] = {servo[n].deg2Tick(point1_in_deg), servo[n].deg2Tick(point2_in_deg)};
	uint16_t pot[2];
	
	// move to point 1
	set()[n] = tick[0];
	_delay_ms(2000);
	update();
	pot[0] = servo[n].pot;
	
	// move to point 2
	set()[n] = tick[1];
	_delay_ms(2000);
	update();
	pot[1] = servo[n].pot;
	
	// return to saved point
	set()[n] = saved_pos;
	
	// extrapolate pot_min and pot_max
	servo[n].pot_min = mapValue(servo[n].tick_min, tick[0], tick[1], pot[0], pot[1]);
	servo[n].pot_max = mapValue(servo[n].tick_max, tick[0], tick[1], pot[0], pot[1]);
}


TMPL inline void S_C::pulse_start_handler()
{
	if(data_can_be_changed)
	{
		for(uint8_t i = 0; i < servo_count; i++)
			servo[i].tick = new_data[i];
		
		//static_sort(servo_sorted);
		pregenerated_sort(servo_sorted);
		
		data_can_be_changed = false;
	}
	
	for(uint8_t i = 0; i < servo_count; i++)
		if(servo_sorted[i]->tick != Servo::disabled)
			servo_sorted[i]->port_reg |= servo_sorted[i]->pin_bitmap; // 1 на выводы задействованных серв
		else
			break;
			//servo[i].port &= ~ servo[i].pin_bitmap; // 0 на выводы отключённых серв
	
	OCR1B = servo_sorted[0]->tick;
	servo_idx = 0;
}
TMPL inline void S_C::pulse_continue_handler() // TIMER1_COMPA_vect
{
	// remember that OCF1B in TIFR1 is reset immediately after entering to ISR
	
	// set 0 to the current servo pin ( assume that pin is set to 1 in pulse_start_handler() )
	pinFromPort(servo_sorted[servo_idx]->port_reg) = servo_sorted[servo_idx]->pin_bitmap; // toggle pin by PINx register
	servo_idx++;
	
	const uint8_t timer_threshold = 10;
	// if you already must set 0 to the next servo and if you want to avoid missing interrupt
	while(	servo_idx < servo_count &&
			servo_sorted[servo_idx]->tick < TCNT1 + timer_threshold )
	{
		// set 0 to the next servo pin
		pinFromPort(servo_sorted[servo_idx]->port_reg) = servo_sorted[servo_idx]->pin_bitmap; // toggle pin by PINx register
		servo_idx++;
	}
	if(servo_idx < servo_count)
		OCR1B = servo_sorted[servo_idx]->tick;
}



#undef TMPL
#undef S_C


#undef DEBUG_PRINTF


#endif /* SERVO_CONTROLLER_H_ */