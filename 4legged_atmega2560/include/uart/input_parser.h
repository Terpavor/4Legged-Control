#ifndef INPUT_PARSER_H_
#define INPUT_PARSER_H_

#include <stdlib.h>			// strtoul()
#include <stdint.h>			// uint8_t, uint16_t
#include <ctype.h>			// isdigit(), isspace()

#include "uart_stdio_wrapper.h"


enum State
{
	initial_state,
	servo_num_label_state,
	servo_val_label_state,
	got_servo_num_state,
	final_state,
	error_state
};
enum Signal
{
	servo_num_label_signal,
	servo_val_label_signal,
	num_signal,
	blank_signal,
	end_signal,
	error_signal
};

template
<
	class T,		// servo controller type (ServoControl<servo_count, servos, AdcT, adc_controller>)
	T &controller	// reference to ADC controller
>
class Input
{
	static constexpr char * const buffer = Uart::receive_buffer;
	static constexpr uint8_t buffer_size = Uart::buffer_size;
	uint8_t start_i, end_i;
	char *start_ptr, *end_ptr;
	uint8_t servo_number;
	// uint16_t servo_value;
	float servo_value;
	
	State initial_state_Callback(Signal current_signal);
	State servo_num_label_state_Callback(Signal current_signal);
	State got_servo_num_state_Callback(Signal current_signal);
	State servo_val_label_state_Callback(Signal current_signal);

	using FsmFunPtr = State(Input::*)(Signal);
	FsmFunPtr stateFcn[4];
	
	Signal getSignal(char x);
public:
	Input();
	
	void parse();
};


#define TMPL	template<class T, T &controller>
#define IN		Input<T, controller>


TMPL IN::Input()
: stateFcn
{
	&Input::initial_state_Callback,
	&Input::servo_num_label_state_Callback,
	&Input::servo_val_label_state_Callback,
	&Input::got_servo_num_state_Callback
}
{}

TMPL State IN::initial_state_Callback(Signal current_signal)
{
	const State current_state = initial_state;

	switch (current_signal) {
		case servo_num_label_signal: {
			//start_i++; !
			start_ptr++;
			}return servo_num_label_state;

		case blank_signal: {
			//start_i++; ! 
			start_ptr++;
			}return current_state;

		case end_signal:
			return final_state;

		default:
			return error_state;
	}
}
TMPL State IN::servo_num_label_state_Callback(Signal current_signal)
{
	const State current_state = servo_num_label_state;

	switch (current_signal) {
		case num_signal: {

			//end_i = start_i; ! 
			//while (isdigit(buffer[++end_i])); ! 

			//char next_char = buffer[end_i];! 
			//buffer[end_i] = '\0'; !
			servo_number = strtoul(start_ptr, &start_ptr, 10);
			//buffer[end_i] = next_char; !

			//start_i = end_i; !

			if(servo_number >= controller.getServoCount())
				return error_state;
			}return got_servo_num_state;

		case blank_signal: {
			//start_i++; !
			start_ptr++;
			}return current_state;

		default:
			return error_state; //error!
	}
}
TMPL State IN::got_servo_num_state_Callback(Signal current_signal)
{
	const State current_state = got_servo_num_state;

	switch (current_signal) {
		case servo_val_label_signal: {
			//start_i++; !
			start_ptr++;
			}return servo_val_label_state;

		case blank_signal: {
			//start_i++; ! 
			start_ptr++;
			}return current_state;

		default:
			return error_state; //error!
	}
}
TMPL State IN::servo_val_label_state_Callback(Signal current_signal)
{
	const State current_state = servo_val_label_state;

	switch (current_signal) {
		case num_signal: {

			//end_i = start_i;
			//while (isdigit(buffer[++end_i]));

			//char next_char = buffer[end_i];
			//buffer[end_i] = '\0';
			//servo_value = strtoul(&buffer[start_i], NULL, 10);
			// remember that float==double==32bit in avr-gcc and strtof isn't defined in avr-libc
			servo_value = strtod(start_ptr, &start_ptr);
			//buffer[end_i] = next_char;

			//start_i = end_i;
			
			// assign
			controller.set()[servo_number] = controller.getServo()[servo_number].deg2Tick(servo_value);
			
			}return initial_state;

		case blank_signal: {
			//start_i++; !
			start_ptr++;
			}return current_state;

		default:
			return error_state; //error!
	}
}

TMPL Signal IN::getSignal(char x)
{
	if (isdigit(x) || x=='+' || x=='-' || x=='.')
		return num_signal;
	if (x == 's')
		return servo_num_label_signal;
	if (x == 'v')
		return servo_val_label_signal;
	if (isspace(x))
		return blank_signal;
	if (x == '\0')
		return end_signal;
	return error_signal;
}
TMPL void IN::parse()
{
	bool no_error = Uart::getStr();
	if (!no_error)
		return;

	//start_i = 0; !
	start_ptr = buffer;
	
	State current_state = initial_state;
	while (current_state != final_state && current_state != error_state)
	{
		Signal current_signal = getSignal(buffer[start_i]);
		current_state = (this->*stateFcn[current_state])(current_signal);
		// It would be "... = stateFcn[current_state](current_signal)" if it were not a member of the class
	}
}


#undef TMPL
#undef IN


#endif /* INPUT_PARSER_H_ */