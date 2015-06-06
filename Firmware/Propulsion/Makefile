# Project Name
TARGET:= piruett

# Which target board
# for Trinket use BOARD:=trinket
# for Pro Trinket use 
BOARD:=atmega328p

# Which microcontroller
MCU:=atmega328p

# Which programmer to use
PROGHW:=usbtiny

# Which avrdude to use
PROGSW:=avrdude

# Which fuses
LFUSE:= lfuse:w:0xFF:m
HFUSE:= hfuse:w:0xD0:m 
EFUSE:= efuse:w:0x05:m


# Apps and Flags
PROGSWFLAGS:= -c $(PROGHW) -p $(BOARD)
CC       := avr-gcc 
TANGLE   := ctangle
WEAVE    := cweave
TEX      := pdftex
CFLAGS   :=  -std=c99 -g -mmcu=$(MCU) -Wall -Os -pedantic
CONV     :=avr-objcopy
CONVFLAGS:= -j .text -j .data -O ihex
LIBS     :=

# Build filenames
HEADERS := $(TARGET).h
OBJECTS := $(TARGET).o
HEX     := $(TARGET).hex
ELF     := $(TARGET).elf
CSOURCES:= $(TARGET).c
WEB     := $(TARGET).w
DOC     := $(TARGET).pdf
TEXSRC  := $(TARGET).tex


# The usual make stuff
default: $(HEX)
elf: $(ELF)
all: default

$(CSOURCES): $(WEB)
	$(TANGLE) $(WEB)
	$(WEAVE) $(WEB)
	$(TEX) $(TEXSRC) 

$(OBJECTS): $(CSOURCES)
	$(CC) -c $(CFLAGS) $(CSOURCES)

$(ELF): $(OBJECTS)
	$(CC) $(LIBS) $(OBJECTS) $(CFLAGS) -o $(ELF)
	chmod -x $(ELF)

$(HEX): $(ELF)
	$(CONV) $(CONVFLAGS) $(ELF) $(HEX) 

clean:
	-rm -f $(OBJECTS)
	-rm -f $(ELF)
	-rm -f $(TEXSRC)
	-rm -f $(CSOURCES)
	-rm -f $(CSOURCES)
	
install:
	$(PROGSW) $(PROGSWFLAGS) -U flash:w:$(HEX)

size:
	avr-size --format=avr --mcu=$(MCU) $(ELF)

fuse:
	$(PROGSW) $(PROGSWFLAGS) -u -U $(LFUSE)  -U $(HFUSE) -U $(EFUSE)
 
