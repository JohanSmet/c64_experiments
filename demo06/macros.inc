; macros.asm - Johan Smet - BSD-3-Clause (see LICENSE)
;
; utility macros for ca65

; credits to Claus on the lemon64 forums (see: https://www.lemon64.com/forum/viewtopic.php?t=72236&sid=29533207f92dce9b621dc9f6f8935686)
.macro ENC_SCREENCODE
    .repeat $20, i
        .charmap $40 + i, $40 + i + $00
    .endrepeat

    .repeat $20, i
        .charmap $60 + i, $60 + i - $60
    .endrepeat

    .repeat $20, i
        .charmap $80 + i, $80 + i + $40
    .endrepeat

    .repeat $20, i
        .charmap $A0 + i, $A0 + i - $40
    .endrepeat

    .repeat $3F, i
        .charmap $C0 + i, $C0 + i - $80
    .endrepeat

    .charmap $FF, $5E

.endmacro 

.macro ENC_PETSCII
    .repeat $ff, i
        .charmap i + 1, i + 1
    .endrepeat
.endmacro 



