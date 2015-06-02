
% jafco

\nocon % omit table of contents
\datethis % print date on listing

@* Introduction. This is the firmware portion of Jaw and Fire control.

This will facilitate two actions: opening the jaw to release the floating
object.
Light the target on fire.

The jaw will close by return-spring so the action will to open it.

Fire is a complex sequence of heating the ignitor, opening the jaw and 
releasing the butane.
About one second will separate each.

place-holder code below
==========================

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
With |"F_CPU"| at 8~MHz, the math goes: $\lfloor{0.5 seconds \times (8 \times 10^6 \over 16384}\rfloor = 244$.
Then, the remainder is $256-244 = 12$, thus leaving 244 counts or about 500 ms until time-out, unless it's reset.

Since |"nowavecount"| is a constant, it must be initialized when declared.

@c
statestruct s_state = {
    .nowavecount = (uint8_t)(256-(NOWAVETIME/1000U)*(F_CPU/16384U))
    };

@
Device pins default as simple inputs so the first thing is to configure to use LED and Siren pins as outputs.
Additionally, we need the clear button to wake the device through an interrupt.
@c
@<Initialize pin outputs and inputs@>

@
The LED is set, meaning `on', assuming that there is an AC signal.
The thought is that it's better to say that there is AC, when there isn't, as opposed to the converse.
@c
  ledcntl(ON);

@
Here the timer is setup.
@c
@<Initialize the no-wave timer@>


@
The Trinket runs at relatively speedy 8 MHz so the slow 60 Hz signal is no issue.
One could use the ADC but that doesn't make too much sense as the input may spend a lot of time clipped.
We just need to know when the signal changes.
The inbuilt comparator seems like the right choice, for now.

@c
 @<Initialize the wave detection@>

@
Of course, any interrupt function requires that bit ``Global Interrupt Enable''
is set; usually done through calling sei().
@c
  sei();
@
Rather than burning loops, waiting 16~ms for something to happen, the ``sleep'' mode is used.
The specific type of sleep is `idle'. In idle, execution stops but timers continue.
Interrupts are used to wake it.
@c
@<Configure to wake upon interrupt...@>


@ Alarm arm delay is in ``nowave'' counts, of a size which is defined by time |"NOWAVETIME"|.
@d ARMTHRESHOLD 1200U // Range to 65535
@c
 s_state.armwait = ARMTHRESHOLD;


@ |"WAVETHRESHOLD"| is the number of waves, that AC must be present to consider it `ON'.
15 counts, or waves; about 250 ms at 60 Hz.
Range is 0 to 255 but don't take too long or the nowave timer will will overflow. Keep in mind that neither clock nor genny frequency is perfect.
@d WAVETHRESHOLD 15U // range maybe to 20, with a 500 ms nowave time
@c
 s_state.wavecount = WAVETHRESHOLD;

@
This is the loop that does the work. It should spend most of its time in |sleep_mode|, comming out at each interrupt event.

@c
 for (;;) // forever
  {@#

@
Now we wait in ``idle'' for any interrupt event.
@c
  sleep_mode();

@
If execution arrives here, some interrupt has been detected.
It could be that a sinewave was detected.
It could be that the NOWAVES timer overflowed, since there have been no sinewaves for an extended period.
It could be that the siren was so annoying that the operator pressed the ``Clear'' button.
Regardless, the respective ISR will have assigned |handleirq()| to the handling funtion.
@c
if (handleirq != NULL)  // not sure why it would be, but to be safe
   {@#
    handleirq(&s_state); // process the irq through it's function
    @<Hold-off all interrupts@>
    handleirq = NULL; // reset so that the action cannot be repeated
    }// end if handleirq
@#
  } // end for
@#

return 0; // it's the right thing to do!
@#
} // end main()

@* Interrupt Handling.
If a wave is detected, it's counted.
Once the counter reaches zero, the light and, if armed, the siren are activated.
Also, the timer for nowave is reset; after all, there is a wave.

|waveaction()| function is called every time there is a wave detected.
@c
void waveaction(statestruct *s_now )
{
 s_now->wavecount =
    (s_now->wavecount)?s_now->wavecount-1:0; // countdown to 0

 if(!s_now->wavecount) // ancillary electric service restored
   {
    ledcntl(ON);

    if(!s_now->armed) chirp(ON); //  annunciate
    s_now->armwait = ARMTHRESHOLD; // reset the arm counter
    TCNT1 = s_now->nowavecount;  // reset the nowave timer
    } // end if wavecount
}

@

If the nowave timer overflows, interrupt |"TIMER1_OVF_vect"| calls the ISR which calls |"nowaveaction()"|.
The LED and siren are turned off.
The waveless counter, |"wavcount"|, is reset.
After some passes, the siren will be armed.

|nowaveaction()| is called when waves have been absent long enough for the timer to expire.
@c
void nowaveaction(statestruct *s_now )
{
 ledcntl(OFF);
 chirp(OFF);  // ASE dropped, stop alarm chirp
 s_now->wavecount = WAVETHRESHOLD; // waveless again

 s_now->armwait = (s_now->armwait)?s_now->armwait-1:0;
                                      // countdown to 0, but not lower
 if(!s_now->armwait) (s_now->armed = SET);
}
@

|clear()| is called whenever the operator presses the clear button.
@c
void clear(statestruct  *s_now )
{
   s_now->armwait = ARMTHRESHOLD;
   s_now->armed = CLEAR;
}


@ The ISRs are pretty skimpy as they are only used to point |handleirq()| to the correct function.
The need for global variables is minimized.


This is the vector for the main timer.
When this overflows it generally means the ASE has been off for as long as it took |TCINT1| to overflow from it's start at |NOWAVETIME|.
@c
/* Timer ISR */
ISR(TIMER1_OVF_vect)
{
 handleirq = &nowaveaction;
}

@
This vector responds to all falling comparator events resulting from ac AC signal at the MUX input. It's expected to fire at line frequency.
@c
/* Comparator ISR */
ISR(ANA_COMP_vect)
{
 handleirq = &waveaction;
}

@
This vector responds to the `Clear' button at pin \#3 or PB3.
@c
/* Clear Button ISR */
ISR(PCINT0_vect)
{
 handleirq = NULL;
}

@* These are the supporting routines, procedures and configuration blocks.


Here is the block that sets-up the digital I/O pins.
@ @<Initialize pin outputs...@>=
{
 /* set the led port direction; This is pin \#1 */
  DDRB |= (1<<DDB1);
 /* set the siren port direction */
  DDRB |= (1<<DDB0);
 /* enable pin change interrupt for clear-button*/
  PCMSK |= (1<<PCINT3);
 /* General interrupt Mask register for clear-button*/
  GIMSK |= (1<<PCIE);
}

@
Siren function will arm after a 10~minute power-loss; that is,
the Trinket is running for about 10~minutes without seeing AC at pin \#2.
Once armed, siren will chirp for 100~ms at a 5~second interval,
only while AC is present. In fact it is called with each AC cycle interrupt so
that |CHIRPLENGTH| and |CHIRPPERIOD| are defined a multiples of ${1 \over Hz}$.
It may be disarmed, stopping the chirp, by pressing the ``clear'' button or a power-cycle.


Chirp parameters for alarm.
These units are of period $1 \over f$ or about 16.6~ms at 60~Hz.
@d CHIRPLENGTH 7 // number of waves long
@d CHIRPPERIOD 200 // number of waves long


@c
void chirp(uint8_t state)
{
static uint8_t count = CHIRPLENGTH;

 count = (count)?count-1:CHIRPPERIOD;
 sirencntl((count > CHIRPLENGTH || state == OFF)?OFF:ON);
}
@


Here is a simple function to flip the LED on or off.
@c
void ledcntl(uint8_t state)
{
  PORTB = state ? PORTB | (1<<PORTB1) : PORTB & ~(1<<PORTB1);
}

@
And the same for the siren.
@c
void sirencntl(uint8_t state)
{
  PORTB = state ? PORTB | (1<<PORTB0) : PORTB & ~(1<<PORTB0);
}

@
A timer is needed to to encompass some number of waves so it can clearly discern off from on. For this ``nowave'' function we use Timer 1.
The timer can trigger an interrupt upon overflow. This is done by setting |TIMSK|.
It could overflow within about $1 \over 2$ second.
Over the course of that time, 25 to 30 comparator interrupts are expected.
When the timer interrupt does occur, the LED is switched off.


Comparator Interrupts are counted and at |WAVETHRESHOLD| this timer is reset and the LED is switched back on.

A very long prescale of 16384 counts is set by setting certain bits in |TCCR1|.

@<Initialize the no-wave timer...@>=
{
 TCCR1 = ((1<<CS10) | (1<<CS11) | (1<<CS12) | (1<<CS13)); //Prescale

 TIMSK |= (1<<TOIE1);  /* Timer 1 f\_overflow interrupt enable */

}


@
The ideal input AN1 (PB1), is connected to the LED in the Trinket!
That's not a big issue since the ADC's MUX may be used.
That MUX may address PB2, PB3, PB4 or PB5. Of those, PB2, PB3 and PB4 are available.
Since PB3 and PB4 are use for USB, PB2 makes sense here.
This is marked \#2 on the Trinket.

PB2 connects the the MUX's ADC1.
Use of the MUX is selected by setting bit ACME of port ADCSRB. ADC1 is set by setting bit MUX0 of register ADMUX


Disable digital input buffers at AIN[1:0] to save power. This is done by
setting AIN1D and AIN0D in register DIDR0.


Both comparator inputs have pins but AIN0 can be connected to a reference of
1.1 VDC, leaving the negative input to the signal. The ref is selected by
setting bit ACBG of register ACSR.


The interrupt can be configured to trigger on rising, falling or toggle (default) by clearing/setting bits ACIS[1:0] also on register ACSR.
There is no need for toggle, and so falling is selected by simply setting ACIS1.


To enable this interrupt, set the ACIE bit of register ACSR.
@<Initialize the wave detection...@>=
{
 ADCSRB |= (1<<ACME); //enable the MUX input ADC1/PB2/pin \#2

 ADMUX |= (1<<MUX0); //set bit MUX0 of register ADMUX
 DIDR0 |= ((1<<AIN1D)|(1<<AIN0D)); // Disable digital inputs
 ACSR |= (1<<ACBG); //Connect the + input to the band-gap reference
 ACSR |= (1<<ACIS1); // Trigger on falling edge only
 ACSR |= (1<<ACIE); // Enable the analog comparator interrupt */
}

@
Setting these bits configure sleep\_mode() to go to ``idle''.
Idle allows the counters and comparator to continue during sleep.

@<Configure to wake upon interrupt...@>=
{
  MCUCR &= ~(1<<SM1);
  MCUCR &= ~(1<<SM0);
}

@
This is the hold-off time in $\mu$s for wave detection. This value is used by the |"_delay_us()"| function here |@<Hold-off all interrupts...@>|.
@d WAVEHOLDOFFTIME 100 // Range to 255


@<Hold-off all interrupts...@>=
{
 /* Disable the analog comparator interrupt */
 ACSR &= ~(1<<ACIE);
 _delay_us(WAVEHOLDOFFTIME);
 /* Enable the analog comparator interrupt */
 ACSR |= (1<<ACIE);
}


