#define F_CPU 16000000UL
#define BAUD 9600 \

#define ON 1
#define OFF 0
#define SET 1
#define CLEAR 0
#define CH1RISE 0
#define CH1FALL 1
#define CH2FALL 2 \
 \

/*2:*/
#line 100 "./piruett.w"

/*5:*/
#line 120 "./piruett.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <stdlib.h> 
# include <stdint.h> 

/*:5*/
#line 101 "./piruett.w"

/*6:*/
#line 131 "./piruett.w"

typedef struct{
uint8_t portOut;
uint8_t starboardOut;
uint16_t thrust;
uint16_t radius;
uint8_t failSafe;
}outputStruct;


/*:6*//*7:*/
#line 144 "./piruett.w"

typedef struct{
uint16_t ch1rise;
uint16_t ch1fall;
uint16_t ch2fall;
uint16_t ch1duration;
uint16_t ch2duration;
uint8_t edge;
}inputStruct;


/*:7*/
#line 102 "./piruett.w"

/*8:*/
#line 155 "./piruett.w"

void ledcntl(uint8_t state);

/*:8*/
#line 103 "./piruett.w"



/*:2*//*10:*/
#line 166 "./piruett.w"


int main(void)
{

inputStruct input_s= {
.ch1rise= 0,
.ch1fall= 0,
.ch2fall= 0,
.edge= 0
};

/*26:*/
#line 319 "./piruett.w"

{

ADCSRA&= ~(1<<ADEN);


ADCSRB|= (1<<ACME);


DIDR0|= ((1<<AIN1D)|(1<<AIN0D));


ACSR|= (1<<ACBG);
ACSR|= (1<<ACIC);
ACSR|= (1<<ACIS1);


TIMSK1|= (1<<ICIE1);


TCCR1B|= (1<<ICNC1);
TCCR1B|= (1<<CS10);


ADMUX&= ~((1<<MUX2)|(1<<MUX1)|(1<<MUX0));
}

/*:26*/
#line 178 "./piruett.w"

/*23:*/
#line 306 "./piruett.w"

{

DDRB|= (1<<DDB5);
}

/*:23*/
#line 179 "./piruett.w"


/*:10*//*11:*/
#line 184 "./piruett.w"

sei();

{
DDRD&= ~(1<<DDD3);


PORTD|= (1<<PORTD3);



EICRA|= (1<<ISC10);
EIMSK|= (1<<INT1);
}

/*:11*//*12:*/
#line 207 "./piruett.w"


/*24:*/
#line 312 "./piruett.w"

{
SMCR&= ~((1<<SM2)|(1<<SM1)|(1<<SM0));
}

/*:24*/
#line 209 "./piruett.w"

ledcntl(OFF);

/*:12*//*13:*/
#line 215 "./piruett.w"

input_s.edge= CH1RISE;


/*:13*//*14:*/
#line 223 "./piruett.w"



for(;;)
{

/*:14*//*15:*/
#line 232 "./piruett.w"


switch(input_s.edge)
{
case CH1RISE:
ADMUX&= ~(1<<MUX0);
TCCR1B|= (1<<ICES1);
break;
case CH1FALL:
ADMUX&= ~(1<<MUX0);
TCCR1B&= ~(1<<ICES1);
break;
case CH2FALL:
ADMUX|= (1<<MUX0);
TCCR1B&= ~(1<<ICES1);
}

/*:15*//*16:*/
#line 252 "./piruett.w"


TIFR1|= (1<<ICF1);

/*:16*//*17:*/
#line 258 "./piruett.w"


sleep_mode();

/*:17*//*18:*/
#line 265 "./piruett.w"





}



return 0;

}

/*:18*//*19:*/
#line 280 "./piruett.w"


ISR(INT1_vect)
{
}

ISR(TIMER1_CAPT_vect)
{
}



/*:19*//*20:*/
#line 294 "./piruett.w"

void ledcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}

/*:20*/
