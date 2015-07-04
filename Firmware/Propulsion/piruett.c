#define F_CPU 16000000UL
#define BAUD 9600 \

#define ON 1
#define OFF 0
#define SET 1
#define CLEAR 0 \

#define CH2RISE 0
#define CH2FALL 1
#define CH1FALL 2
#define MAX_DUTYCYCLE 98 \
 \

/*2:*/
#line 74 "./piruett.w"

/*6:*/
#line 97 "./piruett.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <stdlib.h> 
# include <stdint.h> 

/*:6*/
#line 75 "./piruett.w"

/*7:*/
#line 108 "./piruett.w"

typedef struct{
uint16_t ch2rise;
uint16_t ch2fall;
uint16_t ch1fall;
uint16_t ch1duration;
uint16_t ch2duration;
uint8_t edge;
}inputStruct;

/*:7*//*8:*/
#line 119 "./piruett.w"

typedef struct{
int16_t thrust;
int16_t radius;
int16_t track;
int16_t starboardOut;
int16_t portOut;
}transStruct;


/*:8*//*9:*/
#line 130 "./piruett.w"

typedef struct{
int16_t minIn;
int16_t maxIn;
int16_t minOut;
int16_t maxOut;
int8_t deadBand;
}scaleStruct;


/*:9*/
#line 76 "./piruett.w"

/*10:*/
#line 140 "./piruett.w"

void ledcntl(uint8_t state);
void pwcCalc(inputStruct*);
void edgeSelect(inputStruct*);
uint16_t scaler(scaleStruct*,uint16_t input);
void translate();
void setPwm();

/*:10*/
#line 77 "./piruett.w"

/*11:*/
#line 153 "./piruett.w"

void(*handleIrq)(inputStruct*)= NULL;

/*:11*/
#line 78 "./piruett.w"


/*:2*//*12:*/
#line 158 "./piruett.w"


int main(void)
{
/*:12*//*13:*/
#line 165 "./piruett.w"


inputStruct input_s= {
.edge= CH2RISE
};


/*:13*//*14:*/
#line 186 "./piruett.w"


scaleStruct inputScale_s= {
.minIn= 14970,
.maxIn= 27530,
.minOut= -255,
.maxOut= 255,
.deadBand= 5
};


transStruct translation_s;



/*32:*/
#line 408 "./piruett.w"

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

/*:32*/
#line 201 "./piruett.w"

/*29:*/
#line 395 "./piruett.w"

{

DDRB|= (1<<DDB5);
}

/*:29*/
#line 202 "./piruett.w"


/*:14*//*15:*/
#line 207 "./piruett.w"

sei();

{
DDRD&= ~(1<<DDD3);


PORTD|= (1<<PORTD3);



EICRA|= (1<<ISC10);
EIMSK|= (1<<INT1);
}

/*:15*//*16:*/
#line 231 "./piruett.w"


/*30:*/
#line 401 "./piruett.w"

{
SMCR&= ~((1<<SM2)|(1<<SM1)|(1<<SM0));
}

/*:30*/
#line 233 "./piruett.w"


ledcntl(OFF);

edgeSelect(&input_s);

/*:16*//*17:*/
#line 244 "./piruett.w"



for(;;)
{

/*:17*//*18:*/
#line 253 "./piruett.w"


sleep_mode();

/*:18*//*19:*/
#line 262 "./piruett.w"

if(handleIrq!=NULL)
{
handleIrq(&input_s);
handleIrq= NULL;
}



translation_s.radius= scaler(&inputScale_s,input_s.ch1duration);
translation_s.thrust= scaler(&inputScale_s,input_s.ch2duration);
translation_s.track= 100;

translate(&translation_s);

/*:19*//*20:*/
#line 279 "./piruett.w"

if(translation_s.radius>=255)
ledcntl(ON);
else
ledcntl(OFF);


}



return 0;

}

/*:20*//*21:*/
#line 296 "./piruett.w"


ISR(INT1_vect)
{
}

ISR(TIMER1_CAPT_vect)
{
handleIrq= &pwcCalc;
}

/*:21*//*22:*/
#line 316 "./piruett.w"

void pwcCalc(inputStruct*input_s)
{
/*:22*//*23:*/
#line 323 "./piruett.w"


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


/*:23*//*24:*/
#line 352 "./piruett.w"

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
/*:24*//*25:*/
#line 373 "./piruett.w"


TIFR1|= (1<<ICF1);

}


/*:25*//*26:*/
#line 382 "./piruett.w"

void ledcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}


/*:26*//*33:*/
#line 439 "./piruett.w"

uint16_t scaler(scaleStruct*inputScale_s,uint16_t input)
{
const int32_t ampFact= 128L;

/*:33*//*34:*/
#line 447 "./piruett.w"

if(input> inputScale_s->maxIn)
return inputScale_s->maxOut;
else
if(input<inputScale_s->minIn)
return inputScale_s->minOut;

/*:34*//*35:*/
#line 464 "./piruett.w"



int32_t gain= (ampFact*(int32_t)(inputScale_s->maxIn-inputScale_s->minIn))/
(int32_t)(inputScale_s->maxOut-inputScale_s->minOut);

int32_t offset= ((ampFact*(int32_t)inputScale_s->minIn)/gain)
-(int32_t)inputScale_s->minOut;


return(ampFact*(int32_t)input/gain)-offset;

}

/*:35*//*36:*/
#line 486 "./piruett.w"


void translate(transStruct*trans_s)
{
int16_t speed;
int16_t rotation;
int16_t difference;
const int16_t max= (MAX_DUTYCYCLE*UINT8_MAX)/100;
const int16_t ampFact= 128;

speed= trans_s->thrust;


/*:36*//*37:*/
#line 503 "./piruett.w"

difference= (speed*((ampFact*trans_s->radius)/UINT8_MAX))/ampFact;
rotation= (trans_s->track*((ampFact*difference)/UINT8_MAX))/ampFact;

/*:37*//*38:*/
#line 512 "./piruett.w"

if((speed-rotation)>=max)
trans_s->portOut= max;
else if((speed-rotation)<=-max)
trans_s->portOut= -max;
else
trans_s->portOut= speed-rotation;


if((speed+rotation)>=max)
trans_s->starboardOut= max;
else if((speed+rotation)<=-max)
trans_s->starboardOut= -max;
else
trans_s->starboardOut= speed+rotation;


}/*:38*/
