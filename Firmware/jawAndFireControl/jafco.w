
% jafco

\nocon % omit table of contents
\datethis % print date on listing

@* Introduction. This is the firmware portion of Champbots Jaw and Fire Control
or jafco.

This sequences the ignitor, gas and jaw for ignition as well as allows opening 
of the jaw alone.
The hot-wire ignitor needs some voltage less than 12, so output must be
modulated by duty-cycle.
The hot-wire ignitor should be fast so we can probably start the gas flow at
the same time.
Having low latency will be an advantage when tring to hit the target.
Of course, we must ensure that the jaw is open when the fire comes out so there
will be a small delay while the jaw opens.
The ignitor will remain on for the duration the gas-flow.
The duration will be limited to the shorter of 2 seconds or the duration of the
input.
The jaw will delay closing for 1 second after the fire input stops.

There are two digital outputs, one for jaw and other for gas.
There is one duty-cycle output for the ignitor.
There are two digital inputs, for jaw and fire.

@* Implementation and Specification.
here's how it works...

No code yet.

Extensive use was made of the datasheet, Atmel ``Atmel ATtiny25, ATtiny45, ATtiny85 Datasheet'' Rev. 2586Q–AVR–08/2013 (Tue 06 Aug 2013 03:19:12 PM EDT).
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
void sirencntl(uint8_t state); // alarm siren control
void chirp(uint8_t state); // alarm siren modulation
void waveaction(statestruct *); // what is done when a wave is detected
void nowaveaction(statestruct *); // what is done if waves don't come
void clear(statestruct *); // what is done if clear is pressed

@
My lone global variable is a function pointer.
This lets me pass arguments to the actual interrupt handlers.
This pointer gets the appropriate function attached by one of the |"ISR()"| functions.

@<Global var...@>=
void (*handleirq)(statestruct *) = NULL;


@
Here is |main()|.
@c

int main(void)
{@#

@ |"NOWAVETIME"| is the time allowed by the nowave timer to be waveless before arming the siren.

@d NOWAVETIME 500U  // preset ms for the timer counter. This is close to maximum
@ The prescaler is set to clk/16484 by |@<Initialize the no-wave timer@>|.
|"nowavecount"| is the timer preset so that overflow of the 8-bit counter happens in about 500~ms.


