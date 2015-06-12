#define F_CPU 16000000UL \

#define ON 1
#define OFF 0
#define SET 1
#define CLEAR 0 \

/*1:*/
#line 86 "./piruett.w"

/*4:*/
#line 101 "./piruett.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <stdlib.h> 
# include <stdint.h> 

/*:4*/
#line 87 "./piruett.w"

/*5:*/
#line 111 "./piruett.w"

typedef struct{
uint8_t portOut;
uint8_t starOut;
uint16_t thrust;
uint16_t radius;
}statestruct;


/*:5*/
#line 88 "./piruett.w"

/*6:*/
#line 120 "./piruett.w"

void ledcntl(uint8_t state);

/*:6*/
#line 89 "./piruett.w"



/*:1*//*8:*/
#line 133 "./piruett.w"


int main(void)
{


/*20:*/
#line 228 "./piruett.w"

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

/*:20*/
#line 139 "./piruett.w"

/*17:*/
#line 213 "./piruett.w"

{

DDRB|= (1<<DDB5);
}

/*:17*/
#line 140 "./piruett.w"


/*:8*//*9:*/
#line 145 "./piruett.w"

sei();
/*:9*//*10:*/
#line 151 "./piruett.w"


/*18:*/
#line 219 "./piruett.w"

{
SMCR&= ~(1<<SM2);
SMCR&= ~(1<<SM1);
SMCR&= ~(1<<SM0);
}

/*:18*/
#line 153 "./piruett.w"

ledcntl(OFF);
ADMUX|= (~(1<<MUX2)|~(1<<MUX1)|~(1<<MUX0));

/*:10*//*11:*/
#line 160 "./piruett.w"

for(;;)
{

/*:11*//*12:*/
#line 166 "./piruett.w"

sleep_mode();

/*:12*//*13:*/
#line 171 "./piruett.w"


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

/*:13*//*14:*/
#line 201 "./piruett.w"

void ledcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}

/*:14*/
