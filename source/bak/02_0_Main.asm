;===============================================================================
;                              MAIN PROGRAM
;===============================================================================

INIT            JSR PREVENT_CASE_CHANGE ;prevent the user from using shift+CBM to change the case into lower or upper case
                JSR CLEAR_SCREEN        ;

                JSR CPIO_INIT           ;initialize IO for use of CPIO protocol on the CBM's cassetteport
                JSR BROWSE_RESET        ;force the cassiopei menu to a default state

;                LDX #0                  ;show the current charset
;                LDY #0                  ;
;                JSR SET_CURSOR          ;
;                LDX #00                 ;
;TSTLP           TXA                     ;
;                JSR PRINT_CHAR          ;
;                INX                     ;
;                BNE TSTLP               ;
;ENDLESS         JMP ENDLESS             ;
;        

MAIN_MENU       LDX #0                  ;build the screen
                LDY #0                  ;
                JSR SET_CURSOR          ;
                LDA #<SCREEN_MENU       ;set pointer to the text that defines the main-screen
                LDY #>SCREEN_MENU       ;
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen         
                JSR SHOW_VERSION        ;show version info

                JSR BROWSE_REFRESH      ;get the current available menu screen and print it to the screen
;. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

SCAN_USER_INPUT LDA BROWSE_STATUS       ;check if we should exit
                CMP #BROWSE_EXIT        ;exit menu (meaning that a selection has been made)
                BEQ EXECUTE_PLAY        ;

                JSR SCAN_INPUTS         ;check keyboard and/ joysticks (if applicable)
                CMP #USER_INPUT_SELECT  ;and jump to the requested action
                BEQ EXECUTE_SELECT      ;
                CMP #USER_INPUT_PREVIOUS;
                BEQ EXECUTE_PREV        ;
                CMP #USER_INPUT_NEXT    ;
                BEQ EXECUTE_NEXT        ;

                JMP SCAN_USER_INPUT     ;when the pressed key has no function then continue the key scanning

;. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

EXECUTE_SELECT  JSR BROWSE_SELECT       ;
                JMP SCAN_USER_INPUT     ;

EXECUTE_PREV    JSR BROWSE_PREVIOUS     ;
                JMP SCAN_USER_INPUT     ;

EXECUTE_NEXT    JSR BROWSE_NEXT         ;
                JMP SCAN_USER_INPUT     ;

EXECUTE_PLAY    JSR PLAY_VQ_ANIM        ;play the video
                JMP MAIN_MENU           ;when done playing, allow user to select another file

;===============================================================================
;                             - = SUBROUTINES = -
;===============================================================================

;-------------------------------------------------------------------------------
;Call the corresponding menu function below and it will be printed to the screen
;-------------------------------------------------------------------------------

BROWSE_REFRESH  LDA #CPIO_BROWSE_REFRESH;Refresh: will only get the menu information from the Cassiopei's screen buffer
                STA BROWSE_ACTION       ;store the menu action to memory
                JMP BROWSE_00           ;

BROWSE_PREVIOUS LDA #CPIO_BROWSE_PREVIOUS;Previous: will perform a previous action in the menu, scolling the items down (or moving the indicator up)
                STA BROWSE_ACTION       ;store the menu action to memory
                JMP BROWSE_00           ;

BROWSE_SELECT   LDA #CPIO_BROWSE_SELECT ;Select: will perform a selection of the currently selected menu item
                STA BROWSE_ACTION       ;store the menu action to memory
                JMP BROWSE_00           ;

BROWSE_NEXT     LDA #CPIO_BROWSE_NEXT   ;Next: will perform a next action in the menu, scolling the items up (or moving the indicator down)
                STA BROWSE_ACTION       ;store the menu action to memory
                JMP BROWSE_00           ;

BROWSE_RESET    LDA #CPIO_BROWSE_RESET  ;Reset the menu, forcing it to the beginning state
                STA BROWSE_ACTION       ;store the menu action to memory
                LDA #CPIO_BROWSE        ;send directory read command
                JSR CPIO_START          ;
                LDA BROWSE_ACTION       ;get the menu action from memory                
                JSR CPIO_SEND           ;send the menu action to the Cassiopei
                LDA #WINDOW_X_SIZE      ;send the size of the visble screen area
                JSR CPIO_SEND           ;on the CBM computer
                LDA #WINDOW_Y_SIZE      ;
                JSR CPIO_SEND           ;
                JSR CPIO_REC_LAST       ;get the menu status byte
                STA BROWSE_STATUS       ;the status byte indicates wheter or not the menu is still active, because the user might have select exit
                CLI                     ;allow interrupts (usefull for keyboard and other things)
                RTS                     ;

;...............................................................................

BROWSE_00       LDA #WINDOW_X_POS       ;the location of the first character of the info on the screen
                STA BROWSE_CURX         ;
                LDA #WINDOW_Y_POS       ;
                STA BROWSE_CURY         ;

                LDA #WINDOW_Y_SIZE      ;the number of characters we will (may) display on a single line
                STA BROWSE_MAXY         ;
                LDA #CPIO_BROWSE        ;send directory read command
                JSR CPIO_START          ;
                LDA BROWSE_ACTION       ;get the menu action from memory
                JSR CPIO_SEND           ;send the menu action to the Cassiopei
                LDA #WINDOW_X_SIZE      ;send the size of the visble screen area
                JSR CPIO_SEND           ;on the CBM computer
                LDA #WINDOW_Y_SIZE      ;
                JSR CPIO_SEND           ;
                JSR CPIO_RECIEVE        ;get the menu status byte
                STA BROWSE_STATUS       ;the status byte indicates whether or not the menu is still active, because the user might have select exit

BROWSE_03       LDA #WINDOW_X_SIZE      ;the max length of a file name
                STA BROWSE_MAXX         ;
                LDX BROWSE_CURX         ;
                LDY BROWSE_CURY         ;
                JSR SET_CURSOR          ;

BROWSE_04       LDA BROWSE_MAXX         ;check if this is the last byte that should be drawn on this line
                CMP #1                  ;
                BEQ BROWSE_05           ;
                JSR CPIO_RECIEVE        ;get byte from Cassiopei containing the screen data
                JMP BROWSE_07           ;
BROWSE_05       LDA BROWSE_MAXY         ;check if this REALLY is the last byte we will be reading (regarding this command)
                CMP #1                  ;
                BEQ BROWSE_06           ;
                JSR CPIO_RECIEVE        ;get byte from Cassiopei containing the screen data
                JMP BROWSE_07           ;
BROWSE_06       JSR CPIO_REC_LAST       ;last byte before communication stops

BROWSE_07       JSR PRINT_CHAR          ;character is printed to screen, cursor is incremented by one
                DEC BROWSE_MAXX         ;keep looping untill we have processed the full width of the text area
                BNE BROWSE_04           ;

BROWSE_08       INC BROWSE_CURY         ;the next entry will be written on the next line in the directory text area
                DEC BROWSE_MAXY         ;keep looping untill we have processed the full length of the text area
                BNE BROWSE_03           ;
                
BROWSE_END      CLI                     ;CPIO communication has disabled interrupts, so we must enable interrupts again. Otherwise the keyboard is not scanned etc.
                RTS                     ;

;===============================================================================
;this routine will play the Vector compressed PETSCII animation
;-------------------------------------------------------------------------------
PLAY_VQ_ANIM    JSR OPEN_FILE           ;open the data file
                BCC PLAY_START          ;all OK, continue to loading header
                RTS                     ;

PLAY_START                    
PLAY_FRAME      JSR CHECK_FOR_KEY       ;check the keyboard, if key pressed, the exit
                BNE PLAY_EXIT           ;key pressed? then exit

                JSR LOAD_FRAME          ;load image to buffer

                SEC                     ;set carry (required in order to detect an underflow)
                LDA NMBR_OF_FRAMES      ;low byte of remaining frame counter
                SBC #$01                ;decrement by one
                STA NMBR_OF_FRAMES      ;store result
                LDA NMBR_OF_FRAMES+1    ;high  byte of remaining frame counter
                SBC #$00                ;process the carry
                STA NMBR_OF_FRAMES+1    ;store result
                BNE PLAY_FRAME          ;remaining frames > 0, continue showing frames
                LDA NMBR_OF_FRAMES      ;check the low byte
                BNE PLAY_FRAME          ;remaining frames > 0, continue showing frames
                ;the file we've read contains no frames (or all frames have been shown), so we exit!

PLAY_EXIT       JSR CPIO_REC_LAST       ;a dummy read because CPIO communication requires to be closed first (we close doing a REC_LAST)
                JSR CLOSE_DATAFILE      ;closing the current file
                RTS                     ;

;-------------------------------------------------------------------------------
;This routine will open the file and read it's header
; When this failes , the carry is set
;
;when the file is found, it remains ready for data transfer, the CPIO connection
;is not closed and therefore interrupts remain disabled. Just make sure you start
;reading before the CPIO-time out occurs
;...............................................................................
;FILENAME        ;Filename must be specified in ASCII characters, because the SD-card or to be more precise... THE WHOLE MODERN WORLD!!! uses ASCII
;                ;make sure that the filename is fully specified! Supported characters are:
;                ; 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()-+<>,.?
;                ; the / character is to used for entering (sub)directories
;                ; using other characters then above will lead to a file-not-found situation

;                ;the ' -character surrounding the string indicates that it will be using the PETSCII- or SCREEN-codes (DO NOT USE THAT HERE!!!)
;                ;the " -character surrounding the string indicates that it will be using the ASCII-codes (which usually do not properly display as they (non-numerical characters) differ from screencodes)*/
;                ;Attention: only use lower case characters, they will result in uppercase characters on the receiving end!!
;                ;fortunately the cassiopei itself isn't case sensitive and will load independent of the casetype

;                ;TEXT "normal.dat"
;                ;TEXT "delta.dat"
;                ;TEXT "animatie.dat"
;                TEXT "amiga-tribute.dat"
;                BYTE 0

OPEN_FILE       LDA #CPIO_DATAFILE_OPEN ;the mode we want to operate in
                JSR CPIO_START          ;send this command so the connected device knows we now start working in this mode
                LDA #0                  ;0=read from file
                JSR CPIO_SEND           ;
                JSR CPIO_REC_LAST       ;the cassiopei responds with a 0=file-not-found, 1=file-found, do not drop attention as we want to continue loading data
                STA FILE_OPEN_STATUS    ;

                LDA FILE_OPEN_STATUS    ;
                BNE CHECK_HEADER        ;0=file-not-found, 1=file found (when file is found we may check its header for the magic word)
FILE_NOT_FOUND  JSR CLOSE_DATAFILE      ;closing the current file
                JSR ERROR_FILENOTFOUND  ;file not found
                SEC                     ;set the carry to indicate we could not open the requested file
                RTS                     ;exit immediately

                ;........................

CHECK_HEADER    LDA #CPIO_DATAFILE_READ ;prepare for reading
                JSR CPIO_START          ;send this command so the connected device knows we now start working in this mode

CHECK_MAGICWORD LDA #0                  ;before we continue we must check for the magic word, because if it isn't there then we are interpreting the wrong type of file and we should exit
                STA LOOPCOUNT           ;
CH_MAGICWORD_01 JSR CPIO_RECIEVE        ;get the version of the VQImage file
                LDX LOOPCOUNT           ;
                CMP MAGICWORD,X         ;
                BNE CH_MAGICW_FAIL      ;exit when other things then the magic word are found
                INC LOOPCOUNT           ;
                LDA LOOPCOUNT           ;
                CMP #12                 ;the magic word consists of 12 characters
                BNE CH_MAGICWORD_01     ;
                JMP CH_TYPE             ;the magic word is found, so this is very likely to be a PETSCII video file, continue to check the filetype

CH_MAGICW_FAIL  JSR CPIO_REC_LAST       ;do a dummy read, in order to shutdown reading in a normal manor (suddenly dropping attention (using CPIO_INIT) will lead to a timeout and missing of the next command) 
                JSR CLOSE_DATAFILE      ;closing the current file
                JSR ERROR_NOT_VIDEOFILE ;the selected file is not a PETSCIIVIDEO file
                SEC                     ;
                RTS                     ;exit immediately

                ;........................

CH_TYPE         JSR CPIO_RECIEVE        ;get the version of the VQImage file
                STA FILETYPE            ;save to RAM
                CMP #$01                ;check for filetype, if anything else... exit!!
                BEQ CH_NMBR_FRAMES      ;when ok, continue to the next item in the header
CH_TYPE_FAIL    JSR CPIO_REC_LAST       ;do a dummy read, in order to shutdown reading in a normal manor (suddenly dropping attention (using CPIO_INIT) will lead to a timeout and missing of the next command) 
                JSR CLOSE_DATAFILE      ;closing the current file
                JSR ERROR_NOTSUPPORTED  ;filetype not supported
                SEC                     ;carry set indicates that the filetype isn't supported
                RTS                     ;exit immediately

                ;........................

CH_NMBR_FRAMES  JSR CPIO_RECIEVE        ;get the number of images stored in this file high byte
                STA NMBR_OF_FRAMES+1    ;save to RAM
                JSR CPIO_RECIEVE        ;get the number of images stored in this file low byte
                STA NMBR_OF_FRAMES      ;save to RAM

                ;........................

CH_SIZE
CH_SIZE_X       JSR CPIO_RECIEVE        ;get the X-size (in tiles)
                STA X_SIZE              ;
CH_SIZE_Y       JSR CPIO_RECIEVE        ;get the Y-size (in tiles)
                STA Y_SIZE              ;

                LDA X_SIZE              ;
                CMP #SUPPORTED_X_SIZE   ;check if this value matches the computers native screen resolution
                BNE CH_SIZE_FAIL        ;failure the print error message
                LDA Y_SIZE              ;
                CMP #SUPPORTED_Y_SIZE   ;check if this value matches the computers native screen resolution
                BEQ CH_OTHER            ;continue if OK, print error on failure

CH_SIZE_FAIL    JSR CPIO_REC_LAST       ;do a dummy read, in order to shutdown reading in a normal manor (suddenly dropping attention (using CPIO_INIT) will lead to a timeout and missing of the next command) 
                JSR CLOSE_DATAFILE      ;closing the current file
                CLI                     ;enable interrupts again (required for keyboard readout)
                JSR ERROR_WRONGSIZE     ;file is intended to be played back on a different screen size then the native screen size of this computer
                SEC                     ;carry set indicates that the filetype isn't supported
                RTS                     ;exit immediately

                ;........................

CH_OTHER        JSR CPIO_RECIEVE        ;
               ; STA CODEBOOKSIZE        ;-reserved for future use-

                JSR CPIO_RECIEVE        ;
               ; STA RESERVED_01         ;-reserved for future use-

                JSR CPIO_RECIEVE        ;
               ; STA RESERVED_02         ;-reserved for future use-

                JSR CPIO_RECIEVE        ;
               ; STA RESERVED_03         ;-reserved for future use-

                JSR CPIO_RECIEVE        ;
               ; STA RESERVED_04         ;-reserved for future use-

                ;........................

CHECK_HDR_OK    CLC                     ;carry cleared indicates that all is OK
                RTS                     ;


;-------------------------------------------------------------------------------
;close the current file
;...............................................................................
CLOSE_DATAFILE  LDA #CPIO_DATAFILE_CLOSE;close the file, we are done using it
                JSR CPIO_START          ;send this command so the connected device knows we now start working in this mode
                LDA #0                  ;
                JSR CPIO_SEND_LAST      ;send a dummy to close CPIO communication in a normal manor
                CLI                     ;allow interrupts (usefull for keyboard and other things)

                RTS
;-------------------------------------------------------------------------------
;load an image (or frame) from the file, when the file has just been opened we load the first
;when we call this routine again we load the next, etc.
;...............................................................................
LOAD_FRAME      JSR CPIO_RECIEVE        ;get the mode byte
                STA MODE_BYTE           ;

                LDA MODE_BYTE           ;
                AND #%10000000          ;mask out bit-7 (0=normal mode, 1=delta mode)
                BEQ NORMAL_MODE         ;
                JMP DELTA_MODE          ;

;------------                           
ifdef COMMODOREVIC20
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> (the VIC20 has a charscreen that could be anywhere depeninding on the memory config)
NORMAL_MODE     LDA #00                 ;the low byte of the screen
                STA ADDR                ;low byte of destination address
                STA ADDR_LAST_TILE      ;
                LDA $0288               ;the high byte of the screen as determined by the kernal
                STA ADDR+1              ;high byte of destination address                
                STA ADDR_LAST_TILE+1    ;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
endif

ifdef COMMODOREPET20XX OR COMMODOREPET30XX OR COMMODOREPET40XX OR COMMODOREPET80XX OR COMMODORE64 OR COMMODORE128 OR COMMODORE16PLUS4
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 
NORMAL_MODE     LDA #<CHARSCREEN        ;the destination of the data
                STA ADDR                ;low byte of destination address
                STA ADDR_LAST_TILE      ;
                LDA #>CHARSCREEN        ;
                STA ADDR+1              ;high byte of destination address                
                STA ADDR_LAST_TILE+1    ;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
endif
                ;calculate the memory address of the last tile by adding the number of tiles to the start address
                LDY Y_SIZE              ;based on the information extracted from the 
                LDX X_SIZE              ;header of the image file.
NORM_CALC_TILES TXA                     ;
                CLC                     ;clear carry
                ADC ADDR_LAST_TILE      ;calculate
                STA ADDR_LAST_TILE      ;save
                LDA #$00                ;
                ADC ADDR_LAST_TILE+1    ;add carry (if there was one)
                STA ADDR_LAST_TILE+1    ;save
                DEY                     ;
                BNE NORM_CALC_TILES     ;

                
NORM_LOAD_LOOP  JSR CPIO_RECIEVE        ;
                LDY #$00                ;CPIO_RECEIVE affects the Y registers, so we need to set it to zero here
                STA (ADDR),Y            ;store byte read from file to the requested memory location

                INC ADDR                ;
                BNE NORM_LOAD_LP_02     ;therefore we calculate using Y instead of ADDR in order to keep the loop time as short as possible
                INC ADDR+1              ;


NORM_LOAD_LP_02 LDA ADDR_LAST_TILE      ;check if the current tile address is also the last tile address
                CMP ADDR                ;because is this is the case, then we are done loading this frame
                BNE NORM_LOAD_LOOP      ;
                LDA ADDR_LAST_TILE+1    ;
                CMP ADDR+1              ;
                BNE NORM_LOAD_LOOP      ;

NORMAL_EXIT     RTS                     ;all frame data loaded, return to caller

;-------------------------------------------------------------------------------
ifdef COMMODOREVIC20
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> (the VIC20 has a charscreen that could be anywhere depeninding on the memory config)
DELTA_MODE      LDA #00                 ;the low byte of the screen
                STA ADDR                ;low byte of destination address
                LDA $0288               ;the high byte of the screen as determined by the kernal
                STA ADDR+1              ;high byte of destination address                
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
endif

ifdef COMMODOREPET20XX OR COMMODOREPET30XX OR COMMODOREPET40XX OR COMMODOREPET80XX OR COMMODORE64 OR COMMODORE128 OR COMMODORE16PLUS4
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 
DELTA_MODE      LDA #<CHARSCREEN        ;the destination of the data
                STA ADDR                ;low byte of destination address
                LDA #>CHARSCREEN        ;
                STA ADDR+1              ;high byte of destination address                
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
endif

CMD_LOAD_LP_10  JSR CPIO_RECIEVE        ;get relative position of the changed tile (this is the first changed tile in the frame, the position value could be 0)
                JMP CMD_LOAD_LP_13      ;therefore the first byte read in a new frame should not be checked for 0

CMD_LOAD_LP_11  

CMD_LOAD_LP_12  JSR CPIO_RECIEVE        ;get relative position of the changed tile (this value is never 0, if it is, it indicates the end of the frame and we must stop loading data)
                BEQ CMD_LOAD_DELAY      ;end-of-frame detected, (almost) exit loop
CMD_LOAD_LP_13  CLC                     ;clear carry
                ADC ADDR                ;add the position to the current address
                STA ADDR                ;save result by adding the delta position in the screen/frame to
                LDA #$00                ;the current screen/frame position
                ADC ADDR+1              ;
                STA ADDR+1              ;

                JSR CPIO_RECIEVE        ;get the tile value
                LDY #$00                ;CPIO_RECEIVE affects the Y registers, so we need to set it to zero here
                STA (ADDR),Y            ;store byte read from file to the requested memory location                

                JMP CMD_LOAD_LP_11      ;keep looping

                
CMD_LOAD_DELAY  JSR CPIO_RECIEVE        ;get the delay value, because this frame might not be visible long enough if we don't
                STA FRAME_DELAY         ;
                BEQ DELTA_EXIT          ;test if there is a delay required (0 means no delay)

CMD_FRAME_DELAY LDX #$50                ;
CMD_FRAME_D_01  NOP                     ;
                NOP                     ;
                DEX                     ;
                BNE CMD_FRAME_D_01      ;

CMD_LOAD_LP_14  DEC FRAME_DELAY         ;
                BNE CMD_FRAME_DELAY     ;

DELTA_EXIT      RTS                     ;


;-------------------------------------------------------------------------------
ERROR_FILENOTFOUND
                LDX #$1                 ;chars from the top of the defined screen area
                LDY #$1                 ;chars from the left of the defined screen area
                JSR SET_CURSOR          ;
                LDA #<TXT_NOTFOUND      ;set pointer to the text
                LDY #>TXT_NOTFOUND      ;
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
                JMP ERROR_PRESSKEY      ;
                RTS                     ;

                    ;'--------------------'
TXT_NOTFOUND    TEXT 'file not found      '
                BYTE 0

;...............................................................................
ERROR_NOT_VIDEOFILE
                LDX #$1                 ;chars from the top of the defined screen area
                LDY #$1                 ;chars from the left of the defined screen area
                JSR SET_CURSOR          ;
                LDA #<TXT_NOTVIDEO      ;set pointer to the text
                LDY #>TXT_NOTVIDEO      ;
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
                JMP ERROR_PRESSKEY      ;
                RTS                     ;

                    ;'--------------------'
TXT_NOTVIDEO    TEXT 'file not video      '
                BYTE 0

;...............................................................................
ERROR_NOTSUPPORTED
                LDX #$1                 ;chars from the top of the defined screen area
                LDY #$1                 ;chars from the left of the defined screen area
                JSR SET_CURSOR          ;
                LDA #<TXT_FILEVERSION   ;set pointer to the text
                LDY #>TXT_FILEVERSION   ;
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
                LDA FILETYPE            ;
                JSR PRINT_HEX           ;
                JMP ERROR_PRESSKEY      ;
                RTS                     ;
                    ;'--------------------'
TXT_FILEVERSION TEXT 'no supp. for vers:' ;string is 2 chars shorter because version value also takes 2 character position
                BYTE 0

;...............................................................................
ERROR_WRONGSIZE
                LDX #$1                 ;chars from the top of the defined screen area
                LDY #$1                 ;chars from the left of the defined screen area
                JSR SET_CURSOR          ;
                LDA #<TXT_NOTSUPP       ;set pointer to the text
                LDY #>TXT_NOTSUPP       ;
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen

                LDA X_SIZE              ;
                JSR PRINT_DEC           ;the print routine is called
                LDA #<TXT_TIMES         ;set pointer to the text
                LDY #>TXT_TIMES         ;
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
                LDA Y_SIZE              ;
                JSR PRINT_DEC           ;the print routine is called
                LDA #<TXT_FILL          ;set pointer to the text
                LDY #>TXT_FILL          ;
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
                JMP ERROR_PRESSKEY      ;
                RTS                     ;

                    ;'can't show 000x000---'
TXT_NOTSUPP     TEXT 'can't show '
                BYTE 0

TXT_TIMES       TEXT 'x'
                BYTE 0

TXT_FILL        TEXT '   '
                BYTE 0

;...............................................................................
ERROR_PRESSKEY  LDX #$1                 ;chars from the top of the defined screen area
                LDY #$2                 ;chars from the left of the defined screen area
                JSR SET_CURSOR          ;
                LDA #<TXT_PRESSANYKEY   ;set pointer to the text
                LDY #>TXT_PRESSANYKEY   ;
                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
                JSR WAIT_FOR_KEY        ;wait for user to confirm
                RTS
                    ;'--------------------'
TXT_PRESSANYKEY TEXT 'press key to cont.  '
                BYTE 0
;===============================================================================
; This routine will send a string to the Cassiopei
; call example:
; -------------
;
;   LDA #<FILENAME_1        ;set pointer to the text that defines the main-screen
;   STA STR_ADDR            ;
;   LDA #>FILENAME_1        ;
;   STA STR_ADDR+1          ;
;   JSR SEND_STRING         ;sends a string to the cassiopei
;
; Table example:
; --------------
;
;   BYTE "THE A TEAM"       ;the filename must be in upper case
;   BYTE 0                  ;end of table marker
;
;-------------------------------------------------------------------------------
                
SEND_STRING     LDY #$00                ;
                LDA (STR_ADDR),Y        ;read character from string
                BEQ SEND_STR_END        ;when the character was 0, then the end of string marker was detected and we must exit

                JSR CPIO_SEND           ;send char to Cassiopei
                                     
                CLC                     ;
                LDA #$01                ;add 1
                ADC STR_ADDR            ;
                STA STR_ADDR            ;string address pointer
                LDA #$00                ;
                ADC STR_ADDR+1          ;add carry...
                STA STR_ADDR+1          ;                            

                JMP SEND_STRING         ;repeat...

SEND_STR_END    JSR CPIO_SEND_LAST      ;send last (end-of_string) char to Cassiopei
                RTS                     ;


;;===============================================================================
;;this routine is to be called (or not) after the opening of the file and reading
;;of the header
;;...............................................................................
;SHOW_INFO       PHP                     ;save status register to stack (so that we don't screw up the flags generated by the header-reading routine)
;                LDX #$0                 ;chars from the top of the defined screen area
;                LDY #$0                 ;chars from the left of the defined screen area
;                JSR SET_CURSOR          ;
;                LDA #<TXT_CREDITS       ;set pointer to the text
;                LDY #>TXT_CREDITS       ;
;                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen

;                LDX #$0                 ;chars from the top of the defined screen area
;                LDY #$2                 ;chars from the left of the defined screen area
;                JSR SET_CURSOR          ;
;                LDA #<TXT_FILENAME      ;set pointer to the text
;                LDY #>TXT_FILENAME      ;
;                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
;                LDA #<FILENAME          ;set pointer to the text variable
;                LDY #>FILENAME          ;
;                JSR PRINT_ASCII_STRING  ;the print routine is called, so the pointed text is now printed to screen

;                LDX #$0                 ;chars from the top of the defined screen area
;                LDY #$3                 ;chars from the left of the defined screen area
;                JSR SET_CURSOR          ;
;                LDA #<TXT_FILETYPE      ;set pointer to the text
;                LDY #>TXT_FILETYPE      ;
;                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
;                LDA FILETYPE            ;
;                JSR PRINT_HEX           ;

;                LDX #$0                 ;chars from the top of the defined screen area
;                LDY #$4                 ;chars from the left of the defined screen area
;                JSR SET_CURSOR          ;
;                LDA #<TXT_FILEFRAMES    ;set pointer to the text
;                LDY #>TXT_FILEFRAMES    ;
;                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
;                LDA NMBR_OF_FRAMES+1    ;
;                JSR PRINT_HEX           ;
;                LDA NMBR_OF_FRAMES      ;
;                JSR PRINT_HEX           ;

;                LDX #$0                 ;chars from the top of the defined screen area
;                LDY #$6                 ;chars from the left of the defined screen area
;                JSR SET_CURSOR          ;
;                LDA #<TXT_FILESTART     ;set pointer to the text
;                LDY #>TXT_FILESTART     ;
;                JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen

;                PLP                     ;retrieve status register from stack (to get the generated by the header-reading routine)
;                RTS
;;...............................................................................

;TXT_FILENAME    TEXT 'file:'
;                BYTE 0

;TXT_FILETYPE    TEXT 'type:$'
;                BYTE 0

;TXT_FILEFRAMES  TEXT 'frames:$'
;                BYTE 0

;TXT_FILESTART   TEXT 'press key to start'
;                BYTE 0

;TXT_NOTFOUND    TEXT ' not found'
;                BYTE 0

;TXT_NOTSUPP     TEXT ' not supp.'
;                BYTE 0


;-------------------------------------------------------------------------------
;call this routine as described below:
;
;        LDA #<label                ;set pointer to the text that defines the main-screen
;        LDY #>label                ;
;        JSR PRINT_STRING        ;the print routine is called, so the pointed text is now printed to screen
;
; JSR PRINT_CUR_STR ;print the string as indicated by the current string pointer
;...............................................................................
PRINT_STRING    STA STR_ADDR            ;
                STY STR_ADDR+1          ;
PRINT_CUR_STR   LDY #$00                ;
                LDA (STR_ADDR),Y        ;read character from string
                BEQ PR_STR_END          ;when the character was 0, then the end of string marker was detected and we must exit
                JSR PRINT_CHAR          ;print char to screen
                                     
                CLC                     ;
                LDA #$01                ;add 1
                ADC STR_ADDR            ;
                STA STR_ADDR            ;string address pointer
                LDA #$00                ;
                ADC STR_ADDR+1          ;add carry...
                STA STR_ADDR+1          ;                            

                JMP PRINT_CUR_STR       ;repeat...

PR_STR_END      RTS                     ;


;-------------------------------------------------------------------------------
;call this routine as described below:
;
;       LDA #<label             ;set pointer to the first string in a table of strings
;       LDY #>label             ;set pointer to the first string in a table of strings
;       LDX #string_number      ;select the Xth string from the table of strings
;       JSR PRINT_XTH_STR       ;sets the address pointer to the adress of Xth string after the string as pointed to as indicated
;
;
;the table consists of string that all end with 0
;example:
;  BYTE 'MENU OPTION-A                 ',0      ;
;  BYTE 'MENU OPTION-B                 ',0      ;
;  BYTE 'MENU OPTION-C                 ',0      ;
;-------------------------------------------------------------------------------
PRINT_XTH_STR   STA STR_ADDR            ;
                STY STR_ADDR+1          ;
                TXA                     ;check if X=0
                BEQ SET_PR_STR_END      ;when X=0 then we've allready have the correct pointer value and we're done
SET_PR_STR_01   JSR PRINT_XTH_INCA      ;increment address by one
                LDY #$00                ;
                LDA (STR_ADDR),Y        ;read character from string
                BEQ SET_PR_STR_02       ;when the character was 0, then the end of string marker was detected          
                JMP SET_PR_STR_01       ;repeat until end of string reached
SET_PR_STR_02   DEX                     ;decrement string index counter
                BNE SET_PR_STR_01       ;keep looping until we reached the string we want
                JSR PRINT_XTH_INCA      ;increment address by one (we want to point to the first character of the next table entry, we are now pointing to the end of line marker)
SET_PR_STR_END  JMP PRINT_CUR_STR       ;print the string

PRINT_XTH_INCA  CLC                     ;
                LDA #$01                ;increment the pointer to the string by one in order to get the next char/value
                ADC STR_ADDR            ;add 1
                STA STR_ADDR            ;string address pointer
                LDA #$00                ;add 0 + carry of the previous result
                ADC STR_ADDR+1          ;meaning that if we have an overflow, the must increment the high byte
                STA STR_ADDR+1          ;  
                RTS

;-------------------------------------------------------------------------------
; this routine will print the value in A as a 2 digit hexadecimal value
;        LDA #value                      ;A-register must contain value to be printed
;        JSR PRINT_HEX     ;the print routine is called
;...............................................................................
PRINT_HEX       PHA                     ;save A to stack
                AND #$F0                ;mask out low nibble
                LSR A                   ;shift to the right
                LSR A                   ;
                LSR A                   ;
                LSR A                   ;
                TAX                     ;
                LDA HEXTABLE,X          ;convert using table                                 
                JSR PRINT_CHAR          ;print character to screen

                PLA                     ;retrieve A from stack
                AND #$0F                ;mask out high nibble
                TAX                     ;
                LDA HEXTABLE,X          ;convert using table                                 
                JSR PRINT_CHAR          ;print character to screen
 
                RTS                     ;

HEXTABLE        TEXT '0123456789abcdef'                 

;-------------------------------------------------------------------------------
; this routine will print the value in A as a 3 digit decimal value
;        LDA #value        ;Y-register must contain value to be printed
;        JSR PRINT_DEC     ;the print routine is called
;
;Converts .A to 3 ASCII/PETSCII digits: .Y = hundreds, .X = tens, .A = ones
;...............................................................................
PRINT_DEC       LDY #$2f                ;
                LDX #$3a                ;
                SEC                     ;
DEC_01          INY                     ;
                SBC #100                ;
                BCS DEC_01              ;

DEC_02          DEX                     ;
                ADC #10                 ;
                BMI DEC_02              ;
        
                ADC #$2f                ;
                PHA                     ;save A to stack

                TYA                     ;transfer value to A for printing
                JSR PRINT_CHAR          ;print 100's

                TXA                     ;transfer value to A for printing
                JSR PRINT_CHAR          ;print 10's

                PLA                     ;retrieve saved A from stack for printing
                JSR PRINT_CHAR          ;print 1's

                RTS                     ;


;===============================================================================
;  
;                                V A R I A B L E S 
;
;===============================================================================
;a small list of variables that do not require storage in the zero-page


BROWSE_ACTION   BYTE $0         ;
BROWSE_STATUS   BYTE $0         ;
BROWSE_CURX     BYTE $0         ;
BROWSE_CURY     BYTE $0         ;
BROWSE_MAXX     BYTE $0         ;
BROWSE_MAXY     BYTE $0         ;

DELCNT          BYTE $1         ;
FRAME_DELAY     BYTE $0         ;

FILETYPE        BYTE $00        ;the filetype indicator
NMBR_OF_FRAMES  BYTE $00        ;a variable to store the number of frames (low byte)
                BYTE $00        ;a variable to store the number of frames (high byte)
X_SIZE          BYTE $00        ;the width of the screen in chars
Y_SIZE          BYTE $00        ;the height of the screen in charset_init
MODE_BYTE       BYTE $00        ;the mode the encoded image uses
CODEBOOKSIZE    BYTE $00        ;reserved for future use        
RESERVED_01     BYTE $00        ;reserved for future use
RESERVED_02     BYTE $00        ;reserved for future use
RESERVED_03     BYTE $00        ;reserved for future use        
RESERVED_04     BYTE $00        ;reserved for future use

MAGICWORD       BYTE $50,$45,$54,$53,$43,$49,$49,$56,$49,$44,$45,$4F
LOOPCOUNT       BYTE $0

FILE_OPEN_STATUS        BYTE $0 ;the response to the fileopen request
