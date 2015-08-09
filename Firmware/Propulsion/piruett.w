
% piruett
%\input graphicx.tex
\input miniltx
\input graphicx

\nocon % omit table of contents
\datethis % print date on listing

@* Introduction. This is the firmware portion of the propulsion system for our
Champbot.
It features separate thrust and steering as well as piruett turning.

This will facilitate motion by taking ``thrust'' and ``radius'' pulse-width,
or PWC, inputs from the Futaba-Kyosho RC receiver and converting them to the
appropriate motor actions.
Thrust is Channel 2, entering analog input A1, and Radius is channel 1, at A0.
The action will be similar to driving an RC car or boat.
By keeping it natural, it should be easier to navigate the course than with a
skid-steer style control.

We are using the Wingxing DBH-01 (B/C).
The Inputs are unique on this as the PWM logic input is a two bit value applied
at terminals IN1 and IN2.
Taking IN1 as LSb and IN2 as MSb values 0 and 3 are logic LOW for the PWM.
A value of 1 is logic high in one direction and a value of 2 is logic high in
the other.

The odd example in the datasheet has PWM on IN1 and LOW on IN2 for forward.
For reverse, LOW on IN1 and PWM on IN2.
We don't want PWM hopping between pins so we keep PWM on IN1.
The result of this mode is that PWM as IN1 is inverted when IN2 is HIGH.
This means we need to invert the PWM when the direction pin goes HIGH.

The larboard motor PWM word will be available at Pins 3 and 5.
The starboard motor PWM word will be at 4 and 6.
OC0A and OC0B is on pins 5 and 6  (D8 and D6) and are the PWM.
A fail-safe relay output will be at pin 8.

@* Implementation.
The Futaba receiver has two PWC channels.
The pulse-width from the receiver is at 20~ms intervals.
The on-time ranges from 1000--2000~$\mu$s including trim.
1500~$\mu$s is the pulse-width for stop.
The levers cover $\pm$400~$\mu$s and the trim covers the last 100~$\mu$s.

The median time will be subtracted from them for a pair of signed values
thrust and radius. The value will be scaled.

The thrust and radius will be translated to power to the
port and starboard motors.
When near median the motors will be disabled through a dead-band.
Stiction in the motor probably wouldn't allow it to move anyway, at this low
duty-cycle. Both the PWM and safety relay will open.
The motors will also be disabled when there are no input pulses; in this way
champ wont run-off if the range is exceeded. This function is handled by the
watchdog timer.

The radius control will also be the rotate control, if thrust is zero.
Timer-Counter 0 is used for the PWM.

The ATmega328 has a 16 bit PWMs with two comparators, Timer 1.
This has an ``Input Capture Unit'' that may be used for PWC decoding.
PWC being the type of signal from the RC receiver.
That seems like as elegant a solution as I will find and it is recommended by
Atmel to use it for this purpose.

The best way to use this nice feature is to
take the PWC signals into the MUX, through the comparator and into the Input
Capture Unit.

For the PWC measurement, this app note, AVR135, is helpful:
 www.atmel.com/images/doc8014.pdf


In the datasheet, this section is helpful: 16.6.3

An interesting thing about this Futaba receiver is that the pulses are in
series.
The channel two's pulse is first, followed the channel one.
In fact, channel two's fall is perfectly aligned with channel one's rise.
This means that it will be possible to capture all of the pulses.

After the two pulses are captured, there's an 18~ms dead-time before the next
round. That's over 250,000 clock cycles.
This will provide ample time to do math and set the motor PWMs.


Extensive use was made of the datasheet, Atmel
``Atmel-8271I-AVR- ATmega-Datasheet\_10/2014''.


\includegraphics[width=35 pc]{piruett.png}

I originaly wanted to use the word "Port" for the left-hand side, when facing
the front. On a microcontroller that name is used for all of the ports so I
chose the older word ``larboard''.

@c
@< Include @>@;
@< Types @>@;
@< Prototypes @>@;
@< Global variables @>@;

@ |"F_CPU"| is used to convey the Trinket Pro clock rate.
@d F_CPU 16000000UL

@ Here are some Boolean definitions that are used.
@d ON 1
@d OFF 0
@d SET 1
@d CLEAR 0
@d TRUE  1
@d FALSE 0
@d FORWARD 1
@d REVERSE 0
@d CLOSED 1
@d OPEN 0
@d STOPPED 0

@ Here are some other definitions.
@d CH2RISE 0
@d CH2FALL 1
@d CH1FALL 2
@d MAX_DUTYCYCLE 98 // 98\% to support charge pump of bridge-driver

@ @<Include...@>=
# include <avr/io.h> // need some port access
# include <avr/interrupt.h> // have need of an interrupt
# include <avr/sleep.h> // have need of sleep
# include <avr/wdt.h> // have need of watchdog
# include <stdlib.h>
# include <stdint.h>

@ Here is a structure type to keep track of the state of remote-control
input, e.g. servo timing. Rise and Fall indicate the PWC edges.
|"edge"| is set to the edge type expected for the interrupt.

@<Types@>=
typedef struct {
    uint16_t ch2rise;
    uint16_t ch2fall;
    uint16_t ch1fall;
    uint16_t ch1duration;
    uint16_t ch2duration;
    uint8_t  edge;
    uint8_t  lostSignal;
    const uint16_t minIn;    // input, minimum
    const uint16_t maxIn;    // input, maximum
    } inputStruct;

@ Here is a structure type to keep track of the state of translation items.
@<Types@>=
typedef struct {
    int16_t thrust;         // -255 to 255
    int16_t radius;         // -255 to 255
    int16_t track;          //    1 to 255
    int16_t starboardOut;   // -255 to 255
    int16_t larboardOut;    // -255 to 255
    const int16_t minOut;   // output, minimum
    const int16_t maxOut;   // output, maximum
    const int8_t  deadBand; // width of zero in terms of output units
   } transStruct;


@ @<Prototypes@>=
void relayCntl(int8_t state);
void ledCntl(int8_t state);
void larboardDirection(int8_t state);
void starboardDirection(int8_t state);
void pwcCalc(inputStruct *);
void edgeSelect(inputStruct *);
int16_t scaler(inputStruct *, transStruct *, uint16_t input);
void translate(transStruct *);
void setPwm(transStruct *);
void lostSignal(inputStruct *);

@
My lone global variable is a function pointer.
This lets me pass arguments to the actual interrupt handlers.
This pointer gets the appropriate function attached by the |"ISR()"| function.

This input structure is to contain all of the external inputs.

@<Global var...@>=
void (*handleIrq)(inputStruct *) = NULL;

@#

int main(void)
@#{@#

@
The Futaba receiver leads with channel two, rising edge, so we will start
looking for that by setting |"edge"| to look for a rise on channel 2.

Center position of the controller results in a count of about 21250,
hard left, or up, with trim reports about 29100 and hard right, or down,
 with trim reports about 13400.

About 4/5ths of that range are the full swing of the stick, without trim.
This is from about 14970 and 27530 ticks.

|".minIn"| |".maxIn"| are the endpoints of the normal stick travel.
The units are raw counnts as the Input Capture Register will use.

At some point a calibration feature could be added which could populate these
but the numbers here were from trial and error and seem good.

Until we have collected the edges we will assume there is no signal.
@c

inputStruct input_s = {
    .edge = CH2RISE,
    .minIn = 14970,
    .maxIn = 27530,
    .lostSignal = TRUE
    };


@
This is the structure that holds output parameters.
It's instantiated with the endpoint constants.
@c
transStruct translation_s = {
    .minOut = -255,
    .maxOut = 255,
    .deadBand = 10
    };

@
Here the interrupts are disabled so that configuring them doesn't set it off.
@c
 cli();
@#
@<Initialize the inputs and capture mode...@>
@<Initialize pin outputs...@>
@<Initialize watchdog timer...@>
@#
@
Any interrupt function requires that bit ``Global Interrupt Enable''
is set; usually done through calling |"sei()"|.
@c
  sei();
@#

@

The PWM is used to control larboard and starboard motors through OC0A (D5) and
OC0B (D6), respectivly.
@c
@<Initialize the Timer Counter 0 for PWM...@>


@
Rather than burning loops, waiting the ballance of 18~ms for something to
happen, the |"sleep"| mode is used.
The specific type of sleep is |"idle"|.
In idle, execution stops but timers, like the Input Capture Unit and PWM
continue to operate.
Interrupts, either |Input Capture| or |Watchdog|,  are used to wake it up.

It's important to note that an ISR procedure must be defined to allow the
program to step past the sleep statement, even if it is empty.
This stumped me for a good while.
@c

@<Configure to idle on sleep...@>
@#

ledCntl(OFF);

@
Since |"edge"| is already set, calling |edgeSelect()| will get it ready for
the first rising edge of channel~2.
Subsequent calls to |edgeSelect| rotates it to the next edge type.
@c
edgeSelect(&input_s);

@
This is the loop that does the work.
It should spend most of its time in ``sleep\_mode'', comming out at each
interrupt event caused by an edge or watchdog timeout.
@c


 for (;;)
  {@#

@
Now that a loop is started, the PWM is value and we wait in
|"idle"| for the edge on the channel selected. Each sucessive loop will finish
in the same way.
After three passes |"translation_s"| will have good values.

@c
 setPwm(&translation_s);

 sleep_mode();

@
If execution arrives here, some interrupt has woken it from sleep and some
vector has possibly run. The possibility is first checked.
The pointer |"handleIrq"| will be assigned the value of the responsible
function and then executed.
After that the IRQ is nulled so as to avoid repeating the action, should it
wake for some other reason.


@c
if (handleIrq != NULL)
   {@#
    handleIrq(&input_s);
    handleIrq = NULL;
    }



translation_s.radius = scaler(&input_s, &translation_s, input_s.ch1duration);
translation_s.thrust = scaler(&input_s, &translation_s, input_s.ch2duration);
translation_s.track = 100; /* represents unit-less prop-to-prop distance */

translate(&translation_s);

@
The LED is used to indicate both channels PWM's are zeros.
@c
if(translation_s.larboardOut || translation_s.starboardOut)
    ledCntl(OFF);
 else
    ledCntl(ON);

@#
  } /* end for */
@#


return 0;
@#
}@# /* end main() */


@* Supporting routines, functions, procedures and configuration
blocks.


@
Here is the ISR that fires at each captured edge.
Escentialy it grabs and processes the |Input Capture| data.
@c

ISR (TIMER1_CAPT_vect)
@#{@#
 handleIrq = &pwcCalc;
@#}@#

@
This is a variant of |pwcCalc| that only flips the |lostSignal| flag.
@c
ISR (WDT_vect)
@#{@#
 handleIrq = &lostSignal;
@#}@#

@
This procedure computes the durations from the PWC signal edge capture values
from the Input Capture Unit.
With the levers centered the durations should be about 1500~$\mu$s so at
16~Mhz the count should be near 24000.
The range should be 17600 to 30400 for 12800 counts, well within the range
of the 64 kib of the 16 bit register..


@c
void pwcCalc(inputStruct *input_s)
@#{@#
@
On the falling edges we can compute the durations using modulus subtraction
and then set the edge index for the next edge.
Channel 2 leads so that rise is first.

Arrival at the last case establishes that there was a signal and clears
the flag and resets the watchdog timer.
@c


 switch(input_s->edge)
     {
      case CH2RISE:
         input_s->ch2rise = ICR1;
         input_s->edge = CH2FALL;
       break;
      case CH2FALL:
         input_s->ch2fall = ICR1;
         input_s->ch2duration = input_s->ch2fall - input_s->ch2rise;
         input_s->edge = CH1FALL;
       break;
      case CH1FALL:
         input_s->ch1fall = ICR1;
         input_s->ch1duration = input_s->ch1fall - input_s->ch2fall;
         input_s->edge = CH2RISE;
         input_s->lostSignal = FALSE;
         wdt_reset(); /* watchdog timer is reset at each edge capture */
@t\hskip 1in@>  }

edgeSelect(input_s);
@#}@#

@
This procedure sets output to zero in the event of a lost signal.
@c
void lostSignal(inputStruct *input_s)
@#{@#
 input_s->lostSignal = TRUE;
 input_s->edge = CH2RISE;

 edgeSelect(input_s);
@#}@#

@

The procedure edgeSelect configures the |"Input Capture"| unit to capture on
the expected edge type.

@c
void edgeSelect(inputStruct *input_s)
@#{@#

  switch(input_s->edge)
     {
   case CH2RISE: /* To wait for rising edge on servo-channel 2 */
      ADMUX |= (1<<MUX0); /* Set to mux channel 1 */
      TCCR1B |= (1<<ICES1);  /* Rising edge (23.3.2) */
    break;
   case CH2FALL:
      ADMUX |= (1<<MUX0); /* Set to mux channel 1 */
      TCCR1B &= ~(1<<ICES1);  /* Falling edge (23.3.2) */
    break;
   case CH1FALL:
      ADMUX &= ~(1<<MUX0); /* Set to mux channel 0 */
      TCCR1B &= ~(1<<ICES1);  /* Falling edge (23.3.2) */
   }
@
Since the edge has been changed, the Input Capture Flag should be cleared.
It seems odd but clearing it involves writing a one to it.
@c

 TIFR1 |= (1<<ICF1); /* (per 16.6.3) */
@#}@#


@
Here is a simple procedure to flip the LED on or off.
@c
void ledCntl(int8_t state)
@#{@#
  PORTB = state ? PORTB | (1<<PORTB5) : PORTB & ~(1<<PORTB5);
@#}@#

@
Here is a simple procedure to flip the Relay Closed or Open from pin \#8.
@c
void relayCntl(int8_t state)
@#{@#
 PORTB = state ? PORTB | (1<<PORTB0):PORTB & ~(1<<PORTB0);
@#}@#

@
Here is a simple procedure to set thrust direction on the larboard motor.
Direction is effectivly the MSb of the two bit value at the H-bridge. 
In forward, the PWM value is 2 for high and 3 for low.
In reverse, the PWM value is 1 for high and 0 for low.
The LSb is the PWM itself.
@c
void larboardDirection(int8_t state)
@#{@#
 if(state)
    PORTD |= (1<<PORTD3);
  else
    PORTD &= ~(1<<PORTD3);

@#}@#

@
Here is a simple procedure to set thrust direction on the starboard motor.
Direction is effectivly the MSb of the two bit value at the H-bridge. 
In forward, the PWM value is 2 for high and 3 for low.
In reverse, the PWM value is 1 for high and 0 for low.
The LSb is the PWM itself.
@c
void starboardDirection(int8_t state)
@#{@#
 if(state)
    PORTD |= (1<<PORTD4);
  else
    PORTD &= ~(1<<PORTD4);
@#}@#

@

@
The scaler function takes an input, in time, from the Input Capture
Register and returns a value scaled by the parameters in structure
|"inputScale_s"|.
@c
int16_t scaler(inputStruct *input_s, transStruct *trans_s, uint16_t input)
@#{@#
uint16_t solution;
@
First, we can solve for the obvious cases.
One is where there is no signal; when |"lostSignal"| is |"TRUE"|.
The other is where the input exceeds the range.
This can easily happen if the trim is shifted.
@c
  if (input_s->lostSignal == TRUE)
     return 0;

  if (input > input_s->maxIn)
     return trans_s->maxOut;

  if (input < input_s->minIn)
     return trans_s->minOut;


@
If it's not that simple, then compute the gain and offset and then continue in
the usual way.
This is not really an efficient method, recomputing gain and offset every time
but we are not in a rush and it makes it easier since, if something changes,
I don't have to manualy compute and enter these value.

The constant |"ampFact"| amplifies it so I can take advantage of the extra
bits for precision.

Dead-band is applied when it returns.
@c
const int32_t ampFact = 128L;

int32_t gain = (ampFact*(int32_t)(input_s->maxIn-input_s->minIn))/
                    (int32_t)(trans_s->maxOut-trans_s->minOut);

int32_t offset = ((ampFact*(int32_t)input_s->minIn)/gain)
                 -(int32_t)trans_s->minOut;

solution = (ampFact*(int32_t)input/gain)-offset;


return (abs(solution) > trans_s->deadBand)?solution:0;

@#}@#

@
We need a way to translate |"thrust"| and |"radius"| in order to carve a
 |"turn"|. This procedure should do this but it's not going to be perfect as
drag and slippage make thrust increase progressivly more than speed.
Since |speed| is not known, we will use |thrust|.
It should steer OK as long as the speed is constant and small changes in speed
should not be too disruptive.

The constant |"ampFact"| amplifies it so I can take advantage of the extra
 bits.

This procedure is intended for values from -255 to 255.
@c

void translate(transStruct *trans_s)
@#{@#
int16_t speed = trans_s->thrust; /* we are assuming it's close */
int16_t rotation;
int16_t difference;
int16_t piruett;
const int16_t max = (MAX_DUTYCYCLE * UINT8_MAX)/100;
const int16_t ampFact = 128;


@
Here we convert desired radius to thrust-difference by scaling to speed.
Then that difference is converted to rotation by scaling it with |"track"|.
The radius sensitivity is adjusted by changing the value of |"track"|.
@c
 difference = (speed * ((ampFact * trans_s->radius)/UINT8_MAX))/ampFact;
 rotation = (trans_s->track * ((ampFact * difference)/UINT8_MAX))/ampFact;
 piruett = (trans_s->track * ((ampFact * trans_s->radius)/UINT8_MAX))/ampFact;
@
Any rotation involves one motor turning faster than the other.
At some point, faster is not possible and so the requiered clipping is here.

|"max"| is set at to support the limit of the bridge-driver's charge-pump.

If there is no thrust then it is in piruett mode and spins CW or CCW.
@c


 if(trans_s->thrust != STOPPED)
   {
    if((speed-rotation) >= max)
       trans_s->larboardOut = max;
     else if((speed-rotation) <= -max)
       trans_s->larboardOut = -max;
     else
       trans_s->larboardOut = speed-rotation;

    if((speed+rotation) >= max)
       trans_s->starboardOut = max;
     else if ((speed+rotation) <= -max)
       trans_s->starboardOut = -max;
     else
       trans_s->starboardOut = speed+rotation;
    }
  else /* piruett mode */
   {
    trans_s->larboardOut = -piruett;
    trans_s->starboardOut = piruett;
    }

@#}@#

@
This simple procedure sets the signal to the H-Bridge.
The MSb at termonal IN1 sets the direction.
The LSb is the PWM.
For the PWM we load the positive or negative value into the unsigned registers.
If it is negative the PWM is inverted, which happens to work well for this
H-Bridge. 
@c
void setPwm(transStruct *trans_s)
@#{@#

 if (trans_s->larboardOut >= 0)
     larboardDirection(FORWARD);
  else
     larboardDirection(REVERSE);

 if (trans_s->starboardOut >= 0)
     starboardDirection(FORWARD);
  else
     starboardDirection(REVERSE);
     

 OCR0A = (uint8_t)trans_s->larboardOut;
 OCR0B = (uint8_t)trans_s->starboardOut;
@
We must see if the fail-safe relay needs to be closed.
@c
 if (trans_s->larboardOut || trans_s->starboardOut)
    relayCntl(CLOSED);
  else
    relayCntl(OPEN);


@#}@#
@ @<Initialize pin outputs...@>=
 // set the led port direction; This is pin \#17
  DDRB |= (1<<DDB5);


 // set the relay port direction; This is pin \#8
  DDRB |= (1<<DDB0);


 // 14.4.9 DDRD – The Port D Data Direction Register
 // larboard and starboard pwm outputs
  DDRD |= ((1<<DDD5)|(1<<DDD6)); // Data direction to output (sec 14.3.3)

 // larboard and starboard direction outputs
  DDRD |= ((1<<DDD3)|(1<<DDD4)); // Data direction to output (sec 14.3.3)

@ @<Configure to idle on sleep...@>=
{
  SMCR &= ~((1<<SM2) | (1<<SM1) | (1<<SM0));
}

@
To enable this interrupt, set the ACIE bit of register ACSR.
@ @<Initialize the inputs and capture mode...@>=
{
 // ADCSRA – ADC Control and Status Register A
 ADCSRA &= ~(1<<ADEN); // Conn the MUX to (-) input of comparator (sec 23.2)

 // 23.3.1 ADCSRB – ADC Control and Status Register B
 ADCSRB |= (1<<ACME);  // Conn the MUX to (-) input of comparator (sec 23.2)

 // 24.9.5 DIDR0 – Digital Input Disable Register 0
 DIDR0  |= ((1<<AIN1D)|(1<<AIN0D)); // Disable digital inputs (sec 24.9.5)

 // 23.3.2 ACSR – Analog Comparator Control and Status Register
 ACSR   |= (1<<ACBG);  // Connect + input to the band-gap ref (sec 23.3.2)
 ACSR   |= (1<<ACIC);  // Enable input capture mode (sec 23.3.2)
 ACSR   |= (1<<ACIS1); // Set for both rising and falling edge (sec 23.3.2)

 // 16.11.8 TIMSK1 – Timer/Counter1 Interrupt Mask Register
 TIMSK1 |= (1<<ICIE1); // Enable input capture interrupt (sec 16.11.8)

 // 16.11.2 TCCR1B – Timer/Counter1 Control Register B
 TCCR1B |= (1<<ICNC1); // Enable input capture noise canceling (sec 16.11.2)
 TCCR1B |= (1<<CS10);  // No Prescale. Just count the main clock (sec 16.11.2)

 // 24.9.1 ADMUX – ADC Multiplexer Selection Register
 ADMUX &= ~((1<<MUX2) | (1<<MUX1) | (1<<MUX0)); // Set to mux channel 0
}

@
See section 11.8 in the datasheet for details on the Watchdog Timer.
This is in the ``Interrupt Mode''.
@ @<Initialize watchdog timer...@>=
{

 WDTCSR |= (1<<WDCE) | (1<<WDE);
 WDTCSR = (1<<WDIE) | (1<<WDP2); // reset after about 0.25 seconds
}

@
PWM setup isn't too scary.
Timer Count 0 is configured for ``Phase Correct'' PWM which, according to the
datasheet, is preferred for motor control.
OC0A (port) and OC0B (starboard) are set to clear on a match which creates a
non-inverting PWM.
The prescaler is set to clk/8 and with a 16 MHz clock the $f$ is about 3922 Hz.
@ @<Initialize the Timer Counter 0 for PWM...@>=
{
 // 15.9.1 TCCR0A – Timer/Counter Control Register A
 TCCR0A |= (1<<WGM00);  // Phase correct, mode 1 of PWM (table 15-9)
 TCCR0A |= (1<<COM0A1); // Set/Clear on Comparator A match (table 15-4)
 TCCR0A |= (1<<COM0B1); // Set/Clear on Comparator B match (table 15-7)
 TCCR0A |= (1<<COM0A0); // Clear on Comparator A match (table 15-4)
 TCCR0A |= (1<<COM0B0); // Clear on Comparator B match (table 15-7)

// 15.9.2 TCCR0B – Timer/Counter Control Register B
 TCCR0B |= (1<<CS01);   // Prescaler set to clk/8 (table 15-9)
}


