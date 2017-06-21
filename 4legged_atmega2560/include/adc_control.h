#ifndef ADC_CONTROLLER_H_
#define ADC_CONTROLLER_H_

#include <stdint.h>			// uint8_t, uint16_t
#include <avr/io.h>			// avr/iom2560.h - ADC register


template<uint8_t channel_count>
class AdcControl
{
private:
	uint8_t channel_i;
	uint16_t result[channel_count];

	
	volatile bool completed;
	// uint8_t	channel_count - remember about template parameter
	
public:
	AdcControl();
	
	bool isConversionsFinished();
	const uint16_t* getResult();
	
	inline void adcStart()	__attribute__((always_inline));
	inline void adcStop()	__attribute__((always_inline));
	
	inline void selectChannel(uint8_t channel)	__attribute__((always_inline));
	inline void startSeries()					__attribute__((always_inline));
	
	inline void complete_handler()				__attribute__((always_inline));
};


#define TMPL	template<uint8_t channel_count>
#define A_C		AdcControl<channel_count>

TMPL A_C::AdcControl() : channel_i(0), completed(false)
{
	ADMUX =		( 0 << REFS1 ) |  // ...
				( 1 << REFS0 ) |  // RESF10 = 01, AVCC with external capacitor at AREF pin
				( 0 << ADLAR ) |  // ADC result is right adjusted to get all 10 bits of ADCL(ADC0-7) and ADCH(ADC8-9)
				( 0 << MUX4  ) |  // ...
				( 0 << MUX3  ) |  // ...
				( 0 << MUX2  ) |  // ...
				( 0 << MUX1  ) |  // ...
				( 0 << MUX0  );   // MUX5..0 = 0000, select ADC0 on pin 23

	ADCSRB =	( 0 << ACME  ) |  // it refers to Analog Comparator
				( 0 << MUX5  ) |  // see above MUX4..0 
				( 0 << ADTS2 ) |  // ...
				( 0 << ADTS1 ) |  // ...
				( 0 << ADTS0 );   // ADTS2..0 = 000, Trigger Source(if ADATE) = Free Running mode

	ADCSRA =	( 1 << ADEN  ) |  // ADC enable
				( 0 << ADSC  ) |  // don't start conversion
				( 0 << ADATE ) |  // ADC auto trigger disabled
				( 0 << ADIF  ) |  // there's ADC interrupt flag
				( 1 << ADIE  ) |  // ADC interrupt enabled ( == permitted )
				( 1 << ADPS2 ) |  // ...
				( 1 << ADPS1 ) |  // ...
				( 1 << ADPS0 );   // ADPS2..0 = 111, division factor = 128
	DIDR0 = 0;
}

TMPL bool A_C::isConversionsFinished()
{
	bool tmp = completed;
	completed = false;
	return tmp;
}
TMPL const uint16_t* A_C::getResult()
{
	return result;
}

TMPL inline void A_C::adcStart()
{
	ADCSRA |= 1 << ADSC; // ADC start
}
TMPL inline void A_C::adcStop()
{
	if( ADCSRA & (1 << ADSC) )  // if conversion is in progress
	{
		ADCSRA &= ~(1 << ADEN); // ADC turn off to terminate old conversion
		ADCSRA |=  (1 << ADEN); // ADC turn on
	}
}

TMPL inline void A_C::selectChannel(uint8_t channel)
{
	if(channel > 7) // ATmega2560 datasheet, 26. ADC. Table 26-4.
		channel <<= 2;
	ADMUX = (ADMUX	 & ((1<<REFS1)| (1<<REFS0)| (1<<ADLAR )))  |						// ADMUX   & 0b11100000
			(channel & ((1<<MUX3) | (1<<MUX2) | (1<<MUX2) | (1<<MUX1) | (1<<MUX0)));	// channel & 0b00001111
}
TMPL inline void A_C::startSeries()
{
	adcStop();	
	channel_i = 0;
	selectChannel(0);
	adcStart();
}

TMPL inline void A_C::complete_handler()
{
	result[channel_i++] = ADC;
	if(channel_i < channel_count)
	{
		selectChannel(channel_i);
		adcStart();
	}
	else
	{
		completed = true;
		adcStop();
	}
}



#undef TMPL
#undef A_C

#endif /* ADC_CONTROLLER_H_ */