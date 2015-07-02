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
#line 101 "./piruett.w"

/*5:*/
#line 121 "./piruett.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <stdlib.h> 
# include <stdint.h> 

/*:5*/
#line 102 "./piruett.w"

/*6:*/
#line 132 "./piruett.w"

typedef struct{
uint8_t portOut;
uint8_t starboardOut;
int32_t thrust;
int32_t turn;
uint8_t failSafe;
}outputStruct;


/*:6*//*7:*/
#line 145 "./piruett.w"

typedef struct{
uint16_t ch2rise;
uint16_t ch2fall;
uint16_t ch1fall;
uint16_t ch1duration;
uint16_t ch2duration;
uint8_t edge;
}inputStruct;

/*:7*//*8:*/
#line 159 "./piruett.w"

typedef struct{
uint16_t minIn;
uint16_t maxIn;
uint16_t minOut;
uint16_t maxOut;
}scaleStruct;



/*:8*/
#line 103 "./piruett.w"

/*9:*/
#line 169 "./piruett.w"

void ledcntl(uint8_t state);
void pwcCalc(inputStruct*);
void edgeSelect(inputStruct*);
uint16_t scaler(scaleStruct*,uint16_t input);

/*:9*/
#line 104 "./piruett.w"

/*10:*/
#line 180 "./piruett.w"

void(*handleIrq)(inputStruct*)= NULL;

/*:10*/
#line 105 "./piruett.w"


/*:2*//*11:*/
#line 185 "./piruett.w"


int main(void)
{
/*:11*//*12:*/
#line 192 "./piruett.w"


inputStruct input_s= {
.edge= CH2RISE
};

outputStruct output_s;


/*:12*//*13:*/
#line 213 "./piruett.w"


scaleStruct scale_s= {
.minIn= 14970,
.maxIn= 27530,
.minOut= 1,
.maxOut= 255
};


/*30:*/
#line 422 "./piruett.w"

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

/*:30*/
#line 223 "./piruett.w"

/*27:*/
#line 409 "./piruett.w"

{

DDRB|= (1<<DDB5);
}

/*:27*/
#line 224 "./piruett.w"


/*:13*//*14:*/
#line 229 "./piruett.w"

sei();

{
DDRD&= ~(1<<DDD3);


PORTD|= (1<<PORTD3);



EICRA|= (1<<ISC10);
EIMSK|= (1<<INT1);
}

/*:14*//*15:*/
#line 253 "./piruett.w"


/*28:*/
#line 415 "./piruett.w"

{
SMCR&= ~((1<<SM2)|(1<<SM1)|(1<<SM0));
}

/*:28*/
#line 255 "./piruett.w"


ledcntl(OFF);

edgeSelect(&input_s);

/*:15*//*16:*/
#line 265 "./piruett.w"



for(;;)
{

/*:16*//*17:*/
#line 273 "./piruett.w"


sleep_mode();

/*:17*//*18:*/
#line 281 "./piruett.w"

if(handleIrq!=NULL)
{
handleIrq(&input_s);
handleIrq= NULL;
}



output_s.turn= scaler(&scale_s,input_s.ch1duration);
output_s.thrust= scaler(&scale_s,input_s.ch2duration);


if(output_s.turn>=255)
ledcntl(ON);
else
ledcntl(OFF);


}



return 0;

}

/*:18*//*19:*/
#line 310 "./piruett.w"


ISR(INT1_vect)
{
}

ISR(TIMER1_CAPT_vect)
{
handleIrq= &pwcCalc;
}

/*:19*//*20:*/
#line 330 "./piruett.w"

void pwcCalc(inputStruct*input_s)
{
/*:20*//*21:*/
#line 337 "./piruett.w"


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


/*:21*//*22:*/
#line 366 "./piruett.w"

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
/*:22*//*23:*/
#line 387 "./piruett.w"


TIFR1|= (1<<ICF1);

}


/*:23*//*24:*/
#line 396 "./piruett.w"

void ledcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}


/*:24*//*31:*/
#line 452 "./piruett.w"

uint16_t scaler(scaleStruct*scale_s,uint16_t input)
{

/*:31*//*32:*/
#line 459 "./piruett.w"

if(input> scale_s->maxIn)
return scale_s->maxOut;
else
if(input<scale_s->minIn)
return scale_s->minOut;

/*:32*//*33:*/
#line 475 "./piruett.w"



int32_t gain= (100L*(int32_t)(scale_s->maxIn-scale_s->minIn))/
(int32_t)(scale_s->maxOut-scale_s->minOut);

int32_t offset= ((100L*(int32_t)scale_s->minIn)/gain)-(int32_t)scale_s->minOut;


return(100L*(int32_t)input/gain)-offset;

}/*:33*/
