#define F_CPU 16000000UL
#define BAUD 9600 \

#define ON 1
#define OFF 0
#define SET 1
#define CLEAR 0 \
 \
 \

/*2:*/
#line 93 "./piruett.w"

/*5:*/
#line 111 "./piruett.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <stdlib.h> 
# include <stdint.h> 

/*:5*/
#line 94 "./piruett.w"

/*6:*/
#line 121 "./piruett.w"

typedef struct{
uint8_t portOut;
uint8_t starOut;
uint16_t thrust;
uint16_t radius;
}statestruct;


/*:6*/
#line 95 "./piruett.w"

/*7:*/
#line 130 "./piruett.w"

void ledcntl(uint8_t state);

/*:7*/
#line 96 "./piruett.w"



/*:2*//*9:*/
#line 143 "./piruett.w"


int main(void)
{


/*21:*/
#line 253 "./piruett.w"

{
ADCSRB|= (1<<ACME);
ADCSRA&= ~(1<<ADEN);
DIDR0|= ((1<<AIN1D)|(1<<AIN0D));
ACSR|= (1<<ACBG);
ACSR|= (1<<ACIC);
ACSR|= (1<<ACIE);
ACSR&= ~(1<<ACIS0);
ACSR|= (1<<ACIS1);
TIMSK1|= (1<<ICIE1);
TCCR1B|= (1<<ICNC1);
TCCR1B|= (1<<CS10);
PRR&= ~(1<<PRADC);
}

/*:21*/
#line 149 "./piruett.w"

/*18:*/
#line 240 "./piruett.w"

{

DDRB|= (1<<DDB5);
}

/*:18*/
#line 150 "./piruett.w"


/*:9*//*10:*/
#line 155 "./piruett.w"

DDRD&= ~(1<<DDD3);


PORTD|= (1<<PORTD3);




EICRA|= (1<<ISC10);
EIMSK|= (1<<INT1);
sei();
/*:10*//*11:*/
#line 171 "./piruett.w"


/*19:*/
#line 246 "./piruett.w"

{
SMCR&= ~((1<<SM2)|(1<<SM1)|(1<<SM0));
}

/*:19*/
#line 173 "./piruett.w"

ledcntl(OFF);
ADMUX&= ~((1<<MUX2)|(1<<MUX1)|(1<<MUX0));

/*:11*//*12:*/
#line 180 "./piruett.w"



for(;;)
{

/*:12*//*13:*/
#line 188 "./piruett.w"


SMCR|= (1<<SE);
sleep_mode();
SMCR&= ~(1<<SE);

ledcntl(ON);
/*:13*//*14:*/
#line 198 "./piruett.w"


static char toggle= 0;

{
if(toggle)
{
ledcntl(ON);
TCCR1B&= ~(1<<ICES1);
}
else
{
ledcntl(ON);
TCCR1B|= (1<<ICES1);
}
toggle= toggle?0:1;
}



}



return 0;

}

/*:14*//*15:*/
#line 228 "./piruett.w"

void ledcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}

/*:15*/
