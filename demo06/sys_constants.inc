; sys_constants.asm - Johan Smet - BSD-3-Clause (see LICENSE)
;
; constants for C64 memory map locations

.ifndef SYS_CONSTANTS_GUARD
.define SYS_CONSTANTS_GUARD 1

SCREEN_RAM = $0400			; screen memory (1000 bytes)
COLOUR_RAM = $d800			; color memory (1000 bytes, only lower 4 bits are used) 

CIA1_PRA  = $dc00			; CIA-1: port register A
CIA1_PRB  = $dc01			; CIA-1: port register B
CIA1_DDRA = $dc02			; CIA-1: data direction register for port A
CIA1_DDRB = $dc03			; CIA-1: data direction register for port B
CIA1_ICSR = $dc0d			; CIA-1: Interrupt control and status register

CIA2_ICSR = $dd0d			; CIA-2: Interrupt control and status register

VIC2_SCR = $d011			; VIC-II: screen control register (bit #7 == bit #8 for $d012)
VIC2_RASLN = $d012			; VIC-II: r=current raster line / w=raster line to generate interrupt at
VIC2_ISR = $d019			; VIC-II: interrupt status register
VIC2_ICR = $d01a			; VIC-II: interrupt control register
VIC2_BORCLR = $d020			; VIC-II: Border color
VIC2_BCKCLR = $d021			; VIC-II: Background color

ISR_LO = $0314				; Execution address of interrupt service routine
ISR_HI = $0315

KERNAL_IRQFUL = $ea31		; entire kernal's standard interrupt service routine (incl. keyboard)
KERNAL_IRQEND = $ea81		; final part of the kernal's standard interrupt service routine 

.endif ; SYS_CONSTANTS_GUARD

