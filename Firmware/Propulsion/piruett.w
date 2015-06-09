
% piruett

\nocon % omit table of contents
\datethis % print date on listing

@* Introduction. This is the firmware portion of the propulsion system,
featuring piruett turning. 

This will facilitate motion by taking "thrust" and "radius" pulse-width
inputs and converting them to the appropriate motor actions.

Both pulse-width inputs will have some dead-band to allow for full stop.

The pulse-width from the receiver is at 20 ms intervals.
The time ranges from 1000--2000 ms, including trim.
1500 ms is the width for stopped.
The levers cover \pm0.4 ms and the trim
covers the balance.

Math for radius...I think this ir right:

Where:
 t is track
 r is radius
 v is value
 f is factor

min r is 1
max r is 127

get this value for v
[1]
[127]
[255]

r=factor*abs(127-v)


For non-zero r
Inside=(2r-t)/2r
Outside=(2r+t)/2r


Port motor pulse will be applied to ???, starboard will be at ???.
The median time will be subtracted from them for a pair of signed values
thrust and radius. The value will be scaled.

The thrust and radius will be translated to power to the
port and starboard motors. When near median the motors will be disabled.
The motors will also be disabled when there are no input pulses.
Each motor need direction and power so that's 4 signals of output.

The redius controll will also be the rotate control, if thrust is zero.

Adding the two signal of input, I need more I/O than the trinket has.
So---I now have a \$10 Pro Trinket with far more capability.
It has an ATmega328.

The ATmega328 has a fancy 16 bit PWM with two comparators, Timer 1.
This has an "Input Capture Unit" that may be used for PWC decoding.
That's an elegant solution



One of the other timers will do more than fine for the two motors.

For the PWC measurement, this app note, AVR135, is helpful:
 www.atmel.com/images/doc8014.pdf

In the datasheet, this section is helpful: 16.6.3

Since I have two signals, maybe the best way to use this nice feature is to
take the PWC signals into the MUX, through the comparator and into the Input
Capture Unit. 
First pick the thrust, set for a rising edge, wait, grab the time-stamp and set
for falling edge, wait, grab the time-stamp, do the math, switch the MUX, set
for rising, reset the ICR, wait...
MUX switch timing can be through another timer. 
I'll ponder a bit.
 



place-holder code below
==========================

Extensive use was made of the datasheet, Atmel ``Atmel ATtiny25, ATtiny45, ATtiny85 Datasheet'' Rev. 2586Q–AVR–08/2013 (Tue 06 Aug 2013 03:19:12 PM EDT).
@c
@< Include @>@;
@< Types @>@;
@< Prototypes @>@;


@ |"F_CPU"| is used to convey the Trinket clock rate.
@d F_CPU 16000000UL


@ Here are some Boolean definitions that are used.
@d ON 1
@d OFF 0
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
    uint8_t wavecount; // delay to remain as if waveless, to ensure waves
    uint16_t armwait; // countdown index to arm siren
    uint8_t armed; // non-zero indicates that the siren is armed
    const uint8_t nowavecount; // time until siren arm
    } statestruct;


@ @<Prototypes@>=
void ledcntl(uint8_t state); // LED ON and LED OFF

@
Here is |main()|.
@c

int main(void)
{@#

@<Initialize pin outputs and inputs@>

ledcntl(OFF);


return 0; // it's the right thing to do!
@#
} // end main()

@
Here is a simple function to flip the LED on or off.
@c
void ledcntl(uint8_t state)
{
  PORTB = state ? PORTB | (1<<PORTB5) : PORTB & ~(1<<PORTB5);
}

@

@* These are the supporting routines, procedures and configuration blocks.


Here is the block that sets-up the digital I/O pins.
@ @<Initialize pin outputs...@>=
{
 /* set the led port direction; This is pin \#13 */
  DDRB |= (1<<DDB5);
}
