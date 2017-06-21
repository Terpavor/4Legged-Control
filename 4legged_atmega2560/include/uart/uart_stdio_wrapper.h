#ifndef UART_STDIO_WRAPPER_H_
#define UART_STDIO_WRAPPER_H_

#include <stdio.h>			// FILE

extern "C"
{
	#include "uart.h"
}

namespace Uart
{
	const uint8_t	buffer_size = 32;
	uint16_t		character;
	char			send_buffer[buffer_size];
	char			receive_buffer[buffer_size];

	FILE stream;

	int putChar(char, FILE *);
	int getChar(FILE *);
	
	bool getStr();
};
int Uart::putChar(char c, FILE *stream)
{
	uart_putc(c);
	return 0; // because uart_putc declared as void
}
int Uart::getChar(FILE *stream)
{
	uint16_t tmp = uart_getc();
	return tmp == UART_NO_DATA ? EOF : tmp;
}
	
bool Uart::getStr()
{
	uint16_t character_and_error_code;
	uint8_t	i;
	for(i = 0; i < buffer_size; i++)
	{
		character_and_error_code = uart_getc();

		if(character_and_error_code == UART_NO_DATA)
		return false;

		char character = (char)character_and_error_code;
		if(character == '\n')
		{
			receive_buffer[i] = '\0';
			return true;
		}

		receive_buffer[i] = character;
	}
	return false;
}



#endif /* UART_STDIO_WRAPPER_H_ */