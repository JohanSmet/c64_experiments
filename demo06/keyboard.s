; keyboard.s - Johan Smet - BSD-3-Clause (see LICENSE)
; 
; keyboard input routine - losely based on "Scanning the Keyboard the correct and non-KERNAL way" by TWW/TCR on codebase64.org
; PLEASE NOTE: there are some issues when three keys are pressed at once; last key is not always reported correctly.
;	need to look into this, but current code will do for now

.include "sys_constants.inc"

; ============================================================================
; exported symbols
; ============================================================================

.export keyb_scan

; ============================================================================
; zeropage variables
; ============================================================================

.zeropage
key_matrix:	.res 8, $00
key_down:	.res 3, $00
key_count:	.byte $00
key_tmp1:	.byte $00
key_return:	.byte $00
;
; ============================================================================
; code
; ============================================================================

.code

; keyb_scan: scan keyboard for keypresses
keyb_scan:	lda #%11111111	; set CIA#1 port A to output
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
			sty key_matrix	; store in temp buffer
			.repeat 7, i
				rol			; select next row
				sta CIA1_PRA			
				ldy CIA1_PRB		
				sty key_matrix+i+1
			.endrepeat

			; iterate the matrix and check which keys are pressed
			.repeat 8, i
				lda key_matrix+i
				ldx #(i * 8)
				jsr scan_keyrow
			.endrepeat
		
			; check for newly pressed keys
			ldx key_count	; load counter
@check:		dex			
			bmi @cleanup	; exit routine when counter becomes negative
			lda key_down,x	; load keycode
			cmp key_dprev+0	; check if equal to previously pressed key
			beq @check		; found -> skip to next key
			cmp key_dprev+1	; check if equal to previously pressed key
			beq @check		; found -> skip to next key
			cmp key_dprev+2	; check if equal to previously pressed key
			beq @check		; found -> skip to next key
			sta key_return	; not found -> return this key as new key-press

			; move keys from this execution to _prev buffer
@cleanup:	lda key_down+0
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
scan_keyrow:asl				; shift-left moves top bit into the carry flag
			bcs :+			; carry set == key not pressed
			jsr key_press
	:		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs :+
			jsr key_press
	:		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs :+
			jsr key_press
	:		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs :+
			jsr key_press
	:		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs :+
			jsr key_press
	:		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs :+
			jsr key_press
	:		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs :+
			jsr key_press
	:		inx				; point to next entry in keymap
			asl				; shift next bit into carry flag
			bcs :+
			jsr key_press
	:		rts

; key_press: internal routine - store key press
key_press:	sta key_tmp1	; save value of A-register
			ldy key_count	; use Y-register as index into key-buffer
			inc key_count	; a key will be added
			lda key_map,x	; load key-code
			sta key_down,y	; store in keybuffer
			lda key_tmp1	; restore A-register
			rts
	
; data
.data

; map key matrix to petscii
key_map:	.byte 	$ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff	; down, F5, F3, F1, F7, Right, Return, Delete
			.byte 	$ff, $05, $13, $1a, $34, $01, $17, $33	; left-shift, e, s, z, 4, a, w, 3
			.byte 	$18, $14, $06, $03, $36, $04, $12, $35  ; x, t, f, c, 6, d, r, 5
			.byte 	$16, $15, $08, $02, $38, $07, $19, $37  ; v, u, h, b, 8, g, y, 7
			.byte 	$0e, $0f, $0b, $0d, $30, $0a, $09, $39  ; n, o, k, m, 0, j, i, 9
			.byte 	$2c, $00, $3a, $2e, $2d, $0c, $10, $2b  ; ,, @, :, ., -, l, p, +
			.byte 	$2f, $1e, $3d, $ff, $ff, $3b, $2a, $1c  ; /, ^, =, right-shift, home, ;, *, £
			.byte 	$ff, $11, $ff, $20, $32, $ff, $1f, $31  ; run stop, q, c=, space, 2, ctrl, <-, 1

key_dprev:	.byte	$ff, $ff, $ff

