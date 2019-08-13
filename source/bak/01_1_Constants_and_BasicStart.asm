;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX or COMMODOREPET80XX
;-------------------------------------------------------------------------------

*=$0401
        BYTE    $0E, $08, $0A, $00, $9E, $20, $28,  $31, $30, $37, $32, $29, $00, $00, $00      ;10 SYS (1072)


;-------------------------------------------------------------------------------
endif
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET20XX OR COMMODOREPET30XX OR COMMODOREPET40XX
*=$0410
PRG_IDENTIFIER      ;'0123456789ABCDEF'
                TEXT 'petscii player for 40kol PET' ;this message could be valuable hint in solving a problem
                BYTE 0;end of table marker
endif
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET80XX
*=$0410
PRG_IDENTIFIER      ;'0123456789ABCDEF'
                TEXT 'petscii player for 80kol PET' ;this message could be valuable hint in solving a problem
                BYTE 0;end of table marker
endif
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<








;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX or COMMODOREPET80XX
;-------------------------------------------------------------------------------

*=$0430
PRG_START       LDA #$0C        ;we must force the PET to display a charset that ALL systems can use (according: http://www.atarimagazines.com/compute/issue26/171_1_ALL_ABOUT_PET_CBM_CHARACTER_SETS.php)
                STA $E84C       ;the charset layout we are using now would be identical to the C64 charset layout. NOTE:the 2001's do not have the option of a configurable charset :-(
                JMP INIT        ;start the program

;;-- zeropage RAM registers --
CPIO_DATA       = $A2           ;this zeropage memory location is used to parse the CPIO data
CHAR_ADDR       = $54
;CHAR_ADDR+1    = $55
STR_ADDR        = $56  ;pointer to string
;STR_ADDR+1     = $57  ;           
ADDR_LAST_TILE  = $1F  ;pointer (used in NORMAL mode, for detection of the last tile,
;ADDR_LAST_TILE+1= $20  ;this way we don't have to keep a counter, we just compare two 16-bit values)
CNTR            = $21  ;pointer (used in DELTA mode, since the last tile is unpredictable, this counter just counts the number of tiles
;CNTR+1         = $22  ;until it matches the "changed tiles" value of the image)      
ADDR            = $23  ;pointer
;ADDR+1         = $24  ;     
 

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET20XX OR COMMODOREPET30XX OR COMMODOREPET40XX

;-- BUILD RELATED SETTINGS --

;-- build related settings --
WINDOW_X_POS    = 1             ;the X-distance from top-left
WINDOW_Y_POS    = 8             ;the Y-distance from top-left
WINDOW_X_SIZE   = 31            ;the X-size of the window to be scrolled
WINDOW_Y_SIZE   = 14            ;the Y-size of the window to be scrolled

SUPPORTED_X_SIZE = 40           ;screen width of a 40-kol PET is 40 columns
SUPPORTED_Y_SIZE = 25           ;screen width of a 40-kol PET is 25 rows
endif
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET80XX

;-- BUILD RELATED SETTINGS --
WINDOW_X_POS    = 1             ;the X-distance from top-left
WINDOW_Y_POS    = 7             ;the Y-distance from top-left
WINDOW_X_SIZE   = 46            ;the X-size of the window to be scrolled
WINDOW_Y_SIZE   = 17           ;the Y-size of the window to be scrolled

SUPPORTED_X_SIZE = 80           ;screen width of a 80-kol PET is 80 columns
SUPPORTED_Y_SIZE = 25           ;screen width of a 80-kol PET is 25 rows
endif
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX or COMMODOREPET80XX"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<