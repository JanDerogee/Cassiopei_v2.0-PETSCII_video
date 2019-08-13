;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODORE64
;-------------------------------------------------------------------------------
*=$0801
        BYTE    $0B, $08, $0A, $00, $9E, $32, $30, $39, $36, $00, $00, $00      ; 10 SYS2096


*=$0810
PRG_IDENTIFIER
            ;'0123456789ABCDEF'
        TEXT 'petscii player:c64' ;this message could be valuable hint in solving a problem
        BYTE 0;end of table marker
        ;also usefull for debugging on vice, then the screen is no longer completely empty and you know that something has happened

*=$0830
PRG_START       JMP INIT        ;start the program

;-- zeropage RAM registers--
CPIO_DATA       = $02  ;this zeropage memory location is used to parse the CPIO data

ADDR            = $61  ;pointer
;ADDR+1         = $62  ;     
 
ADDR_LAST_TILE  = $63  ;pointer (used in NORMAL mode, for detection of the last tile,
;ADDR_LAST_TILE+1= $64  ;this way we don't have to keep a counter, we just compare two 16-bit values)
CNTR            = $63  ;pointer (used in DELTA mode, since the last tile is unpredictable, this counter just counts the number of tiles
;CNTR+1         = $64  ;until it matches the "changed tiles" value of the image)      

STR_ADDR        = $6E  ;pointer to string
;STR_ADDR+1     = $6F  ;           
CHAR_ADDR       = $FA
;CHAR_ADDR+1    = $FB


;-- build related settings --
WINDOW_X_POS    = 1             ;the X-distance from top-left
WINDOW_Y_POS    = 8             ;the Y-distance from top-left
WINDOW_X_SIZE   = 31            ;the X-size of the window to be scrolled
WINDOW_Y_SIZE   = 14            ;the Y-size of the window to be scrolled

SUPPORTED_X_SIZE = 40           ;screen width of a C64 is 40 columns
SUPPORTED_Y_SIZE = 25           ;screen width of a C64 is 25 rows

;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODORE64"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<