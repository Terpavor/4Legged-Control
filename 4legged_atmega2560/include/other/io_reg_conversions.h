/*
 * pin_and_ddr_from_port.h
 *
 * Created: 01.05.2017 9:32:05
 *  Author: User
 */ 


#ifndef IO_REG_CONVERSIONS_H_
#define IO_REG_CONVERSIONS_H_

inline volatile uint8_t&  ddrFromPin(volatile uint8_t&);
inline volatile uint8_t& portFromPin(volatile uint8_t&);

inline volatile uint8_t&  pinFromDdr(volatile uint8_t&);
inline volatile uint8_t& portFromDdr(volatile uint8_t&);

inline volatile uint8_t& pinFromPort(volatile uint8_t&);
inline volatile uint8_t& ddrFromPort(volatile uint8_t&);

inline volatile uint8_t&  ddrFromPin(volatile uint8_t& pin)		{	return *(volatile uint8_t *)(&pin + 0x01);	}
inline volatile uint8_t& portFromPin(volatile uint8_t& pin)		{	return *(volatile uint8_t *)(&pin + 0x02);	}

inline volatile uint8_t&  pinFromDdr(volatile uint8_t& ddr)		{	return *(volatile uint8_t *)(&ddr - 0x01);	}
inline volatile uint8_t& portFromDdr(volatile uint8_t& ddr)		{	return *(volatile uint8_t *)(&ddr + 0x01);	}

inline volatile uint8_t& pinFromPort(volatile uint8_t& port)	{	return *(volatile uint8_t *)(&port - 0x02);	}
inline volatile uint8_t& ddrFromPort(volatile uint8_t& port)	{	return *(volatile uint8_t *)(&port - 0x01);	}

//static_assert(	&PORTB-0x01 == &DDRB &&
				//	&PORTC-0x01 == &DDRC &&
				//	&PORTD-0x01 == &DDRD, "pinFromPort doesn't work with this microcontroller");

#endif /* IO_REG_CONVERSIONS_H_ */