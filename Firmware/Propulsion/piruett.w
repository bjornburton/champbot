
% piruett

\nocon % omit table of contents
\datethis % print date on listing

@* Introduction. This is the firmware portion of the propulsion system for our
Champbot.
It features separate thrust and steering as well as piruett turning.

This will facilitate motion by taking "thrust" and "turn" pulse-width inputs
from the Futaba RC receiver by converting them to the appropriate motor actions.
These are from Channel 2 at A1 and channel 1 at A0, respectivily.
The action will be similar to driving an RC car or boat.
By keeping it natural, it should be easier to navigate the course than with a
skid-steer style control.

@* Implementation.
Both pulse-width inputs will have some dead-band to allow for full stop.

The pulse-width from the receiver is at 20 ms intervals.
The time ranges from 1000--2000 ms, including trim.
1500~ ms is the width for stopped.
The levers cover $\pm$0.4~ms and the trim covers the balance.

Math for radius...I think this is right:

Where:
 t is track
 r is radius
 v is value
 f is factor

min r is 1 and 255
max r is 128

get this value for v
[1]
[128]
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

The radius control will also be the rotate control, if thrust is zero.

Adding the two signal of input, I need more I/O than the trinket has.
So---I now have a \$10 Pro Trinket with far more capability.
It has an ATmega328.

The ATmega328 has a fancy 16 bit PWM with two comparators, Timer 1.
This has an ``Input Capture Unit'' that may be used for PWC decoding.
PWC being the type of signal from the RC receiver.
That seems like as elegant a solutioni as I will find and it is recommended by
Atmel to use it for this purpose.

One of the other timers will do more than fine for the two motors.

For the PWC measurement, this app note, AVR135, is helpful:
 www.atmel.com/images/doc8014.pdf

In the datasheet, this section is helpful: 16.6.3

The best way to use this nice feature is to
take the PWC signals into the MUX, through the comparator and into the Input
Capture Unit.

An interesting thing about this Futaba receiver is that the pulses are in
series.
The channel two's pulse is first, followed the channel one.
In fact, channel two's fall is perfectly aligned with channel one's rise.
This means that it will be possible to capture all of the pulses.

After the two pulses are captured, there's an 18~ms dead-time before the next
round. That's over 250,000 clock cycles.
This will provide ample time to do math and set the motor PWMs.

First pick the turn, set for a rising edge, wait, grab the time-stamp and set
for falling edge, wait, grab the time-stamp, do modulus subtraction,
switch the MUX, set for rising, reset the ICR, wait, grab the time-stamp, and
do modulus sutraction for the second duration.


Extensive use was made of the datasheet, Atmel
``Atmel-8271I-AVR- ATmega-Datasheet\_10/2014''.

@c
@< Include @>@;
@< Types @>@;
@< Prototypes @>@;
@< Global variables @>@;

@ |"F_CPU"| is used to convey the Trinket Pro clock rate.
@d F_CPU 16000000UL
@d BAUD 9600

@ Here are some Boolean definitions that are used.
@d ON 1
@d OFF 0
@d SET 1
@d CLEAR 0
@d CH2RISE 0
@d CH2FALL 1
@d CH1FALL 2


@ @<Include...@>=
# include <avr/io.h> // need some port access
# include <util/delay.h> // need to delay
# include <avr/interrupt.h> // have need of an interrupt
# include <avr/sleep.h> // have need of sleep
# include <stdlib.h>
# include <stdint.h>

@ Here is a structure type to keep track of the state of output things,
like motor settings.

@<Types@>=
typedef struct {
    uint8_t portOut;
    uint8_t starboardOut;
    int32_t thrust;
    int32_t turn;
    uint8_t failSafe; // safety relay
    } outputStruct;


@ Here is a structure type to keep track of the state of input things,
like servo timing.

@<Types@>=
typedef struct {
    uint16_t ch2rise;
    uint16_t ch2fall;
    uint16_t ch1fall;
    uint16_t ch1duration;
    uint16_t ch2duration;
    uint8_t  edge;
    } inputStruct;

@ Here is a structure type to contain the scaling parameters for the scaler
function.


@<Types@>=
typedef struct {
    uint16_t minIn;
    uint16_t maxIn;
    uint16_t minOut;
    uint16_t maxOut;
    uint8_t  deadBand;
    } scaleStruct;



@ @<Prototypes@>=
void ledcntl(uint8_t state); // LED ON and LED OFF
void pwcCalc(inputStruct *);
void edgeSelect(inputStruct *);
uint16_t scaler(scaleStruct *, uint16_t input);
void translate();
void setPwm();

@
My lone global variable is a function pointer.
This lets me pass arguments to the actual interrupt handlers.
This pointer gets the appropriate function attached by the |"ISR()"| function.

@<Global var...@>=
void (*handleIrq)(inputStruct *) = NULL;

@
Here is |main()|.
@c

int main(void)
{@#
@
The Futaba receiver leads with channel two, rising edge, so we will start
looking for that by setting |"edge"| to look for a rise on channel 2.
@c

inputStruct input_s = {
    .edge = CH2RISE
    };

outputStruct output_s;


@
Center reports about 21250, hard left, or up, with trim reports about 29100
and hard right, or down, with trim reports about 13400.

About 4/5ths of that range are the full swing of the stick, without trim.
This is from about 14970 and 27530 ticks.

This |"scale_s"| structure holds the parameters used in the scaler function.
The |"In"| numbers are raw from the Input Capture Register.

At some point a calibration feature could be added which could populate these
but the numbers here were from trial and error.
@c

scaleStruct scale_s = {
    .minIn = 14970, // ticks for hard right or down
    .maxIn = 27530, // ticks for hard left or up
    .minOut = 1,
    .maxOut = 255,
    .deadband = 5
    };

@#
@<Initialize the inputs and capture mode...@>
@<Initialize pin outputs...@>
@#
@
Of course, any interrupt function requires that bit ``Global Interrupt Enable''
is set; usually done through calling sei().
@c
  sei();
@#
 { // for test purposes
  DDRD &= ~(1 << DDD3);     // Clear the PD3 pin
  // PD3 (PCINT0 pin) is now an input

  PORTD |= (1 << PORTD3);    // turn On the Pull-up
  // PD3 is now an input with pull-up enabled


  EICRA |= (1 << ISC10);    // set INT1 to trigger on ANY logic change
  EIMSK |= (1 << INT1);     // Turns on INT1
 }

@
Rather than burning loops, waiting the ballance of 18~ms for something to
happen, the ``sleep'' mode is used.
The specific type of sleep is `idle'.
In idle, execution stops but timers continue.
Interrupts are used to wake it.

It's important to note that an ISR procedure must be defined to allow the
program to step past the sleep statement.
@c

@<Configure to idle on sleep...@>
@#
ledcntl(OFF);

edgeSelect(&input_s);

@
This is the loop that does the work. It should spend most of its time in
|sleep_mode|, comming out at each interrupt event caused by an edge.

@c


 for (;;)
  {@#

@
Now that a loop is started, we wait in ``idle'' for the edge on the channel selected.
@c

 sleep_mode(); // idle

@
If execution arrives here, some interrupt has woken it from sleep and some
vector has possibly run.
The pointer handleIrq will be assigned the value of the responsible function.
@c
if (handleIrq != NULL) // in case it woke for some other reason
   {@#
    handleIrq(&input_s);
    handleIrq = NULL; // reset so that the action cannot be repeated
    }// end if handleirq



output_s.turn =   scaler(&scale_s, input_s.ch1duration);
output_s.thrust = scaler(&scale_s, input_s.ch2duration);


if(output_s.turn >=255 )
    ledcntl(ON);
 else
    ledcntl(OFF);

@#
  } // end for
@#


return 0; // it's the right thing to do!
@#
} // end main()

@
Here are the ISRs.
@c

ISR (INT1_vect)
{@#
}

ISR (TIMER1_CAPT_vect)
{@#
handleIrq = &pwcCalc;
}

@
This procedure computes the durations from the PWC signal edge capture values
from the Input Capture Unit.
With the levers centered the durations should be about 1.5~ms so at 16~ Mhz
the count should be near 24000.
The range should be 17600 to 30400 for 12800 counts, well within the range
of the 64 kib of the 16 bit register..


@c
void pwcCalc(inputStruct *input_s)
{@#
@
On the falling edges we can compute the durations using modulus subtraction
and then set the edge index for the next edge.
Channel 2 leads so that rise is first.
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
     }

edgeSelect(input_s);
@#
}


@

The procedure edgeSelect configures the Input Capture unit to capture on the
expected edge type.

@c
void edgeSelect(inputStruct *input_s)
{@#

  switch(input_s->edge)
     {
   case CH2RISE: // wait for rising edge on servo channel 2
      ADMUX |= (1<<MUX0); // Set to mux channel 1
      TCCR1B |= (1<<ICES1);  // Rising edge (23.3.2)
    break;
   case CH2FALL:
      ADMUX |= (1<<MUX0); // Set to mux channel 1
      TCCR1B &= ~(1<<ICES1);  // Falling edge (23.3.2)
    break;
   case CH1FALL:
      ADMUX &= ~(1<<MUX0); // Set to mux channel 0
      TCCR1B &= ~(1<<ICES1);  // Falling edge (23.3.2)
   }
@
Since the edge has been changed, the Input Capture Flag should be cleared.
It's odd but clearing it involves writing a one to it.
@c

 TIFR1 |= (1<<ICF1); // (per 16.6.3)
@#
}


@
Here is a simple procedure to flip the LED on or off.
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
 /* set the led port direction; This is pin \#17 */
  DDRB |= (1<<DDB5);
}

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
The scaler function takes an input, as in times from the Input Capture
Register and returns a value scaled by the parameters in structure |"scale_s"|.
@c
uint16_t scaler(scaleStruct *scale_s, uint16_t input)
{@#

@
First, we can solve for the obvious cases in which the input exceeds the range.
This can easily happen if the trim is shifted.
@c
  if (input > scale_s->maxIn)
     return scale_s->maxOut;
  else
  if (input < scale_s->minIn)
     return scale_s->minOut;

@
If it's not that simple, then compute the gain and offset then continue in the usual way.
This is not really an effecient method, recomputing gain and offset every time
but we are not in a rush and it makes it easier since, if something changes,
I don't have to manualy compute and enter these values and the code is all in
one place.

The constant  100 amplifies it so I can take advantage of the extra bits for
precision.
@c


int32_t gain = (100L*(int32_t)(scale_s->maxIn-scale_s->minIn))/
                    (int32_t)(scale_s->maxOut-scale_s->minOut);

int32_t offset = ((100L*(int32_t)scale_s->minIn)/gain)-(int32_t)scale_s->minOut;


return (100L*(int32_t)input/gain)-offset;

}

@
We need a way to translate |"thrust"| and |"radius"| in order to carve a
 |"turn"|. This function should do this.
It's not going to be perfect, since thrust isn't speed, but it should be close.
@c

int translate(int16_t thrust, int16_t radius)                                   
{                                                                               
//psudocode placeholder
int16_t track = (int16_t)rand()%256;  //    1 to 255                            
int16_t rotation;     // -255 to 255                                            
int16_t star;         // -255 to 255                                            
int16_t port;         // -255 to 255                                            
const int16_t max = (98*UINT8_MAX)/100; // max is 98\%                          
const int16_t ampFact = INT8_MAX; // factor for precision                       
                                                                                
rotation = (track * ((thrust*((ampFact*radius)/UINT8_MAX))/ampFact))/INT8_MAX;  
                                                                                
                                                                                
if((thrust-rotation) >= max)                                                    
   port=max;                                                                    
else if((thrust-rotation) <= -max)                                              
   port=-max;                                                                   
else                                                                            
   port=thrust-rotation;                                                        
                                                                                
                                                                                
if((thrust+rotation) >= max)                                                    
   star=max;                                                                    
else if ((thrust+rotation) <= -max)                                             
   star = -max;                                                                 
else                                                                            
   star=thrust+rotation; 


}
