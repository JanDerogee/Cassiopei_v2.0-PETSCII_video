;bug in menu code? or perhaps a C64 feature?: the joystick in PORT-1 might
;trigger a selection when moving wildly with the joystick AND when the last
;item in the list has been selected, the list of items does not need to be
;long, a 4 item list in de TAP file section is enough

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODORE16PLUS4;testtext causing a problem, move comments to the next line to solve the problem

SCANKEY         = $FF9F         ;scankey, value is in A (no key pressed is 0xFF)
GETKEY          = $FFE4         ;Put relevant value into A


CHROUT          = $FFD2         ;

BORDER          = $FF19         ;bordercolour
BACKGROUND      = $FF15         ;background-0
CHARSCREEN      = $0C00         ;location of the character screen memory
COLORSCREEN     = $0800         ;location of the color screen memory (this value cannot change)

KEYCNT          = $EF           ;the counter that keeps track of the number of key in the keyboard buffer
KEYBUF          = $0527         ;the first position of the keyboard buffer

CURSORPOS_X     = 202           ;Cursor Column on Current Line (be aware that on some computers i.e. the C64, position the cursor does not take effect immediately, only when a CR on the keyboard is send it will go there)
CURSORPOS_Y     = 205           ;Current Cursor Physical Line Number

TODCLK          = $A3           ;Time-Of-Day clock register (MSB) (TIME:$00A3-00A5, Real-time jiffy clock (approx) 1/60 sec)
;TODCLK+1       = $A1           ;Time-Of-Day clock register (.SB)
;TODCLK+2       = $A2           ;Time-Of-Day clock register (LSB)

;###############################################################################

;-- keycodes --
KEY_NOTHING     = $FF           ;when no key is pressed
KEY_F1          = $05
KEY_F2          = $09
KEY_F3          = $06
;KEY_RETURN      = $0D

;-------------------------------------------------------------------------------
;Read the keyboard and joystick, this routine converts the keycode to a control
;code that is easier to decode. This value is stored in A
;...............................................................................
SCAN_INPUTS     LDA ALLOW_KEYREPEAT     ;some functions/keys have keyrepeat, this makes it easier to scroll
                BNE SCAN_KEYPRESS       ;through a long list of filenames

SCAN_JOYRELEASE SEI                     ;disable interrupts, otherwise the keyboard scanning routine will screw things up
SCAN_JOYREL_LP1 LDA #$FF                ;this is crucial! because if we don't write $FF to $FD30 then
                STA $FD30               ;the F3 button would suddenly trigger the EXIT function (like presing fire or the escape button in the menu)
                LDA #$FA                ;$FA selects joy-1
                STA $FF08               ;write value to register to enable the joystick
                LDA $FF08               ;get the value of the selected joystick
                AND #%01000000          ;
                BEQ SCAN_JOYREL_LP1     ;keep looping until fire button is released                
                CLI                     ;enable interrupts again 

                SEI                     ;disable interrupts, otherwise the keyboard scanning routine will screw things up
SCAN_JOYREL_LP2 LDA #$FF                ;this is crucial! because if we don't write $FF to $FD30 then
                STA $FD30               ;the F3 button would suddenly trigger the EXIT function (like presing fire or the escape button in the menu)
                LDA #$FD                ;$FD selects joy-2
                STA $FF08               ;write value to register to enable the joystick
                LDA $FF08               ;get the value of the selected joystick
                CLI                     ;enable interrupts again 
                AND #%10000000          ;
                BEQ SCAN_JOYREL_LP2     ;keep looping until fire button is released                

SCAN_KEYRELEASE JSR SCANKEY             ;scankey, value is in A (no key pressed is 0xFF)
                CMP #KEY_NOTHING        ;check for "no key"
                BNE SCAN_KEYRELEASE     ;continue loop when key is still pressed
SCAN_KEYPRESS   JSR SCANKEY             ;scankey, value is in A (no key pressed is 0xFF)
                CMP #KEY_F1             ;
                BEQ SCAN_VAL_PREV       ;
                CMP #KEY_F2             ;
                BEQ SCAN_VAL_SELECT     ;
                CMP #KEY_F3             ;
                BEQ SCAN_VAL_NEXT       ;

SCAN_JOYSTICK   SEI                     ;disable interrupts, otherwise the keyboard scanning routine will screw things up
                LDA #$FF                ;this is crucial! because if we don't write $FF to $FD30 then
                STA $FD30               ;the F3 button would suddenly trigger the EXIT function (like presing fire or the escape button in the menu)
                LDA #$FA                ;$FA selects joy-1
                STA $FF08               ;write value to register to enable the joystick
                LDA $FF08               ;get the value of the selected joystick
                CLI                     ;enable interrupts again 
                CMP #%11111110          ;up of joy#1
                BEQ SCAN_VAL_PREV       ;
                CMP #%10111111          ;fire of joy#1
                BEQ SCAN_VAL_SELECT     ;
                CMP #%11111101          ;down of joy#1
                BEQ SCAN_VAL_NEXT       ;

                SEI                     ;disable interrupts, otherwise the keyboard scanning routine will screw things up
                LDA #$FF                ;this is crucial! because if we don't write $FF to $FD30 then
                STA $FD30               ;the F3 button would suddenly trigger the EXIT function (like presing fire or the escape button in the menu)
                LDA #$FD                ;$FD selects joy-2
                STA $FF08               ;write value to register to enable the joystick
                LDA $FF08               ;get the value of the selected joystick
                CLI                     ;enable interrupts again 
                CMP #%11111110          ;up of joy#2
                BEQ SCAN_VAL_PREV       ;
                CMP #%01111111          ;fire of joy#2
                BEQ SCAN_VAL_SELECT     ;
                CMP #%11111101          ;down of joy#2
                BEQ SCAN_VAL_NEXT       ;

SCAN_VAL_IDLE   LDA #1                  ;allow keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_IDLE    ;nothing happened, send idle value
                RTS                     ;

SCAN_VAL_SELECT LDA #0                  ;do not allow keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_SELECT  ;
                RTS                     ;

SCAN_VAL_PREV   LDA #1                  ;allow keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_PREVIOUS;
                RTS                     ;

SCAN_VAL_NEXT   LDA #1                  ;allow keyrepeat on this button
                STA ALLOW_KEYREPEAT     ;
                LDA #USER_INPUT_NEXT    ;
                RTS                     ;

ALLOW_KEYREPEAT BYTE $0 ;this is a flag that indicates if keyrepeat is allowed (0=key repeat not alowed, 1=key repeat alowed)

;-------------------------------------------------------------------------------
;This routine will have the Z-flag set when no key is pressed
;call example   JSR CHECK_FOR_KEY
;               BNE <jump to wherever because a key was pressed>
;...............................................................................
CHECK_FOR_KEY   JSR SCANKEY             ;scankey, value is in A (no key pressed is 0xFF)
                CMP #KEY_NOTHING        ;check for "no key"
                RTS                     ;

;-------------------------------------------------------------------------------
;This routine will wait until the user presses a key
;call example   JSR WAIT_FOR_KEY
;...............................................................................
WAIT_FOR_KEY    JSR SCANKEY             ;scankey, value is in A (no key pressed is 0xFF)
                CMP #KEY_NOTHING        ;check for "no key"
                BNE WAIT_FOR_KEY        ;continue loop when key is still pressed

;-------------------------------------------------------------------------------
;Clear screen and set the color of the colorscreen
;Example:       JSR CLEAR_SCREEN
;...............................................................................
;-------------------------------------------------------------------------------
;clear screen and "paint it black" (just like the stones did)

CLEAR_SCREEN    LDA #0                  ;make the screen and border black
                STA BORDER              ;
                STA BACKGROUND          ;

                LDY #0 
                LDA #$20                ;fill the screen with spaces
SETCHARACTER    STA CHARSCREEN+0,y      ;
                STA CHARSCREEN+256,y    ;
                STA CHARSCREEN+512,y    ;
                STA CHARSCREEN+745,y    ;            
                INY                     ;
                BNE SETCHARACTER        ;

                LDY #0                  ;
                LDA #$71                ;make all the characterpositions white
SETTEXTCOLOR    STA COLORSCREEN+0,y     ;
                STA COLORSCREEN+256,y   ;
                STA COLORSCREEN+512,y   ;
                STA COLORSCREEN+745,y   ;            
                INY                     ;
                BNE SETTEXTCOLOR        ;


SET_CHARACT_SET LDA $FF07               ;
                ORA #%10000000          ;force to 256 characters charset, this also DISABLEs case changes caused by pressing CBM+shift
                STA $FF07               ;(by forcing to a 256 chars charset we set the font to the default case)

                LDA $FF12               ;First we have to tell that the characters should be fetched from RAM.
                AND #%11111011          ;
                STA $FF12               ;

                LDA $FF13               ;then we must tell the TED where the charset is located
                AND #%00000011          ;Bits 2-7 (of $FF13) determine, which page should be used
                ORA #%00100000          ;charset located at mem loc. $2000
                STA $FF13               ;

                RTS                     ;

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

                LDA #40                 ;add  40 (which is the number of characters per line for most commodore computers) to calculate the new Y position of cursor
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
                STA (CHAR_ADDR),Y       ;

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
                LDA $FF07               ;
                ORA #%10000000          ;force to 256 characters charset, this also DISABLEs case changes caused by pressing CBM+shift
                STA $FF07               ;(by forcing to a 256 chars charset we set the font to the default case)

                ;charset settings
         ;       LDA $FF12               ;First we have to tell that the characters should be fetched from RAM.
         ;       AND #%11111011          ;
         ;       STA $FF12               ;

         ;       LDA $FF13               ;then we must tell the TED where the charset is located
         ;       AND #%00000011          ;Bits 2-7 (of $FF13) determine, which page should be used
         ;       ORA #%00100000          ;charset located at mem loc. $2000
         ;       STA $FF13               

                RTS                     ;

;-------------------------------------------------------------------------------
;Allow the use of shift+CBM to change the case of the screen.
;Example:       JSR ALLOW_CASE_CHANGE
;...............................................................................                
ALLOW_CASE_CHANGE
                LDA #$08                ;default value
                STA $FF07               ;charset details

                ;charset settings
          ;      LDA #$C4                ;default value
          ;      STA $FF12               ;charset location
                
          ;      LDA #$D0                ;default value
          ;      STA $FF13               ;then we must tell the TED where the charset is located


                LDA #$71                ;set chracter color ($70=brightest luminance, $01=white) because the screen is black and C16 default charcolor is also black
                STA $053B               ;COLOR ($053B) Active attribute byte
              
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



;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;                                                  CHARSET
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;the C16 and plus4 require a hardware bit to be set in order to invert a character
;which is different then the other commodores, so to keep it simple, just use a charset
;that has inverted chars in the same way and the problem is solved

*=$2000

incbin "C16_CHARS.bin",0          ;skip the first ... bytes of the file


;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODORE16PLUS4"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
