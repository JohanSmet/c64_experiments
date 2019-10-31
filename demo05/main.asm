; demo05/main.asm - Johan Smet - BSD-3-Clause (see LICENSE)

.include "sys_constants.asm"

; BASIC loader
*       = $0801							; change program counter to start of BASIC area
        .word (+)						; pointer to next line of basic code
		.word 2005						; current basic line number
        .null $9e, format("%d", start)	; $9e == token for SYS keyword (=> "SYS <start of assembly program> <zero>")
+		.word 0							; end of basic program

* = $1000

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

; check_input: called from irq handler to check keyboard input
check_input	jsr scan_input
			cmp #$ff
			beq _end
	
			ldx msg_size
			cpx #40
			beq _end
		
			sta msg,x
			inc msg_size

			sta SCREEN_RAM,x
			lda #$01
			sta COLOUR_RAM,x

_end		rts

; zero-page locations used by the keyboard routine
key_matrix	= $60		; 8 bytes - temporary buffer for key matrix
key_down	= $68		; 3 bytes - currently pressed keys
key_count	= $6B		; 1 byte - number of keys pressed
key_tmp1	= $6C		; 1 byte - temp register
key_return	= $6D		; 1 byte - keycode to return

; scan_input: scan keyboard for keypresses
scan_input	lda #%11111111	; set CIA#1 port A to output
			sta CIA1_DDRA
		
			lda #%00000000	; set CIA#1 port B to input
			sta CIA1_DDRB

			; init variables
			lda #$00
			sta key_count
			
			ldx #$ff
			stx key_down+0
			stx key_down+1
			stx key_down+2
			stx key_return
		
			; read keyboard matrix in one pass to keep it as consistent as possible
			lda #%11111110	; start at first row
			sec				; set carry so rol shifts in a 1

			sta CIA1_PRA	; select row
			ldy CIA1_PRB	; read column
			sta key_matrix	; store in temp buffer
			.for i := 1, i <= 7, i += 1
				rol			; select next row
				sta CIA1_PRA			
				ldy CIA1_PRB		
				sty key_matrix+i	
			.next

			; iterate the matrix and check which keys are pressed
			.for i := 1, i <= 7, i += 1
				lda key_matrix+i
				ldx #(i * 8)
				jsr scan_keyrow
			.next
		
			; check for newly pressed keys
			ldx key_count	; load counter
_check		dex			
			bmi _cleanup	; exit routine when counter becomes negative
			lda key_down,x	; load keycode
			cmp key_dprev+0	; check if equal to previously pressed key
			beq _check		; found -> skip to next key
			cmp key_dprev+1	; check if equal to previously pressed key
			beq _check		; found -> skip to next key
			cmp key_dprev+2	; check if equal to previously pressed key
			beq _check		; found -> skip to next key
			sta key_return	; not found -> return this key as new key-press

			; move keys from this execution to _prev buffer
_cleanup	lda key_down+0
			sta key_dprev+0
			lda key_down+1
			sta key_dprev+1
			lda key_down+2
			sta key_dprev+2

			; setup return values
			lda key_return

			; end of routine
			rts

; scan_keyrow: internal routine - scan one row of the key-matrix for keys that are down
scan_keyrow	asl				; shift-left moves top bit into the carry flag
			bcs +			; carry set == key not pressed
			jsr key_press
	+		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs +
			jsr key_press
	+		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs +
			jsr key_press
	+		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs +
			jsr key_press
	+		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs +
			jsr key_press
	+		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs +
			jsr key_press
	+		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs +
			jsr key_press
	+		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs +
			jsr key_press
	+		rts

; key_press: internal routine - store key press
key_press	sta key_tmp1	; save value of A-register
			ldy key_count	; use Y-register as index into key-buffer
			inc key_count	; a key will be added
			lda key_map,x	; load key-code
			sta key_down,y	; store in keybuffer
			lda key_tmp1	; restore A-register
			rts


; write_title: write some text to the screen
write_title	ldx #$00		; init counter
_loop		lda line1,x		; read X'th character from line1
			sta $0590,x		;  >> store it near the center of the screen
			lda colors,x
			sta $d990,x		;  >> set foreground color
			lda line2,x		; read X'th character from line1
			sta $05e0,x		;  >> store it near the center of the screen
			lda colors,x
			sta $d9e0,x		;  >> set foreground color
			inx
			cpx #40
			bne _loop		; loop until X == 40 (length of the string)
			rts

; color_title: change the color of the title text
color_title	; assign the values from the colors array to the lines of text
			ldx #$00
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
			jsr check_input
			jsr color_title
			jmp KERNAL_IRQEND	; jump to kernel interrupt routine

	
; data
			.enc "screen"
line1 		.text "   this is test text - the first line    "
line2 		.text "    another line because 1 is boring     "
msg 		.text "                                         "
			.enc "none"

msg_size	.byte $00

colors		.byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f	; 8
			.byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f	; 16
			.byte $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f	; 24
			.byte $0f, $0f, $0f, $0f, $0f, $0f, $0a, $0a	; 32
			.byte $02, $02, $02, $02, $02, $0a, $0a, $0f	; 40

colstrt 	.byte 4
coldir		.byte 0

; map key matrix to petscii
key_map		.byte 	$ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff	; down, F5, F3, F1, F7, Right, Return, Delete
			.byte 	$ff, $05, $13, $1a, $34, $01, $17, $33	; left-shift, e, s, z, 4, a, w, 3
			.byte 	$18, $14, $06, $03, $36, $04, $12, $35  ; x, t, f, c, 6, d, r, 5
			.byte 	$16, $15, $08, $02, $38, $07, $19, $37  ; v, u, h, b, 8, g, y, 7
			.byte 	$0e, $0f, $0b, $0d, $30, $0a, $09, $39  ; n, o, k, m, 0, j, i, 9
			.byte 	$2c, $00, $3a, $2e, $2d, $0c, $10, $2b  ; ,, @, :, ., -, l, p, +
			.byte 	$2f, $1e, $3d, $ff, $ff, $3b, $2a, $1c  ; /, ^, =, right-shift, home, ;, *, £
			.byte 	$ff, $11, $ff, $20, $32, $ff, $1f, $31  ; run stop, q, c=, space, 2, ctrl, <-, 1

key_dprev	.byte	$ff, $ff, $ff

