
% jafco

\nocon % omit table of contents
\datethis % print date on listing

@* Introduction. This is the firmware portion of Jaw and Fire control.

This will facilitate two actions: opening the jaw to release the floating
object and light the target on fire.

The jaw will close by return-spring so the action will to open it.

Fire is a  sequence of opening the jaw, releasing the butane and firing the
ignitor.

place-holder code below
==========================

Extensive use was made of the datasheet, Atmel ``Atmel ATtiny25, ATtiny45,
 ATtiny85 Datasheet'' Rev. 2586Q–AVR–08/2013 (Tue 06 Aug 2013 03:19:12 PM EDT)
and ``AVR130: Setup and Use the AVR Timers'' Rev. 2505A–AVR–02/02.
@c
@< Include @>@;
@< Types @>@;
@< Prototypes @>@;
@< Global variables @>@;


@ |"F_CPU"| is used to convey the Trinket clock rate.
@d F_CPU 8000000UL


@ Here are some Boolean definitions that are used.
@d ON 1
@d OFF 0
@d OPEN 1
@d CLOSE 0
@d SET 1
@d CLEAR 0

@ @<Include...@>=
# include <avr/io.h> // need some port access
# include <util/delay.h> // need to delay
# include <avr/interrupt.h> // have need of an interrupt
# include <avr/sleep.h> // have need of sleep
# include <stdlib.h>
# include <stdint.h>

@ Here is a structure to keep track of the state of things.

 @<Types@>=
typedef struct {
    uint8_t count;
    } statestruct;


@ @<Prototypes@>=
void jawcntl(uint8_t state); // Jaw open and close
void fuelcntl(uint8_t state); // Fuel on and off
void igncntl(uint8_t state); // on and off
void fireseq(statestruct *);
void releaseseq(statestruct *);

@
My lone global variable is a function pointer.
This lets me pass arguments to the actual interrupt handlers.
This pointer gets the appropriate function attached by one of the |"ISR()"|
functions.

@<Global var...@>=
void (*handleirq)(statestruct *) = NULL;


@
Here is |main()|.
@c

int main(void)
{@#

@ The prescaler is set to clk/16484 by |@<Initialize the timer@>|.
With |"F_CPU"| at 8~MHz, the math goes: $\lfloor{0.5 seconds \times (8 \times 10^6 \over 16384}\rfloor = 244$.
Then, the remainder is $256-244 = 12$, thus leaving 244 counts or about 500 ms until time-out, unless it's reset.

@c

statestruct s_state;

@<Initialize pin inputs@>
@<Initialize pin outputs@>

@
@c
  jawcntl(CLOSE); /* PB0 */
  fuelcntl(OFF);  /* PB1 */
  igncntl(OFF);   /* PB2 */

@
Here the timer is setup.
@c
@<Initialize the timer@>


@
Of course, any interrupt function requires that bit ``Global Interrupt Enable''
is set; usually done through calling sei().
@c
  sei();
@
Rather than burning loops, waiting 16~ms for something to happen,
the ``sleep'' mode is used.
The specific type of sleep is `idle'.
In idle, execution stops but timers continue.
Interrupts are used to wake it.
@c
@<Configure to wake upon interrupt...@>


@
This is the loop that does the work.
It should spend most of its time in |sleep_mode|,
comming out at each interrupt event.

@c
 for (;;)
  {@#

@
Now we wait in ``idle'' for any interrupt event.
@c
  sleep_mode();

@
If execution arrives here, some interrupt has been detected.
@c
if (handleirq != NULL)  // not sure why it would be, but to be safe
   {@#
    handleirq(&s_state); // process the irq through it's function
    handleirq = NULL; // reset so that the action cannot be repeated
    }// end if handleirq
@#
  } // end for
@#

return 0; // it's the right thing to do!
@#
} // end main()

@* Interrupt Handling.

@c
void releaseseq(statestruct *s_now )
{
@
This sequence will proceed only while the button is held.
@c
while(!(PORTB & (1<<PORTB3)))
     {

     }



}
@


@c
void fireseq(statestruct *s_now )
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

firingstate = ready;

@
This sequence will proceed only while the button is held.
It can terminate after and state.
@c

while(!(PORTB & (1<<PORTB4)))
     {
      @
      Jaw opens for fire but partly as a warning.
      @c
      if(firingstate == ready)
        {


         firingstate = opened;
         continue;
        }
      @
      Three 250 ms warning blasts from ignitor and then a 1000 ms delay.
      @c
      if(firingstate == opened)
        {

         _delay_ms(250);

         _delay_ms(250);

         _delay_ms(250);

         _delay_ms(1000); /* human duck time */
         firingstate = warned;
         continue;
        }
      @
      Fuel opens for precharge, then 250 ms of delay.
      @c

      if(firingstate == warned)
        {

         _delay_ms(250);
         firingstate = precharged;
         continue;
        }
      @
      Ignitor on, delay for 250 ms.
      @c

      if(firingstate == precharged)
        {

         _delay_ms(250);
         firingstate = igniting;
         continue;
        }
      @
      Ignitor off, and we should have fire now.
      @c
      if(firingstate == igniting)
        {

         firingstate = burning;
         continue;
        }
     }

@
Now set fuel and ignitor off and close jaw.
@c


}



@ The ISRs are pretty skimpy as they are only used to point |handleirq()| to
the correct function.
The need for global variables is minimized.


This is the vector for the main timer.
@c
/* Timer ISR */
ISR(TIMER1_OVF_vect)
{
 handleirq = NULL;
}

@
This vector responds to the jaw input at pin PB3 or fire input at PB4.
@c
ISR(PCINT0_vect)
{

_delay_ms(100); /* relay settle delay */

if(!(PORTB & (1<<PORTB3)))
   handleirq = &releaseseq;
 else
if(!(PORTB & (1<<PORTB4)))
   handleirq = &fireseq;

}


@* These are the supporting routines, procedures and configuration blocks.


Here is the block that sets-up the digital I/O pins.
@ @<Initialize pin outputs...@>=
{
 /* set the jaw port direction */
  DDRB |= (1<<DDB0);
 /* set the fuel port direction */
  DDRB |= (1<<DDB1);
 /* set the ignition port direction */
  DDRB |= (1<<DDB2);
}

@ @<Initialize pin inputs...@>=
{
 /* set the jaw input pull-up */
  PORTB |= (1<<PORTB3);
 /* set the fire input pull-up */
  PORTB |= (1<<PORTB4);
 /* enable  change interrupt for jaw input */
  PCMSK |= (1<<PCINT3);
 /* enable  change interrupt for fire input */
  PCMSK |= (1<<PCINT4);
 /* General interrupt Mask register for clear-button*/
  GIMSK |= (1<<PCIE);
}

@
Here is a simple function to operate the jaw.
@c
void jawcntl(uint8_t state)
{
  PORTB = state ? PORTB | (1<<PORTB0) : PORTB & ~(1<<PORTB0);
}

@
Here is a simple function to operate the fuel.
@c
void fuelcntl(uint8_t state)
{
  PORTB = state ? PORTB | (1<<PORTB1) : PORTB & ~(1<<PORTB1);
}

@
Here is a simple function to operate the ignition.
@c
void igncntl(uint8_t state)
{
  PORTB = state ? PORTB | (1<<PORTB2) : PORTB & ~(1<<PORTB2);
}


@
A very long prescale of 16384 counts is set by setting certain bits in |TCCR1|.

@<Initialize the timer...@>=
{
 TCCR1 = ((1<<CS10) | (1<<CS11) | (1<<CS12) | (1<<CS13)); //Prescale

 TIMSK |= (1<<TOIE1);  /* Timer 1 f\_overflow interrupt enable */

}


@
Setting these bits configure sleep\_mode() to go to ``idle''.
Idle allows the counters and comparator to continue during sleep.

@<Configure to wake upon interrupt...@>=
{
  MCUCR &= ~(1<<SM1);
  MCUCR &= ~(1<<SM0);
}



