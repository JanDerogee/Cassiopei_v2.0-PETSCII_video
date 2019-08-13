;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODORE16PLUS4
;-------------------------------------------------------------------------------
; 10 SYS4128

*=$1001

        BYTE        $0B, $10, $0A, $00, $9E, $34, $31, $32, $38, $00, $00, $00


*=$1010
PRG_IDENTIFIER
            ;'0123456789ABCDEF'
        TEXT 'petscii c16/+4' ;if the wrong menu PRG is installed onto the cassiopei, this message could be valuable hint in solving the problem
        BYTE 0;end of table marker
        ;also usefull for debugging on vice, then the screen is no longer completely empty and you know that something has happened

*=$1020
PRG_START       JMP INIT        ;start the program


;-- zeropage RAM registers--
;-- zeropage RAM registers--
CPIO_DATA       = $D8  ;this zeropage memory location is used to parse the CPIO data
STR_ADDR        = $D9  ;pointer to string
;STR_ADDR+1     = $DA  ;           
CHAR_ADDR       = $DB
;CHAR_ADDR+1    = $DC
ADDR            = $DE
;ADDR+1         = $DF


ADDR_LAST_TILE  = $E0  ;pointer (used in NORMAL mode, for detection of the last tile,
;ADDR_LAST_TILE+1= $E1 ;this way we don't have to keep a counter, we just compare two 16-bit values)
CNTR            = $E2  ;pointer (used in DELTA mode, since the last tile is unpredictable, this counter just counts the number of tiles
;CNTR+1         = $E3  ;until it matches the "changed tiles" value of the image)      



;-- build related settings --
WINDOW_X_POS    = 1             ;the X-distance from top-left
WINDOW_Y_POS    = 8             ;the Y-distance from top-left
WINDOW_X_SIZE   = 31            ;the X-size of the window to be scrolled
WINDOW_Y_SIZE   = 14            ;the Y-size of the window to be scrolled

SUPPORTED_X_SIZE = 40           ;screen width of a C64 is 40 columns
SUPPORTED_Y_SIZE = 25           ;screen width of a C64 is 25 rows

;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODORE16PLUS4"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<