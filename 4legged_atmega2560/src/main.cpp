
#include "servo_control.h"
#include <stdint.h>			// uint8_t, uint16_t
#include <stdio.h>			// printf()
#include <avr/io.h>			// avr/iom2560.h
#include <avr/wdt.h>		// watchdog
#include <avr/interrupt.h>	// cli(), sei()
#include <avr/pgmspace.h>	// PROGMEM, ...
#include <util/delay.h>		// _delay_ms()

volatile bool update_flag = false;

#define MPU6050_DMP_FIFO_RATE_DIVISOR		FIFO_RATE_50HZ

#include "touch_sensor.h"
#include "servo.h"
#include "adc_control.h"
#include "I2Cdev.h"
#include "MPU6050_6Axis_MotionApps20.h"
#include "input_parser.h"
#include "uart_stdio_wrapper.h"
extern "C"
{
	#include "uart.h"
}




#ifdef DEBUG
#define DEBUG_BEGIN()							uart_init( UART_BAUD_SELECT(250000, F_CPU) )
#define DEBUG_PRINT(X)							uart_puts(X)
#define DEBUG_PRINTF(...)						printf(##__VA_ARGS__)
#define DEBUG_PRINTF_P(flash_format_str, ...)	printf_P(PSTR(flash_format_str), ##__VA_ARGS__)
#define DEBUG_PRINTF_STR(...)										\
do{																	\
	snprintf(Uart::send_buffer, Uart::buffer_size,##__VA_ARGS__);	\
	uart_puts(Uart::send_buffer);									\
} while(0)
#define DEBUG_PRINTF_STR_P(flash_format_str, ...)					\
do{ 																\
	snprintf_P(Uart::send_buffer, Uart::buffer_size,				\
				PSTR(flash_format_str),##__VA_ARGS__);				\
	uart_puts(Uart::send_buffer);  									\
} while(0)
#define DEBUG_PRINT_P(X)		uart_puts_P(X)
#else
#define DEBUG_BEGIN(X)
#define DEBUG_PRINT(X)
#define DEBUG_PRINTF(...)
#define DEBUG_PRINTF_P(...)
#define DEBUG_PRINTF_STR(...)
#define DEBUG_PRINTF_STR_P(...)
#define DEBUG_PRINT_P(X)
#endif




void initPorts();
void initTimer1();
void initTimer2();
void initADC();




// class default I2C address is 0x68
MPU6050 mpu;








const uint8_t leg_count = 1;
TouchSensor leg_sensor[leg_count]
{//	pin_reg		pin_bitmap
	{PIND,		1<<PIND7}	// it's 7 arduino uno pin
};
TouchSensorControl<leg_count, leg_sensor> leg_sensor_controller;

const uint8_t battery_count = 2;

const uint8_t servo_count = 2;
Servo servos[servo_count]
{//	deg_range	port_reg	pin_bitmap	tick_min	tick_max	pot_min	pot_max
	{120,		PORTB,		1<<PB0,		1600,		4380,		147,	767 },	// it's 53 arduino mega pin (and ADC pin A0)
	{120,		PORTB,		1<<PB1,		1400,		5200,		300,	1000}	// it's 52 arduino mega pin (and ADC pin A1)
};

AdcControl<servo_count> adc_controller;
using AdcT = decltype(adc_controller); // as typedef

ServoControl<servo_count, servos, AdcT, adc_controller> servo_controller;
using ServoT = decltype(servo_controller);

Input<ServoT, servo_controller> input;




// MPU control/status vars
uint8_t fifoBuffer[42]; // FIFO storage buffer

// orientation/motion vars
Quaternion q;           // [w, x, y, z]         quaternion container
VectorInt16 aa;         // [x, y, z]            accel sensor measurements
VectorInt16 aaReal;     // [x, y, z]            gravity-free accel sensor measurements
VectorInt16 aaWorld;    // [x, y, z]            world-frame accel sensor measurements
VectorFloat gravity;    // [x, y, z]            gravity vector
float ypr[3];           // [yaw, pitch, roll]   yaw/pitch/roll container and gravity vector

bool send_serial_packet_flag;

uint8_t mpuInit(MPU6050 &m, int16_t x_a_offset,	int16_t y_a_offset,	int16_t z_a_offset,
							int16_t x_g_offset,	int16_t y_g_offset, int16_t z_g_offset);
void mpuProcess(MPU6050&);
void initExternalInterrupts();

class Output
{
	// structure:
	// servo position:				[float degrees]	from [uint16_t adc_value]	x12
	// battery voltage:				[float volts]	from [uint16_t adc_value]	x2
	// ground contact:				[bool]										x4
	// angles:						[Quaternion] which is [float x4]			x1
	// real accel in global CS:		[VectorFloat] which is [float x3]			x1
	// gravity vector:				[VectorFloat] which is [float x3]			x1
	
	// we need definitely known packet size for binary protocol and we can use packing for this.
	// __attribute__ ((packed)) gives warning about impossibility of packing non-POD VectorFloat and Quaternion.
	// #pragma pack doesn't. (but i don't know if it works or not)
	// in general, it does not matter, as long as we use 8 bit uC...
	struct SerialPacket
	{
		float servo_position[servo_count];
		float battery_voltage[battery_count];
		bool ground_contact[leg_count];
		Quaternion orientation;
		VectorFloat acceleration;
		VectorFloat gravity;
	} packet;
	public:
	Output();
	
	void updateValues();

	void sendAsText();
	void sendAsBinary();
	void sendAsBinaryOverText();
};



ISR(ADC_vect) // 50 Hz, 18 kHz
{
	adc_controller.complete_handler();
}
ISR(TIMER1_COMPA_vect) // up to 2 MHz?
{
	servo_controller.pulse_start_handler();
	adc_controller.startSeries();
	//TouchSensorControl::poll();
}
ISR(TIMER1_COMPB_vect) // 50 Hz
{
	servo_controller.pulse_continue_handler();
}
ISR(TIMER2_COMPA_vect) // user defined frequncy
{
	update_flag = true; // to debug
}
volatile bool mpu_interrupt_flag = false;
ISR(INT2_vect) // 50 Hz
{// DMP_INT and FIFO_OFLOW_INT interrupts from INT_ENABLE register (Register Map Register 58, but DMP_INT isn't specified in rev4.2)
	mpu_interrupt_flag = true;
}

int main(void)
{
	adc_controller.startSeries();

	fdev_setup_stream(&Uart::stream, Uart::putChar, Uart::getChar, _FDEV_SETUP_RW);
	stdin = stdout = &Uart::stream;
	DEBUG_BEGIN();
	
	initPorts();
	initTimer1();
	initTimer2();
	
	initExternalInterrupts(); // INT pin of MPU6050
	
	sei();
	
	uint8_t error_status = mpuInit(mpu,	-1012, -227, +352,		// accel offsets
										+340/4, -113/4, +31/4);	// gyro offsets
	if(error_status)
	{
		DEBUG_PRINT_P("MPU6050 programming failed\n");
		for(;;);
	}
	
	
	for(;;)
	{
		if(uart_string_available())
		{
			input.parse();
			send_serial_packet_flag = true;
		}
		
		if(send_serial_packet_flag)
		{
			Output x;
			x.sendAsText();
			send_serial_packet_flag = false;
		}
		
		if(update_flag)
		{
			servo_controller.update();
			update_flag = false;
		}
		if(mpu_interrupt_flag)
		{
			mpu_interrupt_flag = false;
			mpuProcess(mpu);
		}
	}
}

// ADC initialized in AdcControl constructor
// servo PWM pins initialized in Servo constructor
// leg touch sensor pins initialized in TouchSensor constructor
void initPorts()
{
	
}
void initTimer1() // to servo control
{
	OCR1A = 39999;  // TOP = OCR1A
	OCR1B = 0xffff; // initial OCR1B > OCR1A because "overflow" ISR(it's Compare A Match) must be called first

	// I/O pins are disconnected from timer. COM1A/B/C0..1 = 0 in TCCR1A
	TCCR1A =	( 0 << WGM11  ) |	// ...
				( 0 << WGM10  );	// ...
	TCCR1B =	( 0 << WGM13  ) |	// WGM13..10 = 0100, CTC Mode, TOP = OCR1A, 
				( 1 << WGM12  ) |	// OCR1x updates immediately, TOV1 set on MAX = 0xffff = never
				( 0 << CS12   ) |	// ...
				( 1 << CS11   ) |	// ...
				( 0 << CS10   );	// CS12..10 = 010, clk/8
	TCCR1C = 0;
	TIMSK1 =	( 1 << OCIE1B ) |	// Output Compare B Match interrupt enabled
				( 1 << OCIE1A ) |	// Output Compare A Match interrupt enabled
				( 0 << TOIE1  );	// Overflow interrupt disabled
}
void initTimer2() // to debug (unused)
{
	OCR2A = 0x80; // some user-defined value
	
	// I/O pins are disconnected from timer. COM2A/B0..1 = 0 in TCCR1A
	TCCR2A =	( 1 << WGM21  ) |	// ...
				( 0 << WGM20  );	// ...
	TCCR2B =	( 0 << WGM22  ) |	// WGM22...20 = 010, CTC Mode, TOP = 0xOCRA
				( 1 << CS22   ) |	// ...
				( 1 << CS21   ) |	// ...
				( 1 << CS20   );	// CS22..20 = 111, clk/1024
	TIMSK2 =	( 1 << OCIE2A ) |	// Compare Match A interrupt enabled
				( 0 << OCIE2B ) |	// Compare Match B interrupt disabled
				( 0 << TOIE2  );	// Overflow interrupt disabled
}
void initExternalInterrupts() // to INT pin of MPU6050
{
	EICRA = ( 1 << ISC21 ) |	// ...
			( 1 << ISC20 );		// The rising edge of INT2 generates an interrupt request
	EIMSK =   1 << INT2;		// External Interrupt Request 0 Enable
}



uint8_t mpuInit(MPU6050 &m, int16_t x_a_offset,	int16_t y_a_offset,	int16_t z_a_offset,	
							int16_t x_g_offset,	int16_t y_g_offset, int16_t z_g_offset) // must be called after sei()
{
	Fastwire::setup(400, true);

	// initialize device
	DEBUG_PRINT("Initializing I2C devices...\n");
	m.initialize();

	// verify connection
	DEBUG_PRINT("Testing device connections...\n");
	if(m.testConnection())
		DEBUG_PRINT("MPU6050 connection successful\n");
	else
		DEBUG_PRINT("MPU6050 connection failed\n");
	

	


	// load and configure the DMP
	DEBUG_PRINT("Initializing DMP...\n");
	uint8_t dmp_status = m.dmpInitialize();


	//offsets
	m.setXAccelOffset(x_a_offset);
	m.setYAccelOffset(y_a_offset);
	m.setZAccelOffset(z_a_offset);
	m.setXGyroOffset(x_g_offset);
	m.setYGyroOffset(y_g_offset);
	m.setZGyroOffset(z_g_offset);

	// make sure it worked (returns 0 if so)
	if (dmp_status == 0)
	{
		// turn on the DMP, now that it's ready
		DEBUG_PRINT("Enabling DMP...\n");
		mpu.setDMPEnabled(true);

		// enable Arduino interrupt detection
		DEBUG_PRINT("Enabling interrupt detection (Arduino external interrupt 0)...\n");
		//mpuIntStatus = mpu.getIntStatus();
		
		// set our DMP Ready flag so the main loop() function knows it's okay to use it
		DEBUG_PRINT("DMP ready! Waiting for first interrupt...\n");
		} else {
		// ERROR!
		// 1 = initial memory load failed
		// 2 = DMP configuration updates failed
		// (if it's going to break, usually the code will be 1)
		DEBUG_PRINTF_P("DMP Initialization failed (code %d)\n",dmp_status);
	}

	DEBUG_PRINTF_P("SMPLRT_DIV = %d\n", mpu.getRate());
	return dmp_status;
}
void mpuProcess(MPU6050 &m)
{
	uint8_t mpu_int_status = m.getIntStatus();
	
	if(mpu_int_status & (1 << MPU6050_INTERRUPT_FIFO_OFLOW_BIT))
	// || fifoCount >= MPU6050_FIFO_SIZE // unnecessary check?
	// || fifoCount % mpu.dmpPacketSize != 0 // - if something strange happened
	{
		m.resetFIFO();
		return;
	}
	else if(mpu_int_status & (1 << MPU6050_INTERRUPT_DMP_INT_BIT))
	{
		m.getFIFOBytes(fifoBuffer, m.dmpPacketSize);
		m.resetFIFO();
	}
	
	#ifdef OUTPUT_READABLE_QUATERNION
	// display quaternion values in easy matrix form: w x y z
	m.dmpGetQuaternion(&q, fifoBuffer);
	PRINTF("quat\t");
	PRINTF(q.w);
	PRINTF("\t");
	PRINTF(q.x);
	PRINTF("\t");
	PRINTF(q.y);
	PRINTF("\t");
	PRINTFLN(q.z);
	#endif

	#ifdef OUTPUT_READABLE_EULER
	// display Euler angles in degrees
	mpu.dmpGetQuaternion(&q, fifoBuffer);
	mpu.dmpGetEuler(euler, &q);
	PRINTF("euler\t");
	PRINTF("%f",euler[0] * 180/M_PI);
	PRINTF("\t");
	PRINTF("%f",euler[1] * 180/M_PI);
	PRINTF("\t");
	PRINTFLN("%f",euler[2] * 180/M_PI);
	#endif

	#ifdef OUTPUT_READABLE_YAWPITCHROLL
	// display Euler angles in degrees
	mpu.dmpGetQuaternion(&q, fifoBuffer);
	mpu.dmpGetGravity(&gravity, &q);
	mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);
	DEBUG_PRINTF_P("ypr\t%f\t%f\t%f\n",ypr[0] * 180/M_PI,ypr[1] * 180/M_PI,ypr[2] * 180/M_PI);
	#endif

	#ifdef OUTPUT_READABLE_REALACCEL
	// display real acceleration, adjusted to remove gravity
	mpu.dmpGetQuaternion(&q, fifoBuffer);
	mpu.dmpGetAccel(&aa, fifoBuffer);
	mpu.dmpGetGravity(&gravity, &q);
	mpu.dmpGetLinearAccel(&aaReal, &aa, &gravity);
	//PRINTF("areal\t");
	//PRINTF("%d",aaReal.x);
	//PRINTF("\t");
	//PRINTF("%d",aaReal.y);
	//PRINTF("\t");
	//PRINTFLN("%d",aaReal.z);
	DEBUG_PRINTF_P("a\t%d\t%d\t%d\n",aa.x,aa.y,aa.z);
	#endif

	#ifdef OUTPUT_READABLE_WORLDACCEL
	// display initial world-frame acceleration, adjusted to remove gravity
	// and rotated based on known orientation from quaternion
	mpu.dmpGetQuaternion(&q, fifoBuffer);
	mpu.dmpGetAccel(&aa, fifoBuffer);
	mpu.dmpGetGravity(&gravity, &q);
	mpu.dmpGetLinearAccel(&aaReal, &aa, &gravity);
	mpu.dmpGetLinearAccelInWorld(&aaWorld, &aaReal, &q);
	PRINTF("aworld\t");
	PRINTF("%d",aaWorld.x);
	PRINTF("\t");
	PRINTF("%d",aaWorld.y);
	PRINTF("\t");
	PRINTFLN("%d",aaWorld.z);
	#endif	
}



		
Output::Output()
{
	updateValues();
}

void Output::updateValues()
{
	//float servo_position[servo_count];
	for(uint8_t i = 0; i < servo_count; i++)
		packet.servo_position[i] = servos[i].pot2Deg();
	
	//float battery_voltage[battery_count];
	for(uint8_t i = 0; i < battery_count; i++)
		packet.battery_voltage[i] = 0;
	
	//bool ground_contact[leg_count];
	for(uint8_t i = 0; i < leg_count; i++)
		packet.ground_contact[i] = leg_sensor_controller.getState(i);
	
	//Quaternion orientation;
	mpu.dmpGetQuaternion(&packet.orientation, fifoBuffer);
	
	//VectorFloat gravity;
	mpu.dmpGetGravity(&packet.gravity, &packet.orientation);
	
	//VectorFloat acceleration;
	VectorInt16 tmp_a;
	VectorInt16 tmp_a_real;
	mpu.dmpGetAccel(&tmp_a, fifoBuffer);
	mpu.dmpGetLinearAccel(&tmp_a_real, &tmp_a, &gravity);
	mpu.dmpGetLinearAccelInWorld(&tmp_a_real, &aaReal, &packet.orientation);
	packet.acceleration = VectorFloat(tmp_a_real.x / 8192.0f, tmp_a_real.y / 8192.0f, tmp_a_real.z / 8192.0f);
}

void Output::sendAsText()
{
	for(uint8_t i = 0; i < servo_count; i++)
	printf_P(PSTR("%f\t"), packet.servo_position[i]);
	
	for(uint8_t i = 0; i < battery_count; i++)
	printf_P(PSTR("%f\t"), packet.battery_voltage[i]);
	
	for(uint8_t i = 0; i < leg_count; i++)
	printf_P(packet.ground_contact[i] ? PSTR("1\t") :  PSTR("0\t"));
	
	printf_P(PSTR("%f\t%f\t%f\t%f\t"),	packet.orientation.w,
	packet.orientation.x,
	packet.orientation.y,
	packet.orientation.z);
	
	printf_P(PSTR("%f\t%f\t%f\t"),		packet.acceleration.x,
	packet.acceleration.y,
	packet.acceleration.z);
	
	printf_P(PSTR("%f\t%f\t%f\n"),		packet.gravity.x,
	packet.gravity.y,
	packet.gravity.z);
}
void Output::sendAsBinary()
{
	for(uint8_t i = 0; i < sizeof(SerialPacket); i++)
	uart_putc(*((uint8_t*)&packet+i));
}
void Output::sendAsBinaryOverText()
{
	for(uint8_t i = 0; i < sizeof(SerialPacket); i++)
	printf_P(PSTR("%0hhx"),*((uint8_t*)&packet+i));
	uart_putc('\n');
}
