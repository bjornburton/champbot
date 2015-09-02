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

/*23:*/
#line 205 "./jafco.w"

{

PORTB|= (1<<PORTB3);

PORTB|= (1<<PORTB4);

PCMSK|= (1<<PCINT3);

PCMSK|= (1<<PCINT4);

GIMSK|= (1<<PCIE);
}

/*:23*/
#line 90 "./jafco.w"

/*22:*/
#line 195 "./jafco.w"

{

DDRB|= (1<<DDB0);

DDRB|= (1<<DDB1);

DDRB|= (1<<DDB2);
}

/*:22*/
#line 91 "./jafco.w"


/*:9*//*10:*/
#line 94 "./jafco.w"

jawcntl(CLOSE);
fuelcntl(OFF);
igncntl(OFF);

/*:10*//*11:*/
#line 101 "./jafco.w"

/*27:*/
#line 247 "./jafco.w"

{
TCCR1= ((1<<CS10)|(1<<CS11)|(1<<CS12)|(1<<CS13));

TIMSK|= (1<<TOIE1);

}


/*:27*/
#line 102 "./jafco.w"



/*:11*//*12:*/
#line 108 "./jafco.w"

sei();
/*:12*//*13:*/
#line 116 "./jafco.w"

/*28:*/
#line 260 "./jafco.w"

{
MCUCR&= ~(1<<SM1);
MCUCR&= ~(1<<SM0);
}


/*:28*/
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
}
/*:17*//*18:*/
#line 159 "./jafco.w"

void fireseq(statestruct*s_now)
{
}



/*:18*//*19:*/
#line 174 "./jafco.w"


ISR(TIMER1_OVF_vect)
{
handleirq= NULL;
}

/*:19*//*20:*/
#line 183 "./jafco.w"


ISR(PCINT0_vect)
{
handleirq= &releaseseq;
}


/*:20*//*24:*/
#line 221 "./jafco.w"

void jawcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB0):PORTB&~(1<<PORTB0);
}

/*:24*//*25:*/
#line 229 "./jafco.w"

void fuelcntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB1):PORTB&~(1<<PORTB1);
}

/*:25*//*26:*/
#line 237 "./jafco.w"

void igncntl(uint8_t state)
{
PORTB= state?PORTB|(1<<PORTB2):PORTB&~(1<<PORTB2);
}


/*:26*/
