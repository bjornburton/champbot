#define F_CPU 16000000UL
#define BAUD 9600 \

#define ON 1
#define OFF 0
#define SET 1
#define CLEAR 0
#define TRUE 1
#define FALSE 0
#define FORWARD 1
#define REVERSE 0
#define CLOSED 1
#define OPEN 0 \
 \

#define CH2RISE 0
#define CH2FALL 1
#define CH1FALL 2
#define MAX_DUTYCYCLE 98 \

/*2:*/
#line 74 "./piruett.w"

/*6:*/
#line 103 "./piruett.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <avr/wdt.h>  
# include <stdlib.h> 
# include <stdint.h> 

/*:6*/
#line 75 "./piruett.w"

/*7:*/
#line 115 "./piruett.w"

typedef struct{
uint16_t ch2rise;
uint16_t ch2fall;
uint16_t ch1fall;
uint16_t ch1duration;
uint16_t ch2duration;
uint16_t minIn;
uint16_t maxIn;
uint8_t edge;
uint8_t lostSignal;
}inputStruct;

/*:7*//*8:*/
#line 129 "./piruett.w"

typedef struct{
int16_t thrust;
int16_t radius;
int16_t track;
int16_t starboardOut;
int16_t portOut;
int16_t minOut;
int16_t maxOut;
int8_t deadBand;
}transStruct;


/*:8*/
#line 76 "./piruett.w"

/*9:*/
#line 142 "./piruett.w"

void relayCntl(int8_t state);
void ledCntl(int8_t state);
void portDirection(int8_t state);
void starboardDirection(int8_t state);
void pwcCalc(inputStruct*);
void edgeSelect(inputStruct*);
int16_t scaler(inputStruct*,transStruct*,uint16_t input);
void translate(transStruct*);
void setPwm(transStruct*);
void lostSignal(inputStruct*);

/*:9*/
#line 77 "./piruett.w"

/*10:*/
#line 161 "./piruett.w"

void(*handleIrq)(inputStruct*)= NULL;

/*:10*/
#line 78 "./piruett.w"


/*:2*//*11:*/
#line 166 "./piruett.w"


int main(void)
{

/*:11*//*12:*/
#line 176 "./piruett.w"


inputStruct input_s= {
.edge= CH2RISE,
.minIn= 14970,
.maxIn= 27530,
.lostSignal= TRUE
};


/*:12*//*13:*/
#line 200 "./piruett.w"

transStruct translation_s= {
.minOut= -255,
.maxOut= 255,
.deadBand= 10
};


cli();

/*37:*/
#line 471 "./piruett.w"

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

/*:37*/
#line 210 "./piruett.w"

/*34:*/
#line 448 "./piruett.w"


DDRB|= (1<<DDB5);



DDRB|= (1<<DDB0);




DDRD|= ((1<<DDD5)|(1<<DDD6));


DDRD|= ((1<<DDD3)|(1<<DDD4));

/*:34*/
#line 211 "./piruett.w"

cli();
/*39:*/
#line 501 "./piruett.w"

{

WDTCSR|= (1<<WDCE)|(1<<WDE);
WDTCSR= (1<<WDIE)|(1<<WDP2);
}

/*:39*/
#line 213 "./piruett.w"


/*:13*//*14:*/
#line 218 "./piruett.w"

sei();


/*:14*//*15:*/
#line 226 "./piruett.w"

/*41:*/
#line 515 "./piruett.w"

{

TCCR0A|= (1<<WGM00);
TCCR0A|= (1<<COM0A1);
TCCR0A|= (1<<COM0B1);


TCCR0B|= (1<<CS01);
}


/*:41*/
#line 227 "./piruett.w"



/*:15*//*16:*/
#line 239 "./piruett.w"


/*35:*/
#line 464 "./piruett.w"

{
SMCR&= ~((1<<SM2)|(1<<SM1)|(1<<SM0));
}

/*:35*/
#line 241 "./piruett.w"



ledCntl(OFF);

/*:16*//*17:*/
#line 248 "./piruett.w"

edgeSelect(&input_s);

/*:17*//*18:*/
#line 256 "./piruett.w"



for(;;)
{

/*:18*//*19:*/
#line 266 "./piruett.w"

setPwm(&translation_s);

sleep_mode();

/*:19*//*20:*/
#line 276 "./piruett.w"

if(handleIrq!=NULL)
{
handleIrq(&input_s);
handleIrq= NULL;
}



translation_s.radius= scaler(&input_s,&translation_s,input_s.ch1duration);
translation_s.thrust= scaler(&input_s,&translation_s,input_s.ch2duration);
translation_s.track= 100;

translate(&translation_s);

/*:20*//*21:*/
#line 293 "./piruett.w"

if(translation_s.portOut==0)
ledCntl(ON);
else
ledCntl(OFF);


}



return 0;

}

/*:21*//*22:*/
#line 310 "./piruett.w"


ISR(TIMER1_CAPT_vect)
{
handleIrq= &pwcCalc;
}

ISR(WDT_vect)
{
handleIrq= &lostSignal;
}

/*:22*//*23:*/
#line 331 "./piruett.w"

void pwcCalc(inputStruct*input_s)
{
/*:23*//*24:*/
#line 341 "./piruett.w"



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
input_s->lostSignal= FALSE;
wdt_reset();
}

edgeSelect(input_s);

}

/*:24*//*25:*/
#line 369 "./piruett.w"

void lostSignal(inputStruct*input_s)
{
input_s->lostSignal= TRUE;
input_s->edge= CH2RISE;

edgeSelect(input_s);
}

/*:25*//*26:*/
#line 383 "./piruett.w"

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
/*:26*//*27:*/
#line 404 "./piruett.w"


TIFR1|= (1<<ICF1);

}


/*:27*//*28:*/
#line 413 "./piruett.w"

void ledCntl(int8_t state)
{
PORTB= state?PORTB|(1<<PORTB5):PORTB&~(1<<PORTB5);
}

/*:28*//*29:*/
#line 421 "./piruett.w"

void relayCntl(int8_t state)
{
PORTB= state?PORTB|(1<<PORTB0):PORTB&~(1<<PORTB0);
}

/*:29*//*30:*/
#line 429 "./piruett.w"

void portDirection(int8_t state)
{
PORTD= state?PORTD|(1<<PORTD3):PORTD&~(1<<PORTD3);
}

/*:30*//*31:*/
#line 437 "./piruett.w"

void starboardDirection(int8_t state)
{
PORTD= state?PORTD|(1<<PORTD4):PORTD&~(1<<PORTD4);
}

/*:31*//*42:*/
#line 531 "./piruett.w"

int16_t scaler(inputStruct*input_s,transStruct*trans_s,uint16_t input)
{
uint16_t solution;
/*:42*//*43:*/
#line 540 "./piruett.w"

if(input_s->lostSignal==TRUE)
return 0;

if(input> input_s->maxIn)
return trans_s->maxOut;

if(input<input_s->minIn)
return trans_s->minOut;


/*:43*//*44:*/
#line 563 "./piruett.w"

const int32_t ampFact= 128L;

int32_t gain= (ampFact*(int32_t)(input_s->maxIn-input_s->minIn))/
(int32_t)(trans_s->maxOut-trans_s->minOut);

int32_t offset= ((ampFact*(int32_t)input_s->minIn)/gain)
-(int32_t)trans_s->minOut;

solution= (ampFact*(int32_t)input/gain)-offset;


return(abs(solution)> trans_s->deadBand)?solution:0;

}

/*:44*//*45:*/
#line 587 "./piruett.w"


void translate(transStruct*trans_s)
{
int16_t speed= trans_s->thrust;
int16_t rotation;
int16_t difference;
const int16_t max= (MAX_DUTYCYCLE*UINT8_MAX)/100;
const int16_t ampFact= 128;


/*:45*//*46:*/
#line 602 "./piruett.w"

difference= (speed*((ampFact*trans_s->radius)/UINT8_MAX))/ampFact;
rotation= (trans_s->track*((ampFact*difference)/UINT8_MAX))/ampFact;
/*:46*//*47:*/
#line 610 "./piruett.w"

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

}

void setPwm(transStruct*trans_s)
{

if(trans_s->portOut>=0)
{
OCR0A= (uint8_t)trans_s->portOut;
portDirection(FORWARD);
}
else
{
OCR0A= (uint8_t)-trans_s->portOut;
portDirection(REVERSE);
}


if(trans_s->starboardOut>=0)
{
OCR0B= (uint8_t)trans_s->starboardOut;
starboardDirection(FORWARD);
}
else
{
OCR0B= (uint8_t)-trans_s->starboardOut;
starboardDirection(REVERSE);
}


if(trans_s->portOut||trans_s->starboardOut)
relayCntl(CLOSED);
else
relayCntl(OPEN);


}/*:47*/
