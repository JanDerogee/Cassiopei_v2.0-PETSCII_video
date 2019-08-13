;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODORE128

;ATTENTION: in order to test this code in VICE (emulators are much more practical
;========== for a quick menu look-and-feel test. It is important that you
;           use the correct autostarting settings, otherwise it WILL crash!!
;           settings -> autostarting settings -> select inject to RAM
;-------------------------------------------------------------------------------

*=$1C01 
        BYTE    $0E, $08, $0A, $00, $9E, $20, $28,  $37, $32, $31, $36, $29, $00, $00, $00      ; 10 SYS (7216)


*=$1C10
PRG_IDENTIFIER
            ;'0123456789ABCDEF'
        TEXT 'petscii player:c128' ;if the wrong menu PRG is installed onto the cassiopei, this message could be valuable hint in solving the problem
        BYTE 0;end of table marker
        ;also usefull for debugging on vice, then the screen is no longer completely empty and you know that something has happened

*=$1C30
PRG_START       JMP INIT        ;start the program


;-- zeropage RAM registers--
CPIO_DATA       = $02  ;this zeropage memory location is used to parse the CPIO data

ADDR            = $61  ;pointer
;ADDR+1         = $62  ;     
 
ADDR_LAST_TILE  = $63  ;pointer (used in NORMAL mode, for detection of the last tile,
;ADDR_LAST_TILE+1= $64  ;this way we don't have to keep a counter, we just compare two 16-bit values)
CNTR            = $63  ;pointer (used in DELTA mode, since the last tile is unpredictable, this counter just counts the number of tiles
;CNTR+1         = $64  ;until it matches the "changed tiles" value of the image)      


;COL_PRINT       = $6B  ;holds the color of the charaters printed with the PRINT_CHAR routine
;COLOR_ADDR      = $6C  ;pointer to color memory
;COLOR_ADDR+1   = $6D

STR_ADDR        = $6E  ;pointer to string
;STR_ADDR+1     = $6F  ;           
;;ADDR          = $F8  ;pointer
;;;ADDR+1       = $F9  ;      
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
endif   ;this endif belongs to "ifdef COMMODORE128"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<