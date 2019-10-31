; demo04/main.asm - Johan Smet - BSD-3-Clause (see LICENSE)

; BASIC loader
*       = $0801							; change program counter to start of BASIC area
        .word (+)						; pointer to next line of basic code
		.word 2005						; current basic line number
        .null $9e, format("%d", start)	; $9e == token for SYS keyword (=> "SYS <start of assembly program> <zero>")
+		.word 0							; end of basic program

*       = $1000

; constants for C64 memory map locations
SCREEN_RAM = $0400			; screen memory (1000 bytes)
COLOUR_RAM = $d800			; color memory (1000 bytes, only lower 4 bits are used) 

CIA1_ICSR = $dc0d			; CIA-1: Interrupt control and status register
CIA2_ICSR = $dd0d			; CIA-2: Interrupt control and status register

VIC2_SCR = $d011			; VIC-II: screen control register (bit #7 == bit #8 for $d012)
VIC2_RASLN = $d012			; VIC-II: r=current raster line / w=raster line to generate interrupt at
VIC2_ISR = $d019			; VIC-II: interrupt status register
VIC2_ICR = $d01a			; VIC-II: interrupt control register
VIC2_BORCLR = $d020			; VIC-II: Border color
VIC2_BCKCLR = $d021			; VIC-II: Background color

ISR_LO = $0314
ISR_HI = $0315

KERNAL_IRQFUL = $ea31		; entire kernal's standard interrupt service routine (incl. keyboard)
KERNAL_IRQEND = $ea81		; final part of the kernal's standard interrupt service routine 

; main routine
start		jsr init_screen
			jsr write_title
			jsr setup_irq
			jmp *			; loop forever

; setup_irq: init interrupt handler
setup_irq	sei				; set interrupt disable flag

			ldy #%01111111
			sty CIA1_ICSR	; turn off CIA-1 interrupts
			sty CIA2_ICSR	; turn off CIA-2 interrupts
			lda CIA1_ICSR	; ACK any pending interrupts on CIA-1
			lda CIA2_ICSR	; ACK any pending interrupts on CIA-2

			lda #$01		; enable raster interrupt
			sta VIC2_ICR	; write VIC-II interrupt control register
			
			lda #<irq		; low byte of our irq handler address
			ldx #>irq		; high byte of our irq handler address
			sta ISR_LO		; set execution address of
			stx ISR_HI		; 	interrupt service routine

			lda #$00		; scan-line to trigger raster interrupt on
			sta VIC2_RASLN
		
			lda VIC2_ICR	; bit-7 is actually bit 8 of trigger scan-line
			and #%01111111	; make sure it is zero
			sta VIC2_ICR

			cli				; clear interrupt disable flag
			rts

; write_title: write some text to the screen
write_title	ldx #$00		; init counter
_loop		lda line1,x		; read X'th character from line1
			sta $0590,x		;  >> store it near the center of the screen
			lda colors,x
			sta $d990,x		;  >> set foreground color
			lda line2,x		; read X'th character from line2
			sta $05e0,x		;  >> store it near the center of the screen
			lda colors,x
			sta $d9e0,x		;  >> set foreground color
			inx
			cpx #40
			bne _loop		; loop until X == 40 (length of the string)
			rts

; color_title: change the color of the title text
color_title	; assign the values from the colors array to the lines of text
			ldx #0
			ldy colstrt
_loop		iny				; next color
			cpy #40
			bne _color_ok
			ldy #$00
_color_ok	lda colors,y
			sta $d990,x
			sta $d9e0,x
			inx
			cpx #40
			bne _loop		; loop until X == 40 (length of the string)
			
			; change the starting color for next iteration
			ldy colstrt		; load current starting position in reg-Y
			lda coldir		; check which direction were moving
			bne _right		;	(0 == left, 1 == right)

_left		cpy #26			; at the end of the color line?
			beq _end_l
			inc colstrt
			rts				; end subroutine
_end_l		lda #1			; switch direction
			sta coldir
			rts				; end subroutine

_right		cpy #0			; at the beginning of the color line?
			beq _end_r
			dec colstrt
			rts				; end subroutine
_end_r		lda #0			; switch direction
			sta coldir
			rts				; end subroutine

; init_screen: clear screen (black)
init_screen	ldx #$00		; set X to zero (black) - reset to zero if color changes!
			stx VIC2_BCKCLR ; set background color
			stx VIC2_BORCLR	; set border color

_clear		; clear to screen in 4 blocks
			lda #$20		; set A to spacebar character
			sta SCREEN_RAM,x
			sta SCREEN_RAM+256,x		
			sta SCREEN_RAM+512,x
			sta SCREEN_RAM+744,x	; not 768 or we'd write past the end of screen memory

			; clear color in 4 blocks
			lda #$00		; set foreground to black
			sta COLOUR_RAM,x
			sta COLOUR_RAM+256,x
			sta COLOUR_RAM+512,x
			sta COLOUR_RAM+744,x

			inx				; increment X
			bne _clear		; repeat loop until x wraps to 0

			rts				; return from subroutine

; irq : custom interrupt handler
irq			dec VIC2_ISR		; acknowledge IRQ
			jsr color_title
			jmp KERNAL_IRQEND	; jump to kernel interrupt routine
		
; data
			.enc "screen"
line1 		.text "   this is test text - the first line    "
line2 		.text "    another line because 1 is boring     "
			.enc "none"

colors		.byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f	; 8
			.byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f	; 16
			.byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f	; 24
			.byte $0f, $0f, $0f, $0f, $0f, $0f, $0a, $0a	; 32
			.byte $02, $02, $02, $02, $02, $0a, $0a, $0f	; 40

colstrt 	.byte 4
coldir		.byte 0
