#define F_CPU 8000000UL \
 \

#define ON 1
#define OFF 0
#define OPEN 1
#define CLOSE 0
#define SET 1
#define CLEAR 0 \

/*1:*/
#line 20 "./jafco.w"

/*4:*/
#line 38 "./jafco.w"

# include <avr/io.h>  
# include <util/delay.h>  
# include <avr/interrupt.h>  
# include <avr/sleep.h>  
# include <avr/wdt.h>  
# include <stdlib.h> 
# include <stdint.h> 


/*:4*/
#line 21 "./jafco.w"

/*5:*/
#line 48 "./jafco.w"

void jawcntl(uint8_t state);
void fuelcntl(uint8_t state);
void igncntl(uint8_t state);
void releaseseq(void);
void fireseq(void);

/*:5*/
#line 22 "./jafco.w"

/*6:*/
#line 61 "./jafco.w"

void(*handleirq)()= NULL;



int main(void)
{


/*28:*/
#line 316 "./jafco.w"

{

PCMSK|= (1<<PCINT3);

PCMSK|= (1<<PCINT4);

GIMSK|= (1<<PCIE);
}

/*:28*/
#line 70 "./jafco.w"

/*27:*/
#line 308 "./jafco.w"

{

PORTB|= (1<<PORTB3);

PORTB|= (1<<PORTB4);
}

/*:27*/
#line 71 "./jafco.w"

/*26:*/
#line 298 "./jafco.w"

{

DDRB|= (1<<DDB0);

DDRB|= (1<<DDB1);

DDRB|= (1<<DDB2);
}

/*:26*/
#line 72 "./jafco.w"


/*:6*/
#line 23 "./jafco.w"



/*:1*//*7:*/
#line 78 "./jafco.w"

sei();
/*:7*//*8:*/
#line 86 "./jafco.w"

/*34:*/
#line 364 "./jafco.w"

{
MCUCR&= ~(1<<SM1);
MCUCR&= ~(1<<SM0);
}


/*:34*/
#line 87 "./jafco.w"


/*:8*//*9:*/
#line 94 "./jafco.w"

for(;;)
{

/*:9*//*10:*/
#line 100 "./jafco.w"


igncntl(OFF);
fuelcntl(OFF);
jawcntl(CLOSE);

/*:10*//*11:*/
#line 108 "./jafco.w"

sleep_mode();
/*:11*//*12:*/
#line 112 "./jafco.w"


if(handleirq!=NULL)
{
handleirq();
handleirq= NULL;
}
}

return 0;
}

/*:12*//*13:*/
#line 126 "./jafco.w"

void releaseseq()
{

/*:13*//*14:*/
#line 132 "./jafco.w"


jawcntl(OPEN);

while(!(PINB&(1<<PB3)))
_delay_ms(10);

jawcntl(CLOSE);

}
/*:14*//*15:*/
#line 145 "./jafco.w"

void fireseq()
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

/*:15*//*16:*/
#line 167 "./jafco.w"


while(!(PINB&(1<<PB4)))
{

/*:16*//*17:*/
#line 174 "./jafco.w"

if(firingstate==ready)
{


jawcntl(OPEN);
firingstate= opened;
continue;
}
/*:17*//*18:*/
#line 185 "./jafco.w"

if(firingstate==opened)
{

for(int8_t count= 0;count<3;count++)
{
igncntl(ON);
_delay_ms(100);
igncntl(OFF);
_delay_ms(100);
}

_delay_ms(1000);
firingstate= warned;
continue;
}
/*:18*//*19:*/
#line 203 "./jafco.w"


if(firingstate==warned)
{

fuelcntl(ON);
_delay_ms(500);
firingstate= precharged;
continue;
}
/*:19*//*20:*/
#line 215 "./jafco.w"


if(firingstate==precharged)
{

igncntl(ON);
_delay_ms(250);
firingstate= igniting;
continue;
}
/*:20*//*21:*/
#line 227 "./jafco.w"

if(firingstate==igniting)
{

igncntl(OFF);
firingstate= burning;
continue;
}
}

/*:21*//*22:*/
#line 239 "./jafco.w"


igncntl(OFF);
fuelcntl(OFF);
jawcntl(CLOSE);

}


/*:22*//*24:*/
#line 257 "./jafco.w"

ISR(PCINT0_vect)
{
const int8_t high= 32;
const int8_t low= -high;
int8_t dbp3= 0;
int8_t dbp4= 0;


while(abs(dbp3)<high)
{
if(!(PINB&(1<<PB3))&&dbp3> low)
dbp3--;
else
if((PINB&(1<<PB3))&&dbp3<high)
dbp3++;
_delay_ms(1);
}

while(abs(dbp4)<high)
{
if(!(PINB&(1<<PB4))&&dbp4> low)
dbp4--;
else
if((PINB&(1<<PB4))&&dbp4<high)
dbp4++;
_delay_ms(1);
}

if(dbp3==low)
handleirq= &releaseseq;
else
if(dbp4==low)
handleirq= &fireseq;
}


/*:24*//*29:*/
#line 328 "./jafco.w"

void jawcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB0):PORTB&~(1<<PORTB0);
}

/*:29*//*30:*/
#line 336 "./jafco.w"

void fuelcntl(uint8_t state)
{

PORTB= state?PORTB|(1<<PORTB1):PORTB&~(1<<PORTB1);
}

/*:30*//*31:*/
#line 345 "./jafco.w"

void igncntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB2):PORTB&~(1<<PORTB2);
}

/*:31*/
