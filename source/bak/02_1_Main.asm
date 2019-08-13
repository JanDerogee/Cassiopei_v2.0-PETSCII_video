;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX
SCREENWIDTH = 40        ;width of the computer screen in characters, required for print function
endif

ifdef COMMODOREPET80XX
SCREENWIDTH = 80        ;width of the computer screen in characters, required for print function
endif

ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX or COMMODOREPET80XX
;-------------------------------------------------------------------------------
CHARSCREEN      = $8000         ;location of the character screen memory

;KEYCNT  = 525          ;the counter that keeps track of the number of key in the keyboard buffer       Original ROM PETs       
;KEYBUF  = 527          ;the first position of the keyboard buffer                                      Original ROM PETs  
KEYCNT          = 158           ;the counter that keeps track of the number of key in the keyboard buffer       PET/CBM (Upgrade and 4.0 BASIC)
KEYBUF          = 623           ;the first position of the keyboard buffer                                      PET/CBM (Upgrade and 4.0 BASIC)
CURSORPOS_X     = 198           ;Cursor Column on Current Line                                                  PET/CBM (Upgrade and 4.0 BASIC)
CURSORPOS_Y     = 216           ;Current Cursor Physical Line Number                                            PET/CBM (Upgrade and 4.0 BASIC)

;TODCLK         = $C8           ;Time-Of-Day clock register (MSB) BASIC 1 uses locations 200-202 ($C8-$CA)
;TODCLK+1       = $C9           ;Time-Of-Day clock register (.SB)
;TODCLK+2       = $CA           ;Time-Of-Day clock register (LSB)

TODCLK          = $8D           ;Time-Of-Day clock register (MSB) BASIC>1 uses locations 141-143 ($8D-$8F)
;TODCLK+1       = $8E           ;Time-Of-Day clock register (.SB)
;TODCLK+2       = $8F           ;Time-Of-Day clock register (LSB)

;###############################################################################

KEY_NOTHING     = 255           ;matrix value when no key is pressed

;-- PETSCII keycodes --
KEY_7           = $37           ;$37 = 7 
KEY_4           = $34           ;$34 = 4
KEY_1           = $31           ;$31 = 1 
KEY_0           = $30           ;$30 = 0
KEY_RETURN      = $0D           ;$0D = RETURN

;-------------------------------------------------------------------------------
;Read the keyboard, this routine converts the keycode to a control
;code that is easier to decode. This value is stored in A
;...............................................................................
SCAN_INPUTS     LDA #254                ;by setting the "currently detected value" to something different then the value that was detected the last time, we can achieve key-repeat
                STA $97                 ;because the CBM will wait for the "currently detected value" to change before it will accept the same again.
                LDA ALLOW_KEYREPEAT     ;some functions/keys have keyrepeat, this makes it easier to scroll
                BNE SCAN_KEYPRESS       ;through a long list of filenames

SCAN_KEYRELEASE LDA $97                 ;
                CMP #KEY_NOTHING        ;check for the "no key pressed" situation
                BNE SCAN_KEYRELEASE     ;when the keyboard isn't released, we may asume that the user is still pressing the same key, perhaps so we repeat the input (and by that we create key repeat functionality)

SCAN_KEYPRESS   LDA #$00                ;clear keyboard buffer
                STA KEYCNT              ;
SCAN_KEYPR_00   LDA KEYCNT              ;check number of chars in keyboard buffer
                BEQ SCAN_KEYPR_00       ;

                LDA KEYBUF              ;use the value as found in the keyboard buffer, the only way to be independend of the keyboard matrix!!!
                CMP #KEY_7              ;and jump to the requested action
                BEQ SCAN_VAL_PREV       ;
                CMP #KEY_4              ;
                BEQ SCAN_VAL_SELECT     ;
                CMP #KEY_1              ;
                BEQ SCAN_VAL_NEXT       ; 


SCAN_VAL_IDLE   LDA #0                  ;do not allow keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_IDLE    ;nothing happened, send idle value
                RTS

SCAN_VAL_SELECT LDA #0                  ;do not allow keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_SELECT  ;
                RTS

SCAN_VAL_PREV   LDA #1                  ;keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_PREVIOUS;
                RTS

SCAN_VAL_NEXT   LDA #1                  ;keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_NEXT    ;
                RTS

ALLOW_KEYREPEAT BYTE $0 ;this is a flag that indicates if keyrepeat is allowed (0=key repeat not alowed, 1=key repeat alowed)


;-------------------------------------------------------------------------------
;This routine will have the Z-flag set when no key is pressed
;call example   JSR CHECK_FOR_KEY
;               BNE <jump to wherever because a key was pressed>
;in vice $FB is the value when space is pressed, but on my CBM3032 this does not work
;just type all keys on the keyboard (one ate a time) untill you have found a key that makes the value $FF change
;On my CBM3032 runstop-key changes the value, arrow back does, so these are convinient keys for stopping video playback.
;This is a little problem caused by the many different keyboard layouts.
;...............................................................................

CHECK_FOR_KEY   LDA $E816               ;check the PIA for any kind of keypress on the keyboard scan
                CMP #$FF                ;the value when nothing is pressed
                RTS                     ;

;-------------------------------------------------------------------------------
;This routine will wait until the user presses a key
;call example   JSR WAIT_FOR_KEY
;...............................................................................
WAIT_FOR_KEY    LDA #$00                ;clear keyboard buffer
                STA KEYCNT              ;
WAIT_FOR_KEY_01 LDA KEYCNT              ;check number of chars in keyboard buffer
                BEQ WAIT_FOR_KEY_01     ;
                RTS                     ;

;-------------------------------------------------------------------------------
;Prevent the use of shift+CBM to change the case of the screen.
;This must be prevented when screen are build with special characters.
;Example:       JSR PREVENT_CASE_CHANGE
;...............................................................................                
PREVENT_CASE_CHANGE
                RTS                     ;

;HOW DO I ACCESS UPPER/LOWER CASE OR GRAPHICS CHARACTER SETS?

;  In order to have graphic symbols to to draw simple charts and for games
;  as well as upper and lower case characters for word processing Commodore
;  gave the PET two 256 character sets, one with upper and lower case
;  characters for word processing and business applications and one with
;  upper case and graphics characters for charts, games, etc.  In order to
;  change the 'mode' of the PET you must direct the computer to 'look' at
;  one of two character sets via a POKE command. 

;  The PETs start up in one of two modes, upper case characters (pressing
;  shift types graphics symbols) or lower case characters (pressing shift
;  shift types upper case characters).

;  To direct the computer to uppercase/graphics mode:
;    POKE 59468,12

;  To direct the computer to lower/uppercase mode:
;    POKE 59468,14

;   Note that when you change sets the characters on the screen change
;   immediately to the new image, you cannot hve characters from both
;   set on the screen at the same time without some specially timed
;   program to perform it.

;  Original ROM PET have reversed reversed upper/lower case characters:

;  Commodore had the upper/lower case characters reversed in the original
;  ROM models where both modes started with upper case characters and you
;  pressed SHIFT for lower case or graphics.  This is the reason for some
;  older software having reversed case text.  There are utilities available
;  that will adjust all your PRINT statements to the proper case for the
;  newer or older ROM machines.

;  12" 4000/8000 series:

;  The 12" 4000/8000 series PETs allow you to change case by printing
;  a control character:  CHR$(14) - Text Mode   CHR$(142)-Graphics Mode

;  When you issue a CHR$(14) on a 4000/800 series PET the newer display
;  controller will be adjusted so there is a pixel or two gap between
;  screen lines.  If you do not wish this gap in text mode just
;  POKE 59468,14 instead of printing CHR$(14)
;  (if you want the gap in character mode you can issue a ? CHR$(14)
;  and then POKE 59468,12 to produce the desired effect.)

;  Unlike the later Commmodore 8-Bits there is no way to edit the
;  characters on the screen in software alone.

; but the easiest way is to do a JSR $E01B and the black lines instantly dissappear

;-------------------------------------------------------------------------------
;Allow the use of shift+CBM to change the case of the screen.
;Example:       JSR ALLOW_CASE_CHANGE
;...............................................................................                
ALLOW_CASE_CHANGE
                RTS


;-------------------------------------------------------------------------------
;This routine will print extra computer specific information
;Example:       JSR SHOW_VERSION
;...............................................................................
SHOW_VERSION    LDX #1                  ;set cursor to top,left
                LDY #1                  ;
                JSR SET_CURSOR          ;
                LDA #<PRG_IDENTIFIER    ;set pointer to the text that defines the main-screen
                LDY #>PRG_IDENTIFIER    ;        
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen     
               
                LDX #1                  ;set cursor to top,left
                LDY #2                  ;
                JSR SET_CURSOR          ;
                LDA #<VERSION_INFO      ;set pointer to the text that defines the main-screen
                LDY #>VERSION_INFO      ;        
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen     

                RTS

;-------------------------------------------------------------------------------
; The first location of the charsecreen (topleft) is defined as coordinate 0,0
; Use this routine before calling a PRINT related routine
;               LDX CURSOR_Y;.. chars from the top of the defined screen area
;               LDY CURSOR_X;.. chars from the left of the defined screen area
;               JSR SET_CURSOR
;...............................................................................

SET_CURSOR      LDA #<CHARSCREEN        ;
                STA CHAR_ADDR           ;store base address (low byte)
                LDA #>CHARSCREEN        ;
                STA CHAR_ADDR+1         ;store base address (high byte)

                ;calculate exact value based on the requested X and Y coordinate
                CLC                     ;
                TXA                     ;add  value in X register (to calculate the new X position of cursor)
                ADC CHAR_ADDR           ;                        
                STA CHAR_ADDR           ;
                LDA #$00                ;
                ADC CHAR_ADDR+1         ;add carry
                STA CHAR_ADDR+1         ;

SET_CURS_CHR_LP CPY #00                 ;
                BEQ SET_CURS_END        ;when Y is zero, calculation is done
                CLC                     ;clear carry for the upcoming "ADC CHAR_ADDR"

                LDA #SCREENWIDTH        ;add  40 or 80 to calculate the new Y position of cursor
                ADC CHAR_ADDR           ;                        
                STA CHAR_ADDR           ;
                LDA #$00                ;
                ADC CHAR_ADDR+1         ;add carry... and viola, we have a new cursor position (memory location where next character will be printed)
                STA CHAR_ADDR+1         ;
                DEY                     ;
                JMP SET_CURS_CHR_LP     ;

SET_CURS_END    RTS                     ;

;-------------------------------------------------------------------------------
;call this routine as described below:
;
;               LDA #character          ;character is stored in Accumulator
;               JSR PRINT_CHAR          ;character is printed to screen, cursor is incremented by one
; also affects Y
; note: when the character value is 0 there is nothing printed but we do increment the cursor by one
;...............................................................................
PRINT_CHAR      BEQ PRINT_NOTHING       ;when the value = 0, we print nothing but we do increment the cursor by one
                ;CLC
                ;ADC CHAR_INVERT         ;invert character depending on the status of the  CHAR_INVERT-flag
                LDY #00                 ;
                STA (CHAR_ADDR),Y       ;character read from string (stored in A) is now written to screen memory (see C64 manual appendix E for screen display codes)

                ;increment character pointer
PRINT_NOTHING   CLC                     ;
                LDA #$01                ;add 1
                ADC CHAR_ADDR           ;                        
                STA CHAR_ADDR           ;
                LDA #$00                ;
                ADC CHAR_ADDR+1         ;add carry... and viola, we have a new cursor position (memory location where next character will be printed)
                STA CHAR_ADDR+1         ;

                RTS                     ;

;CHAR_INVERT     BYTE $0        ;flag to indicate whether or not the printed character should be inverted

;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX or COMMODOREPET80XX"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX
;-------------------------------------------------------------------------------
;Clear screen (no color memory needs to be set on a b/w or green-screen PET)
;this fills all 1000 screen locations (40x25) with the value "space"
;Example:       JSR CLEAR_SCREEN
;...............................................................................
CLEAR_SCREEN    LDY #0 
                LDA #$20                ;fill the screen with spaces
SETCHARACTER    STA CHARSCREEN+0,y      ;
                STA CHARSCREEN+256,y    ;
                STA CHARSCREEN+512,y    ;
                STA CHARSCREEN+745,y    ;            
                INY                     ;
                BNE SETCHARACTER        ;

                RTS                     ;

endif   ;this endif belongs to "ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET80XX
;-------------------------------------------------------------------------------
;Clear screen (no color memory needs to be set on a b/w or green-screen PET)
;this fills all 2000 screen locations (80x25) with the value "space"
;Example:       JSR CLEAR_SCREEN
;...............................................................................
CLEAR_SCREEN    LDY #0 
                LDA #$20                ;fill the screen with spaces
SETCHARACTER    STA CHARSCREEN+0,y      ;
                STA CHARSCREEN+256,y    ;
                STA CHARSCREEN+512,y    ;
                STA CHARSCREEN+768,y    ;            
                STA CHARSCREEN+1024,y   ;            
                STA CHARSCREEN+1280,y   ;            
                STA CHARSCREEN+1536,y   ;            
                STA CHARSCREEN+1744,y   ;            
                INY                     ;
                BNE SETCHARACTER        ;

                JSR $E01B               ;the easiest way is to make the black lines dissappear on an 80 column screen

                RTS                     ;

endif   ;this endif belongs to "ifdef COMMODOREPET80XX"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


