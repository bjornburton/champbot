#define F_CPU 8000000UL \
 \

#define ON 1
#define OFF 0
#define OPEN 1
#define CLOSE 0
#define SET 1
#define CLEAR 0 \

/*1:*/
#line 23 "./jafco.w"

/*4:*/
#line 42 "./jafco.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <stdlib.h> 
# include <stdint.h> 

/*:4*/
#line 24 "./jafco.w"

/*5:*/
#line 52 "./jafco.w"

typedef struct{
uint8_t count;
}statestruct;


/*:5*/
#line 25 "./jafco.w"

/*6:*/
#line 58 "./jafco.w"

void jawcntl(uint8_t state);
void fuelcntl(uint8_t state);
void igncntl(uint8_t state);
void fireseq(statestruct*);
void releaseseq(statestruct*);

/*:6*/
#line 26 "./jafco.w"

/*7:*/
#line 71 "./jafco.w"

void(*handleirq)(statestruct*)= NULL;


/*:7*/
#line 27 "./jafco.w"



/*:1*//*8:*/
#line 77 "./jafco.w"


int main(void)
{

/*:8*//*9:*/
#line 86 "./jafco.w"


statestruct s_state;

/*31:*/
#line 305 "./jafco.w"

{

PORTB|= (1<<PORTB3);

PORTB|= (1<<PORTB4);

PCMSK|= (1<<PCINT3);

PCMSK|= (1<<PCINT4);

GIMSK|= (1<<PCIE);
}

/*:31*/
#line 90 "./jafco.w"

/*30:*/
#line 295 "./jafco.w"

{

DDRB|= (1<<DDB0);

DDRB|= (1<<DDB1);

DDRB|= (1<<DDB2);
}

/*:30*/
#line 91 "./jafco.w"


/*:9*//*10:*/
#line 94 "./jafco.w"

jawcntl(CLOSE);
fuelcntl(OFF);
igncntl(OFF);

/*:10*//*11:*/
#line 101 "./jafco.w"

/*35:*/
#line 347 "./jafco.w"

{
TCCR1= ((1<<CS10)|(1<<CS11)|(1<<CS12)|(1<<CS13));

TIMSK|= (1<<TOIE1);

}


/*:35*/
#line 102 "./jafco.w"



/*:11*//*12:*/
#line 108 "./jafco.w"

sei();
/*:12*//*13:*/
#line 116 "./jafco.w"

/*36:*/
#line 360 "./jafco.w"

{
MCUCR&= ~(1<<SM1);
MCUCR&= ~(1<<SM0);
}


/*:36*/
#line 117 "./jafco.w"



/*:13*//*14:*/
#line 125 "./jafco.w"

for(;;)
{

/*:14*//*15:*/
#line 131 "./jafco.w"

sleep_mode();

/*:15*//*16:*/
#line 136 "./jafco.w"

if(handleirq!=NULL)
{
handleirq(&s_state);
handleirq= NULL;
}

}


return 0;

}

/*:16*//*17:*/
#line 152 "./jafco.w"

void releaseseq(statestruct*s_now)
{
/*:17*//*18:*/
#line 157 "./jafco.w"

while(!(PORTB&(1<<PORTB3)))
{

}



}
/*:18*//*19:*/
#line 169 "./jafco.w"

void fireseq(statestruct*s_now)
{
uint8_t firingstate;

enum firingstates
{
ready,
opened,
warned,
precharged,
igniting,
burning
};

firingstate= ready;

/*:19*//*20:*/
#line 189 "./jafco.w"


while(!(PORTB&(1<<PORTB4)))
{
/*:20*//*21:*/
#line 195 "./jafco.w"

if(firingstate==ready)
{


firingstate= opened;
continue;
}
/*:21*//*22:*/
#line 205 "./jafco.w"

if(firingstate==opened)
{

_delay_ms(250);

_delay_ms(250);

_delay_ms(250);

_delay_ms(1000);
firingstate= warned;
continue;
}
/*:22*//*23:*/
#line 221 "./jafco.w"


if(firingstate==warned)
{

_delay_ms(250);
firingstate= precharged;
continue;
}
/*:23*//*24:*/
#line 232 "./jafco.w"


if(firingstate==precharged)
{

_delay_ms(250);
firingstate= igniting;
continue;
}
/*:24*//*25:*/
#line 243 "./jafco.w"

if(firingstate==igniting)
{

firingstate= burning;
continue;
}
}

/*:25*//*26:*/
#line 254 "./jafco.w"



}



/*:26*//*27:*/
#line 267 "./jafco.w"


ISR(TIMER1_OVF_vect)
{
handleirq= NULL;
}

/*:27*//*28:*/
#line 276 "./jafco.w"

ISR(PCINT0_vect)
{

_delay_ms(100);

if(!(PORTB&(1<<PORTB3)))
handleirq= &releaseseq;
else
if(!(PORTB&(1<<PORTB4)))
handleirq= &fireseq;

}


/*:28*//*32:*/
#line 321 "./jafco.w"

void jawcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB0):PORTB&~(1<<PORTB0);
}

/*:32*//*33:*/
#line 329 "./jafco.w"

void fuelcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB1):PORTB&~(1<<PORTB1);
}

/*:33*//*34:*/
#line 337 "./jafco.w"

void igncntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB2):PORTB&~(1<<PORTB2);
}


/*:34*/
