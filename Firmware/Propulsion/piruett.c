#define F_CPU 16000000UL \
 \

#define ON 1
#define OFF 0
#define SET 1
#define CLEAR 0 \

/*1:*/
#line 44 "./piruett.w"

/*4:*/
#line 60 "./piruett.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <stdlib.h> 
# include <stdint.h> 

/*:4*/
#line 45 "./piruett.w"

/*5:*/
#line 70 "./piruett.w"

typedef struct{
uint8_t wavecount;
uint16_t armwait;
uint8_t armed;
const uint8_t nowavecount;
}statestruct;


/*:5*/
#line 46 "./piruett.w"

/*6:*/
#line 79 "./piruett.w"

void ledcntl(uint8_t state);

/*:6*/
#line 47 "./piruett.w"



/*:1*//*7:*/
#line 84 "./piruett.w"


int main(void)
{

/*11:*/
#line 112 "./piruett.w"

{

DDRB|= (1<<DDB5);
}/*:11*/
#line 89 "./piruett.w"


ledcntl(OFF);


return 0;

}

/*:7*//*8:*/
#line 100 "./piruett.w"

void ledcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}

/*:8*/
