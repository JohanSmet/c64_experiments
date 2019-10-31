; demo02/main.asm - Johan Smet - BSD-3-Clause (see LICENSE)

; BASIC loader
*       = $0801							; change program counter to start of BASIC area
        .word (+)						; pointer to next line of basic code
		.word 2005						; current basic line number
        .null $9e, format("%d", start)	; $9e == token for SYS keyword (=> "SYS <start of assembly program> <zero>")
+		.word 0							; end of basic program

*       = $1000							; start actual assembly program at address $1000

; main routine
start		jsr init_screen
			jsr write_title
			jmp *		; loop forever

; write_title: write some text to the screen
write_title	ldx #$00	; init counter
_loop		lda line1,x	; read X'th character from line1
			sta $0590,x	;  >> store it near the center of the screen
			lda #$02
			sta $d990,x	;  >> set foreground color
			lda line2,x	; read X'th character from line2
			sta $05e0,x	;  >> store it near the center of the screen
			lda #$02
			sta $d9e0,x	;  >> set foreground color
			inx
			cpx #40
			bne _loop	; loop until X == 40 (length of the string)
			rts

; init_screen: clear screen (black)
init_screen	ldx #$00	; set X to zero (black) - reset to zero if color changes!
			stx $d021	; set background color
			stx $d020	; set border color

_clear		lda #$20	; set A to spacebar character
			sta $0400,x	; write to screen in 4 blocks
			sta $0500,x	;	last block is end of screen area - 256
			sta $0600,x
			sta $06e8,x
			lda #$00	; set foreground to black
			sta $d800,x
			sta $d900,x
			sta $da00,x
			sta $dae8,x
			inx			; increment X
			bne _clear	; repeat loop until x wraps to 0

			rts			; return from subroutine
	
; data
			.enc "screen"
line1 		.text "   this is test text - the first line    "
line2 		.text "    another line because 1 is boring     "

