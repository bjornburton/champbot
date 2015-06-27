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
uint16_t ch2rise;
uint16_t ch2fall;
uint16_t ch1fall;
uint16_t ch1duration;
uint16_t ch2duration;
uint8_t edge;
}inputStruct;


/*:7*/
#line 102 "./piruett.w"

/*8:*/
#line 155 "./piruett.w"

void ledcntl(uint8_t state);
void pwcCalc(inputStruct*);
void edgeSelect(inputStruct*);

/*:8*/
#line 103 "./piruett.w"

/*9:*/
#line 165 "./piruett.w"

void(*handleIrq)(inputStruct*)= NULL;

/*:9*/
#line 104 "./piruett.w"


/*:2*//*10:*/
#line 170 "./piruett.w"


int main(void)
{
/*:10*//*11:*/
#line 177 "./piruett.w"


inputStruct input_s= {
.ch2rise= 0,
.ch2fall= 0,
.ch1fall= 0,
.edge= CH2RISE
};

outputStruct output_s;


/*29:*/
#line 395 "./piruett.w"

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

/*:29*/
#line 189 "./piruett.w"

/*26:*/
#line 382 "./piruett.w"

{

DDRB|= (1<<DDB5);
}

/*:26*/
#line 190 "./piruett.w"


/*:11*//*12:*/
#line 195 "./piruett.w"

sei();

{
DDRD&= ~(1<<DDD3);


PORTD|= (1<<PORTD3);



EICRA|= (1<<ISC10);
EIMSK|= (1<<INT1);
}

/*:12*//*13:*/
#line 219 "./piruett.w"


/*27:*/
#line 388 "./piruett.w"

{
SMCR&= ~((1<<SM2)|(1<<SM1)|(1<<SM0));
}

/*:27*/
#line 221 "./piruett.w"

ledcntl(OFF);

edgeSelect(&input_s);

/*:13*//*14:*/
#line 230 "./piruett.w"



for(;;)
{

/*:14*//*15:*/
#line 239 "./piruett.w"




/*:15*//*16:*/
#line 245 "./piruett.w"


sleep_mode();

/*:16*//*17:*/
#line 253 "./piruett.w"

if(handleIrq!=NULL)
{
handleIrq(&input_s);
handleIrq= NULL;
}








if(input_s.ch1duration> 32200)
ledcntl(ON);
else
ledcntl(OFF);


}



return 0;

}

/*:17*//*18:*/
#line 283 "./piruett.w"


ISR(INT1_vect)
{
}

ISR(TIMER1_CAPT_vect)
{
handleIrq= &pwcCalc;
}

/*:18*//*19:*/
#line 303 "./piruett.w"

void pwcCalc(inputStruct*input_s)
{
/*:19*//*20:*/
#line 310 "./piruett.w"


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


/*:20*//*21:*/
#line 339 "./piruett.w"

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
/*:21*//*22:*/
#line 360 "./piruett.w"


TIFR1|= (1<<ICF1);

}


/*:22*//*23:*/
#line 369 "./piruett.w"

void ledcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}


/*:23*/
