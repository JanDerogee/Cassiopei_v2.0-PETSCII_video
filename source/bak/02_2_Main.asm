;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREVIC20
;-------------------------------------------------------------------------------

SCAN_KEYBOARD   = $FF9F ;scans the keyboard and puts the matrix value in $C5
CHROUT          = $FFD2 ;

KEYCNT          = 198           ;the counter that keeps track of the number of key in the keyboard buffer       VIC-20
KEYBUF          = 631           ;the first position of the keyboard buffer                                      VIC-20
CURSORPOS_X     = 198           ;Cursor Column on Current Line                                                  PET/CBM (Upgrade and 4.0 BASIC)
CURSORPOS_Y     = 216           ;Current Cursor Physical Line Number                                            PET/CBM (Upgrade and 4.0 BASIC)

TODCLK          = $8D           ;Time-Of-Day clock register (MSB) BASIC>1 uses locations 141-143 ($8D-$8F)
;TODCLK+1       = $8E           ;Time-Of-Day clock register (.SB)
;TODCLK+2       = $8F           ;Time-Of-Day clock register (LSB)


;###############################################################################

;-- keycodes -- (VIC20 keyboard scanning values)

KEY_NOTHING     = $40           ;matrix value when no key is pressed

KEY_F3          = $2F
KEY_F5          = $37
KEY_F7          = $3F
;-------------------------------------------------------------------------------
;Read the keyboard and joystick, this routine converts the keycode to a control
;code that is easier to decode. This value is stored in A

;unfortunately the VIC20 keyboard does not always produce reliable results,
;therefore the matrix value is used with a simple consistency check algorithm
;that will filter out erronous values.
;...............................................................................
SCAN_INPUTS     LDA ALLOW_KEYREPEAT     ;some functions/keys have keyrepeat, this makes it easier to scroll
                BNE SCAN_KEYPRESS       ;through a long list of filenames

SCAN_KEYRELEASE JSR $EB1E               ;use kernal routine to scan VIC20 keyboard
                LDA $CB                 ;
                CMP #KEY_NOTHING        ;check for the "no key pressed" situation
                BNE SCAN_KEYRELEASE     ;when the keyboard isn't released, we may asume that the user is still pressing the same key, perhaps so we repeat the input (and by that we create key repeat functionality)

SCAN_KEYPRESS   LDA #8                  ;number of times the matrix value should be the same in order to detect a key as valid
                STA DEBOUNCE_CNT        ;
                JSR $EB1E               ;use kernal routine to scan VIC20 keyboard
                LDA $CB                 ;current matrix value
                STA DEBOUNCE_CURRENT    ;save current value
                CMP #KEY_NOTHING        ;check for the "no key pressed" situation
                BEQ SCAN_JOYSTICK       ;no keyboard action, check joystick

SCAN_KEY_LP     JSR $EB1E               ;use kernal routine to scan VIC20 keyboard
                LDA $CB                 ;current matrix value, compare this to the previous
                CMP DEBOUNCE_CURRENT    ;value, if this value stays the same for .. time in a row
                BNE SCAN_JOYSTICK       ;then it must be correct and we may process that value
                DEC DEBOUNCE_CNT        ;
                LDA DEBOUNCE_CNT        ;
                BNE SCAN_KEY_LP         ;keep looping until counter reaches 0

                LDA DEBOUNCE_CURRENT    ;
                CMP #KEY_F3             ;
                BEQ SCAN_VAL_PREV       ;
                CMP #KEY_F5             ;
                BEQ SCAN_VAL_SELECT     ;
                CMP #KEY_F7             ;
                BEQ SCAN_VAL_NEXT       ; 

SCAN_JOYSTICK   ;LDA #$00                ;make sure that inputs are set as inputs
                LDA #$80                ;ATN (bit-7) is output, the rest is input
                STA $9113               ;

                LDA $9111               ;joy#1
                AND #%00101100          ;mask out joystick signals before checking
                CMP #%00101100          ;is in a position other then the center position
                BEQ SCAN_EXIT           ;if not then we exit immediately

                LDA #160                ;
                STA DEBOUNCE_CNT        ;
                LDA $9111               ;joy#1
                AND #%00101100          ;mask out joystick signals
                STA DEBOUNCE_CURRENT    ;
SCAN_JOY_LP     LDA $9111               ;joy#1
                AND #%00101100          ;mask out joystick signals
                CMP DEBOUNCE_CURRENT    ;
                BNE SCAN_EXIT           ;
                DEC DEBOUNCE_CNT        ;
                BEQ SCAN_JOY_LP         ;keep looping (until we reach the thresshold) if the joystick stays the same...

                LDA #%00100000          ;fire
                BIT $9111               ;joy#1
                BEQ SCAN_VAL_SELECT     ;

                LDA #%00000100          ;up
                BIT $9111               ;joy#1
                BEQ SCAN_VAL_PREV       ;

                LDA #%00001000          ;down
                BIT $9111               ;joy#1
                BEQ SCAN_VAL_NEXT       ;

SCAN_EXIT       LDA #1                  ;allow keyrepeat in order to react better to keypresses (because there is no check for releasing screwing things up)
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_IDLE    ;nothing happened, send idle value
                RTS

SCAN_VAL_SELECT LDA #0                  ;do not allow keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_SELECT  ;
                RTS

SCAN_VAL_PREV   LDA #1                  ;allow keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_PREVIOUS;
                RTS

SCAN_VAL_NEXT   LDA #1                  ;allow keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_NEXT    ;
                RTS

ALLOW_KEYREPEAT         BYTE $0 ;this is a flag that indicates if keyrepeat is allowed (0=key repeat not alowed, 1=key repeat alowed)
DEBOUNCE_CNT            BYTE $0 ;use for debouncing
DEBOUNCE_CURRENT        BYTE $0 ;use for debouncing


;-------------------------------------------------------------------------------
;This routine will have the Z-flag set when no key is pressed
;unfortunately, keyboard and Cassiopei don't work together...
;so this routine fakes the "no key pressed" situation in order to compile properly
;...............................................................................
CHECK_FOR_KEY LDA #00 
              RTS

;-------------------------------------------------------------------------------
;This routine will wait until the user presses a key
;call example   JSR WAIT_FOR_KEY
;...............................................................................
WAIT_FOR_KEY    JSR $EB1E               ;use kernal routine to scan VIC20 keyboard
                LDA $CB                 ;
                CMP #KEY_NOTHING        ;check for the "no key pressed" situation
                BEQ WAIT_FOR_KEY        ;continue loop when no key is detected
                RTS                     ;

;-------------------------------------------------------------------------------
;Clear screen and set the color of the colorscreen
;Example:       JSR CLEAR_SCREEN
;...............................................................................
CLEAR_SCREEN    LDA #$08                ;make the screen and border black
                STA $900F               ;

                LDA #5                  ;PRINT CHR$(5) TO SET PRINTING COLOUR TO WHITE (this is the colour used with the KERNAL printing routine)
                JSR CHROUT              ;SCREEN
                LDA #147                ;PRINT CHR$(147) TO CLEAR
                JSR CHROUT              ;SCREEN
                RTS                     ;

;-------------------------------------------------------------------------------
; The first location of the charsecreen (topleft) is defined as coordinate 0,0
; Use this routine before calling a PRINT related routine
;               LDX CURSOR_Y;.. chars from the top of the defined screen area
;               LDY CURSOR_X;.. chars from the left of the defined screen area
;               JSR SET_CURSOR
;...............................................................................

SET_CURSOR      LDA #00                 ;
                STA CHAR_ADDR           ;store base address (low byte)
                LDA $0288               ;the location (high byte) of the screen as determined by the kernal
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

                LDA #22                 ;add  22 (which is the number of characters per line for a VIC20) to calculate the new Y position of cursor
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
;Prevent the use of shift+CBM to change the case of the screen.
;This must be prevented when screen are build with special characters.
;Example:       JSR PREVENT_CASE_CHANGE
;...............................................................................                
PREVENT_CASE_CHANGE
                LDA #128                ;disable shift+CBM
                STA $0291               ;

                RTS                     ;

;-------------------------------------------------------------------------------
;Allow the use of shift+CBM to change the case of the screen.
;Example:       JSR ALLOW_CASE_CHANGE
;...............................................................................                
ALLOW_CASE_CHANGE
                LDA #0                  ;enable shift+CBM
                STA $0291               ;
              
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
PRG_IDENTIFIER      ;'0123456789ABCDEF'
                TEXT 'petscii player:vic20' ;if the wrong menu PRG is installed onto the cassiopei, this message could be valuable hint in solving the problem also usefull for debugging on vice, then the screen is no longer completely empty and you know that something has happened
                BYTE 0;end of table marker


;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODOREVIC20"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
