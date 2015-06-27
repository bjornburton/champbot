#define F_CPU 16000000UL
#define BAUD 9600 \

#define ON 1
#define OFF 0
#define SET 1
#define CLEAR 0
#define CH2RISE 0
#define CH2FALL 1
#define CH1FALL 2 \
 \

#define GAINX100 6157L
#define OFFSET 218L \
 \

/*2:*/
#line 100 "./piruett.w"

/*6:*/
#line 125 "./piruett.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <stdlib.h> 
# include <stdint.h> 

/*:6*/
#line 101 "./piruett.w"

/*7:*/
#line 136 "./piruett.w"

typedef struct{
uint8_t portOut;
uint8_t starboardOut;
int32_t thrust;
int32_t turn;
uint8_t failSafe;
}outputStruct;


/*:7*//*8:*/
#line 149 "./piruett.w"

typedef struct{
uint16_t ch2rise;
uint16_t ch2fall;
uint16_t ch1fall;
uint16_t ch1duration;
uint16_t ch2duration;
uint8_t edge;
}inputStruct;


/*:8*/
#line 102 "./piruett.w"

/*9:*/
#line 160 "./piruett.w"

void ledcntl(uint8_t state);
void pwcCalc(inputStruct*);
void edgeSelect(inputStruct*);

/*:9*/
#line 103 "./piruett.w"

/*10:*/
#line 170 "./piruett.w"

void(*handleIrq)(inputStruct*)= NULL;

/*:10*/
#line 104 "./piruett.w"


/*:2*//*11:*/
#line 175 "./piruett.w"


int main(void)
{
/*:11*//*12:*/
#line 182 "./piruett.w"


inputStruct input_s= {
.ch2rise= 0,
.ch2fall= 0,
.ch1fall= 0,
.edge= CH2RISE
};

outputStruct output_s;


/*31:*/
#line 417 "./piruett.w"

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

/*:31*/
#line 194 "./piruett.w"

/*28:*/
#line 404 "./piruett.w"

{

DDRB|= (1<<DDB5);
}

/*:28*/
#line 195 "./piruett.w"


/*:12*//*13:*/
#line 200 "./piruett.w"

sei();

{
DDRD&= ~(1<<DDD3);


PORTD|= (1<<PORTD3);



EICRA|= (1<<ISC10);
EIMSK|= (1<<INT1);
}

/*:13*//*14:*/
#line 224 "./piruett.w"


/*29:*/
#line 410 "./piruett.w"

{
SMCR&= ~((1<<SM2)|(1<<SM1)|(1<<SM0));
}

/*:29*/
#line 226 "./piruett.w"

ledcntl(OFF);

edgeSelect(&input_s);

/*:14*//*15:*/
#line 235 "./piruett.w"



for(;;)
{

/*:15*//*16:*/
#line 243 "./piruett.w"


sleep_mode();

/*:16*//*17:*/
#line 251 "./piruett.w"

if(handleIrq!=NULL)
{
handleIrq(&input_s);
handleIrq= NULL;
}



/*:17*//*18:*/
#line 264 "./piruett.w"


output_s.turn= ((100L*input_s.ch1duration)/GAINX100)-OFFSET;
output_s.thrust= ((100L*input_s.ch2duration)/GAINX100)-OFFSET;

/*:18*//*19:*/
#line 273 "./piruett.w"


if(output_s.turn> 255)
output_s.turn= 255;
else
if(output_s.turn<0)
output_s.turn= 0;

if(output_s.thrust> 255)
output_s.thrust= 255;
else
if(output_s.thrust<0)
output_s.thrust= 0;



if(output_s.turn> 127L)
ledcntl(ON);
else
ledcntl(OFF);


}



return 0;

}

/*:19*//*20:*/
#line 305 "./piruett.w"


ISR(INT1_vect)
{
}

ISR(TIMER1_CAPT_vect)
{
handleIrq= &pwcCalc;
}

/*:20*//*21:*/
#line 325 "./piruett.w"

void pwcCalc(inputStruct*input_s)
{
/*:21*//*22:*/
#line 332 "./piruett.w"


switch(input_s->edge)
{
case CH2RISE:
input_s->ch2rise= ICR1;
input_s->edge= CH2FALL;
break;
case CH2FALL:
input_s->ch2fall= ICR1;
input_s->ch2duration= input_s->ch2fall-input_s->ch2rise;
input_s->edge= CH1FALL;
break;
case CH1FALL:
input_s->ch1fall= ICR1;
input_s->ch1duration= input_s->ch1fall-input_s->ch2fall;
input_s->edge= CH2RISE;
}

edgeSelect(input_s);

}


/*:22*//*23:*/
#line 361 "./piruett.w"

void edgeSelect(inputStruct*input_s)
{

switch(input_s->edge)
{
case CH2RISE:
ADMUX|= (1<<MUX0);
TCCR1B|= (1<<ICES1);
break;
case CH2FALL:
ADMUX|= (1<<MUX0);
TCCR1B&= ~(1<<ICES1);
break;
case CH1FALL:
ADMUX&= ~(1<<MUX0);
TCCR1B&= ~(1<<ICES1);
}
/*:23*//*24:*/
#line 382 "./piruett.w"


TIFR1|= (1<<ICF1);

}


/*:24*//*25:*/
#line 391 "./piruett.w"

void ledcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}


/*:25*/
