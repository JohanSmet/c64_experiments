; demo05/main.asm - Johan Smet - BSD-3-Clause (see LICENSE)

.include "sys_constants.inc"
.include "macros.inc"
.include "keyboard.inc"

; main routine
.code

start:		jsr init_screen
			jsr write_title
			jsr setup_irq
			jmp *			; loop forever

; setup_irq: init interrupt handler
setup_irq:	sei				; set interrupt disable flag

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

; check_input: called from irq handler to check keyboard input
check_input:jsr keyb_scan
			cmp #$ff
			beq @end
	
			ldx msg_size
			cpx #40
			bne @upd
			ldx #0
			stx msg_size
		
@upd:		sta msg,x
			inc msg_size

			sta SCREEN_RAM,x
			lda #$01
			sta COLOUR_RAM,x

@end:		rts

; write_title: write some text to the screen
write_title:ldx #$00		; init counter
@loop:		lda line1,x		; read X'th character from line1
			sta $0590,x		;  >> store it near the center of the screen
			lda colors,x
			sta $d990,x		;  >> set foreground color
			lda line2,x		; read X'th character from line1
			sta $05e0,x		;  >> store it near the center of the screen
			lda colors,x
			sta $d9e0,x		;  >> set foreground color
			inx
			cpx #40
			bne @loop		; loop until X == 40 (length of the string)
			rts

; color_title: change the color of the title text
color_title:; assign the values from the colors array to the lines of text
			ldx #$00
			ldy colstrt
@loop:		iny				; next color
			cpy #40
			bne @color_ok
			ldy #$00
@color_ok:	lda colors,y
			sta $d990,x
			sta $d9e0,x
			inx
			cpx #40
			bne @loop		; loop until X == 40 (length of the string)
			
			; change the starting color for next iteration
			ldy colstrt		; load current starting position in reg-Y
			lda coldir		; check which direction were moving
			bne @right		;	(0 == left, 1 == right)

@left:		cpy #26			; at the end of the color line?
			beq @end_l
			inc colstrt
			rts				; end subroutine
@end_l:		lda #1			; switch direction
			sta coldir
			rts				; end subroutine

@right:		cpy #0			; at the beginning of the color line?
			beq @end_r
			dec colstrt
			rts				; end subroutine
@end_r:		lda #0			; switch direction
			sta coldir
			rts				; end subroutine

; init_screen: clear screen (black)
init_screen:ldx #$00		; set X to zero (black) - reset to zero if color changes!
			stx VIC2_BCKCLR ; set background color
			stx VIC2_BORCLR	; set border color

@clear:		; clear to screen in 4 blocks
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
			bne @clear		; repeat loop until x wraps to 0

			rts				; return from subroutine

; irq : custom interrupt handler
irq:		dec VIC2_ISR		; acknowledge IRQ
			jsr check_input
			jsr color_title
			jmp KERNAL_IRQEND	; jump to kernel interrupt routine

	
; data
.data

ENC_SCREENCODE
line1: 		.byte "   this is test text - the first line    "
line2:		.byte "    another line because 1 is boring     "
msg:		.byte "                                         "
ENC_PETSCII

msg_size:	.byte $00

colors:		.byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f	; 8
			.byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f	; 16
			.byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f	; 24
			.byte $0f, $0f, $0f, $0f, $0f, $0f, $0a, $0a	; 32
			.byte $02, $02, $02, $02, $02, $0a, $0a, $0f	; 40

colstrt: 	.byte 4
coldir:		.byte 0
