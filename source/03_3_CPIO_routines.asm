;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODORE64
;-------------------------------------------------------------------------------
DATA_DIR_6510   = $00           ;the MOS6510 data direction register of the peripheral IO pins (P7-0)
DATA_BIT_6510   = $01           ;the MOS6510 value f the bits of the peripheral IO pins (P7-0)

;###############################################################################

;///////////////////////////////////////////////////////////////////////////////
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;
;              C P I O   r o u t i n e s   ( f o r   t h e   C 6 4 )
;
;///////////////////////////////////////////////////////////////////////////////
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


;*******************************************************************************
; Cassette Port Input Output protocol initialisation
;******************************************************************************* 
CPIO_INIT       LDA DATA_BIT_6510   ;
                ORA #%00101000      ;P5: lower ATTENTION-line (this signal is inverted therefore we need to write a '1' into the reg.) by the power stage that drives the motor-line
                STA DATA_BIT_6510   ;P3: raise CLOCK-line (cassette write-line)               

                LDA DATA_DIR_6510   ;data direction register of the MOS6510
                AND #%11101111      ;set the direction of the DATA-line (cassette button sense-line) to input
                STA DATA_DIR_6510   ;data direction register of the MOS6510

                RTS

;*******************************************************************************
;JSR CPIO_WAIT4RDY   ;wait until the CPIO device (slave) is ready

CPIO_WAIT4RDY   LDA $DC0D           ;read CIA connected to the cassetteport (reading clears the state of the bits)
                AND #%00010000      ;mask out bit 4
                BEQ CPIO_WAIT4RDY   ;loop until the slave lowers the read signal              
                RTS

;*******************************************************************************
;LDA <data>     ;data is the requested operating mode of the slave
;JSR CPIO_START  ;raise attention signal, now communication is set up, we can read or write data from this point
CPIO_START      STA CPIO_DATA       ;store value in A (which holds the mode-byte) to working register

                JSR CPIO_BACKOFF    ;make sure that the attention low signal is long enough low to be detected by the Cassiopei (placing it here ensures that 2 sequential but different data transfers are separated by a long enough low state of the ATN signal)

                SEI                 ;disable interrupts
                LDA $DC0D           ;reading clears all flags, so when we do a Read here we clear the old interrupts so that our routines will trigger on the correct event (instead of an old unhandled event)
               
                LDA DATA_BIT_6510   ;set ATTENTION signal to make slave prepare for communication
                AND #%11011111      ;motor control line is set to 0 (MOTOR is now ON (6 volt))
                STA DATA_BIT_6510   ;

                JMP SEND_DATA       ;send the mode byte to the slave

;*******************************************************************************
;this routine will lower the attention to indicate that the current is the last byte
CPIO_SEND_LAST  STA CPIO_DATA       ;safe the data (stored in the accu) to a working register

                LDA DATA_DIR_6510   ;data direction register of the MOS6510
                ORA #%00010000      ;set the direction of the sense line to output
                STA DATA_DIR_6510   ;data direction register of the MOS6510

                JSR CPIO_WAIT4RDY   ;wait until the CPIO device (slave) is ready
                
                LDA DATA_BIT_6510   ;send a '0'
                ORA #%00100000      ;motor control line is set to 1 (MOTOR is now OFF (0 Volt))
                STA DATA_BIT_6510   ;with the attention signal being low (motor-off) the slave has been notified that communication has come to an end and that the current byte is the last byte within this session

                LDY #$08            ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine
                JMP SEND_DATA_LP    ;
;...............................................................................
;this routine will send a byte to the slave
;LDA <data>
;JSR CPIO_SEND

CPIO_SEND       STA CPIO_DATA       ;safe the data (stored in the accu) to a working register
SEND_DATA       LDY #$08            ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine

                LDA DATA_DIR_6510   ;data direction register of the MOS6510
                ORA #%00010000      ;set the direction of the sense line to output
                STA DATA_DIR_6510   ;data direction register of the MOS6510

                JSR CPIO_WAIT4RDY   ;wait until the CPIO device (slave) is ready                
SEND_DATA_LP
SEND_CLOCK_0    LDA DATA_BIT_6510   ;lower clock
                AND #%11110111      ;change state of write line to '0'
                STA DATA_BIT_6510   ;    

                BIT CPIO_DATA       ;bit moves bit-7 of CPIO_DATA into the N-flag of the status register
                BPL SEND_ZERO       ;BPL tests the N-flag, when it is 0 the branch to SEND_ZERO is executed (using the BIT instruction instead of conventional masking, we save 2 cycles, and 2 bytes)
SEND_ONE        LDA DATA_BIT_6510   ;
                ORA #%00010000      ;change state of sense line to '1'
                JMP SEND_BIT        ;
SEND_ZERO       LDA DATA_BIT_6510   ;
                AND #%11101111      ;change state of sense line to '0'

SEND_BIT        STA DATA_BIT_6510   ;
SEND_CLOCK_1   ; LDA DATA_BIT_6510  ;raise clock to indicate data is ready for the slave to be read
                ORA #%00001000      ;change state of write line to '1'
                STA DATA_BIT_6510   ;
                ASL CPIO_DATA       ;rotate data in order to send each individual bit, we do it here so that we save time, we have to wait for the clock pulse high-time anyway

                DEY                 ;decrement the Y value
                BNE SEND_DATA_LP    ;exit loop after the eight bit

                LDA DATA_BIT_6510   ;
                AND #%11110111      ;lower the clock line so that the slave has the opportunity to read the data
                STA DATA_BIT_6510   ;
                ORA #%00001000      ;raise clock by changing state of write line to '1' to indicate that the byte has come to an end
                STA DATA_BIT_6510   ;

                LDA DATA_DIR_6510   ;data direction register of the MOS6510
                AND #%11101111      ;set the direction of the sense line to input
                STA DATA_DIR_6510   ;data direction register of the MOS6510
                RTS                 ;end of subroutine


;*******************************************************************************
;this routine will lower the attention to indicate that the current is the last byte
CPIO_REC_LAST   JSR CPIO_WAIT4RDY   ;wait until the CPIO device (slave) is ready

                LDA DATA_BIT_6510   ;send a '0'
                ORA #%00100000      ;motor control line is set to 1 (MOTOR is now OFF (0 Volt))
                STA DATA_BIT_6510   ;with the attention signal being low (motor-off) the slave has been notified that communication has come to an end and that the current byte is the last byte within this session

                LDA #$01            ;the LSB is one,but after eight ROL's it will end up in the carry, which we can detect and use to end our loop
                STA CPIO_DATA       ;by using our working data destination register we do not require a CLC on every bit check and we don't need a DEY after every bit
                CLC                 ;clear the carry as it could be set by a previous routine

                TYA
                PHA
                TXA
                PHA
        
                LDA DATA_BIT_6510       ;lower clock
                AND #%11110111          ;calculate state of write line (CLOCK) cleared to '0'
                STA DATA_BIT_6510       ;APPLY
                TAX                     ;save for later use 
                ORA #%00001000          ;calculate state of write line (CLOCK) set to '1'
                TAY                     ;save for later use
                CLC                     ;clear the carry, which is usefull for the ADC further on, because the  ROL will clear it otherwise.
        
REC_DATA_LP     
REC_CLOCK_1     STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA DATA_BIT_6510       ;sample the data
REC_CLOCK_0     STX DATA_BIT_6510       ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry
                BCC REC_DATA_LP         ;keep loopin untill the Carry becomes set (which will be after 8 ROL's)

                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1'

                PLA
                TAX
                PLA
                TAY

                LDA CPIO_DATA           ;move data to accu
                RTS                     ;end of subroutine



;*******************************************************************************
;this is an unrolled version of the CPIO_RECIEVE routine optimized for speed
;-------------------------------------------------------------------------------
;this routine will recieve a byte to the slave
;JSR CPIO_RECIEVE
;data is in Accu
;
;Attention: affects X and Y register
;...............................................................................
CPIO_RECIEVE    
CPIO_REC_01     ;wait until the CPIO device (slave) is ready  
                LDA #%00010000      ;mask out bit 4
CPIO_REC_W4R    BIT $DC0D           ;read CIA connected to the cassetteport (reading clears the state of the bits)
                BEQ CPIO_REC_W4R    ;loop until the slave lowers the read signal              

                LDA DATA_BIT_6510       ;lower clock
                AND #%11110111          ;calculate state of write line (CLOCK) cleared to '0'
                STA DATA_BIT_6510       ;APPLY
                TAX                     ;save for later use 
                ORA #%00001000          ;calculate state of write line (CLOCK) set to '1'
                TAY                     ;save for later use
                LDA #$00                ;must be zero, because every bit goes (because of the ROL instruction) through the carry and the carry must remain cleared
                STA CPIO_DATA           ;
                CLC                     ;clear the carry, which is usefull for the ADC further on, because the  ROL will clear it otherwise.
        
                ;bit 7
                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA DATA_BIT_6510       ;sample the data
                STX DATA_BIT_6510       ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 6
                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA DATA_BIT_6510       ;sample the data
                STX DATA_BIT_6510       ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 5
                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA DATA_BIT_6510       ;sample the data
                STX DATA_BIT_6510       ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 4
                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA DATA_BIT_6510       ;sample the data
                STX DATA_BIT_6510       ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 3
                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA DATA_BIT_6510       ;sample the data
                STX DATA_BIT_6510       ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 2
                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA DATA_BIT_6510       ;sample the data
                STX DATA_BIT_6510       ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 1
                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA DATA_BIT_6510       ;sample the data
                STX DATA_BIT_6510       ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 0
                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA DATA_BIT_6510       ;sample the data
                STX DATA_BIT_6510       ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                STY DATA_BIT_6510       ;changing state of write line (CLOCK) to '1'

                LDA CPIO_DATA           ;move data to accu
                RTS                     ;end of subroutine

;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODORE64"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
