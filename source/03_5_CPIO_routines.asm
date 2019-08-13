;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODORE16PLUS4
;-------------------------------------------------------------------------------
DATA_DIR_7501   = $00           ;the 7501/8501 register to controll the IEC serial port and cassette signals
DATA_BIT_7501   = $01           ;the 7501/8501 register to controll the CPU own io lines data direction register
CASS_SENSE      = $FD10         ;the casse sense signal is I/O mapped  to FD10-FD1F and connected to bit 2 of the databus


;###############################################################################

;///////////////////////////////////////////////////////////////////////////////
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;
;                    C P I O   r o u t i n  e s   f o r   C 1 6
;
;///////////////////////////////////////////////////////////////////////////////
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



;0001h - CPU 7501/8501 On-Chip I/O Port Data (Cassette, Serial, User Port)
;--------------------------------------------------------------------------
;  Bit Dir Expl.
;  7   In  Serial Data In (and PLUS/4: Cas Sense) (0=Low, 1=High)
;  6   In  Serial Clock In                        (0=Low, 1=High)
;  5   -   Not used (no pin-out on 7501/8501)     (N/A)
;  4   In  Cassette Read                          (0=Low, 1=High)
;  3   Out Cassette Motor                         (0=9VDC, 1=Off) (Inverted !!)
;  2   Out Serial ATN Out (and PLUS/4: User Port) (0=High, 1=Low) (Inverted)
;  1   Out Serial Clock Out, Cassette Write       (0=High, 1=Low) (Inverted !!)
;  0   Out Serial Data Out                        (0=High, 1=Low) (Inverted !!)

;Switch Serial Clock/Data Outputs HIGH before reading Clock/Data Inputs.




;FD10h-FD1Fh - Cassette Sense / User Port 8bit Parallel I/O
;--------------------------------------------------------------------------
;  7-0 User Port 6529B, 8bit Parallel I/O   (PLUS/4 Only)
;  2   Cassette Sense In                    (C16 and C116 Only)

;Note: On the PLUS/4, the Cassette Sense signal has moved to Port 0001h/Bit7, exchanging the J8,J9 jumpers switches the Plus/4 to C16 compatible mode.


;as you'be noticed the C16 isn't capable of following the C64/VIC20's pinout for CPIO communication, why? well
;because the C16 has the cassette sense line is only available in 1 direction, so it cannot act as a bi-directional dataline (thanks to a 74LS125)
;however the cassette read signal IS bi-directional, so we can use this line as the data line, since the Cassiopei is mostly software and the IO-pins
;can be redirected in software this will mean that the C16 can be made to work with the CPIO protocol as long as the read and sense lines are controlled
;in the proper way. Only software...

;*******************************************************************************
; Cassette Port Input Output protocol initialisation
;******************************************************************************* 
CPIO_INIT       LDA DATA_BIT_7501   ;
                ORA #%00001010      ;lower ATTENTION-line (3=cass motor:this signal is inverted), raise Clock signal (1=cass write)
                STA DATA_BIT_7501   ;

                LDA DATA_DIR_7501   ;
                AND #%11101111      ;read line is set to input (0=input, 1=output)
                STA DATA_DIR_7501   ;

                RTS

;*******************************************************************************
;LDA <data>     ;data is the requested operating mode of the slave
;JSR CPIO_START  ;raise attention signal, now communication is set up, we can read or write data from this point
CPIO_START      STA CPIO_DATA       ;store value in A (which holds the mode-byte) to working register

                JSR CPIO_BACKOFF    ;make sure that the attention low signal is long enough low to be detected by the Cassiopei (placing it here ensures that 2 sequential but different data transfers are separated by a long enough low state of the ATN signal)

                SEI                 ;disable interrupts
               
                LDA DATA_BIT_7501   ;set ATTENTION signal to make slave prepare for communication
                AND #%11110111      ;cassette motor ON (motor is turning)
                STA DATA_BIT_7501   ;

                JMP SEND_DATA       ;send the mode byte to the slave


;*******************************************************************************
;this routine will lower the attention to indicate that the current is the last byte
CPIO_SEND_LAST  STA CPIO_DATA       ;safe the data (stored in the accu) to a working register
                JSR WAIT_FOR_READY  ;wait until slave acknowledges that it is ready

                LDA DATA_BIT_7501   ;
                ORA #%00001000      ;cassette motor OFF (motor does not move) (attention, this line is inverted: 0=ON, 1=OFF)
                STA DATA_BIT_7501   ;

                LDA DATA_DIR_7501   ;the READ line is used to transfer the DATA so it must be set as an output (because this is the SEND routine)
                ORA #%00010000      ;read line is set to output (0=input, 1=output)
                STA DATA_DIR_7501   ;

                LDY #$08            ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine
                JMP SEND_DATA_LP

;...............................................................................
;this routine will send a byte to the slave
;LDA <data>
;JSR CPIO_SEND

CPIO_SEND       STA CPIO_DATA       ;safe the data (stored in the accu) to a working register
SEND_DATA       LDY #$08            ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine

                LDA DATA_DIR_7501   ;the READ line is used to transfer the DATA so it must be set as an output (because this is the SEND routine)
                ORA #%00010000      ;read line is set to output (0=input, 1=output)
                STA DATA_DIR_7501   ;

                JSR WAIT_FOR_READY  ;wait until slave acknowledges that it is ready
SEND_DATA_LP
SEND_CLOCK_0    JSR CPIO_CLOCK_LOW  ;

                BIT CPIO_DATA       ;bit moves bit-7 of CPIO_DATA into the N-flag of the status register
                BPL SEND_ZERO       ;BPL tests the N-flag, when it is 0 the branch to SEND_ZERO is executed (using the BIT instruction instead of conventional masking, we save 2 cycles, and 2 bytes)
SEND_ONE        LDA DATA_BIT_7501   ;
                ORA #%00010000      ;cassette read = high (we want to send a '1')
                JMP SEND_BIT        ;
SEND_ZERO       LDA DATA_BIT_7501   ;
                AND #%11101111      ;cassette read = low (we want to send a '0')
SEND_BIT        STA DATA_BIT_7501   ;

SEND_CLOCK_1    JSR CPIO_CLOCK_HIGH ;
                ASL CPIO_DATA       ;rotate data in order to send each individual bit, we do it here so that we save time, we have to wait for the clock pulse high-time anyway
                DEY                 ;decrement the Y value
                BNE SEND_DATA_LP    ;exit loop after the eight bit

                JSR CPIO_CLOCK_LOW  ;
                JSR CPIO_CLOCK_HIGH ;

                LDA DATA_DIR_7501   ;
                AND #%11101111      ;read line is set to input (0=input, 1=output)
                STA DATA_DIR_7501   ;
                RTS                 ;end of subroutine

;*******************************************************************************
;this routine will lower the attention to indicate that the current is the last byte
CPIO_REC_LAST   LDY #$08            ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine
                JSR WAIT_FOR_READY  ;wait until slave anknowledges that it is ready

                LDA DATA_BIT_7501   ;
                ORA #%00001000      ;cassette motor OFF (motor does not move) (attention, this line is inverted: 0=ON, 1=OFF)
                STA DATA_BIT_7501   ;with the attention signal being low (motor-off) the slave has been notified that communication has come to an end and that the current byte is the last byte within this session

REC_DATA_LP
REC_CLOCK_0     JSR CPIO_CLOCK_LOW  ;

                CLC                 ;clear the carry, which is usefull for the ADC later, we clear it here in order to make the clock=0 time 2 cycles longer (keeps our clock duty cycle closer to 50% (which is allways nice))
REC_CLOCK_1     JSR CPIO_CLOCK_HIGH ;

                LDA DATA_BIT_7501   ;
                AND #%00010000      ;mask out the READ line (the READ line is our data signal)
                ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA       ;shift all the bits one position to the right and add the LSB which is located in the carry

                DEY                 ;decrement the Y value
                BNE REC_DATA_LP     ;exit loop after the eight bit

                JSR CPIO_CLOCK_LOW  ;
                JSR CPIO_CLOCK_HIGH ;

                LDA CPIO_DATA       ;move data to accu
                RTS                 ;end of subroutine


;*******************************************************************************
;this routine will wait until the CPIO slave signals that is is ready
;the C16 uses the cass sense signal as the ready indicator
;...............................................................................
WAIT_FOR_READY  LDA CASS_SENSE      ;FD10h-FD1Fh - Cassette Sense and other IO
                AND #%00000100      ;Bit 2 = Cassette Sense In (C16 and C116 Only)
                BNE WAIT_FOR_READY  ;loop until the slave lowers the read signal
                RTS                 ;    

;*******************************************************************************
CPIO_CLOCK_HIGH LDA DATA_BIT_7501   ;lower the clock line so that the slave has the opportunity to read the data
                AND #%11111101      ;cassette write = high (this signal is inverted by a 7406)
                STA DATA_BIT_7501   ;
                RTS

;*******************************************************************************
CPIO_CLOCK_LOW  LDA DATA_BIT_7501   ;raise clock by changing state of write line to '1' to indicate that the byte has come to an end
                ORA #%00000010      ;cassette write = low (this signal is inverted by a 7406)
                STA DATA_BIT_7501   ;
                RTS

;;*******************************************************************************
;;this is an unrolled version of the CPIO_RECIEVE routine optimized for speed
;;-------------------------------------------------------------------------------
;;this routine will recieve a byte to the slave
;;JSR CPIO_RECIEVE
;;data is in Accu
;;
;;Attention: affects X and Y register
;;...............................................................................
CPIO_RECIEVE    JSR WAIT_FOR_READY      ;wait until slave anknowledges that it is ready (unrolling this makes not required because we neec to honor timing, unrolling makes it too fast)
                ;also the unrolling of the CPIO_CLOCK_HIGH and LOW routines reduced reliabillity and was therefore not used!!

                LDA DATA_BIT_7501       ;
                ORA #%00000010          ;cassette write = low (this signal is inverted by a 7406)
                STA DATA_BIT_7501       ;
                TAX                     ;save for later use 
                AND #%11111101          ;cassette write = high (this signal is inverted by a 7406)
                TAY                     ;save for later use
                LDA #$00                ;must be zero, because every bit goes (because of the ROL instruction) through the carry and the carry must remain cleared
                STA CPIO_DATA           ;
                CLC                     ;clear the carry, which is usefull for the ADC further on, because the  ROL will clear it otherwise.
        
                ;bit 7
                JSR CPIO_CLOCK_HIGH     ;
                LDA DATA_BIT_7501       ;sample the data
                JSR CPIO_CLOCK_LOW      ;
                AND #%00010000          ;mask out the READ line (the READ line is our data signal)
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry

                ;bit 6
                JSR CPIO_CLOCK_HIGH     ;
                LDA DATA_BIT_7501       ;sample the data
                JSR CPIO_CLOCK_LOW      ;
                AND #%00010000          ;mask out the READ line (the READ line is our data signal)
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry

                ;bit 5
                JSR CPIO_CLOCK_HIGH     ;
                LDA DATA_BIT_7501       ;sample the data
                JSR CPIO_CLOCK_LOW      ;
                AND #%00010000          ;mask out the READ line (the READ line is our data signal)
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry

                ;bit 4
                JSR CPIO_CLOCK_HIGH     ;
                LDA DATA_BIT_7501       ;sample the data
                JSR CPIO_CLOCK_LOW      ;
                AND #%00010000          ;mask out the READ line (the READ line is our data signal)
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry

                ;bit 3
                JSR CPIO_CLOCK_HIGH     ;
                LDA DATA_BIT_7501       ;sample the data
                JSR CPIO_CLOCK_LOW      ;
                AND #%00010000          ;mask out the READ line (the READ line is our data signal)
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry

                ;bit 2
                JSR CPIO_CLOCK_HIGH     ;
                LDA DATA_BIT_7501       ;sample the data
                JSR CPIO_CLOCK_LOW      ;
                AND #%00010000          ;mask out the READ line (the READ line is our data signal)
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry

                ;bit 1
                JSR CPIO_CLOCK_HIGH     ;
                LDA DATA_BIT_7501       ;sample the data
                JSR CPIO_CLOCK_LOW      ;
                AND #%00010000          ;mask out the READ line (the READ line is our data signal)
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry

                ;bit 0
                JSR CPIO_CLOCK_HIGH     ;
                LDA DATA_BIT_7501       ;sample the data
                JSR CPIO_CLOCK_LOW      ;
                AND #%00010000          ;mask out the READ line (the READ line is our data signal)
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry

                JSR CPIO_CLOCK_HIGH     ;

                LDA CPIO_DATA           ;move data to accu
                RTS                     ;end of subroutine

;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODORE16PLUS4"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
