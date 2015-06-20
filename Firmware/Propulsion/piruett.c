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
#line 239 "./piruett.w"

{
ADCSRB|= (1<<ACME);
ADMUX|= (1<<MUX0);
ADCSRA&= ~(1<<ADEN);
DIDR0|= ((1<<AIN1D)|(1<<AIN0D));
ACSR|= (1<<ACBG);
ACSR|= (1<<ACIC);
TIMSK1|= (1<<ICIE1);
TCCR1B|= (1<<ICNC1);
TCCR1B|= (1<<CS10);
}

/*:21*/
#line 149 "./piruett.w"

/*18:*/
#line 224 "./piruett.w"

{

DDRB|= (1<<DDB5);
}

/*:18*/
#line 150 "./piruett.w"


/*:9*//*10:*/
#line 155 "./piruett.w"

sei();
/*:10*//*11:*/
#line 161 "./piruett.w"


/*19:*/
#line 230 "./piruett.w"

{
SMCR&= ~(1<<SM2);
SMCR&= ~(1<<SM1);
SMCR&= ~(1<<SM0);
}

/*:19*/
#line 163 "./piruett.w"

ledcntl(OFF);
ADMUX|= (~(1<<MUX2)|~(1<<MUX1)|~(1<<MUX0));

/*:11*//*12:*/
#line 170 "./piruett.w"

for(;;)
{

/*:12*//*13:*/
#line 176 "./piruett.w"

sleep_mode();

/*:13*//*14:*/
#line 182 "./piruett.w"


static char toggle= 0;

{
if(toggle)
{
ledcntl(ON);
TCCR1B&= ~(1<<ICES1);
}
else
{
ledcntl(OFF);
TCCR1B|= (1<<ICES1);
}
toggle= toggle?0:1;
}



}



return 0;

}

/*:14*//*15:*/
#line 212 "./piruett.w"

void ledcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}

/*:15*/
