;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX or COMMODOREPET80XX
;-------------------------------------------------------------------------------

;///////////////////////////////////////////////////////////////////////////////
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;
;            C P I O   r o u t i n  e s   ( 30XX series (i.e. the PET-3032 ))
;
;///////////////////////////////////////////////////////////////////////////////
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

;*******************************************************************************
; Cassette Port Input Output protocol initialisation
;******************************************************************************* 
CPIO_INIT       ;lower ATTENTION-line (cassette motor line)
                LDA $E813               ;peripheral control register of 6520 (PIA) (IC7 as indicated on 320349)
                ORA #%00001000          ;CB2 high (motor=OFF) Attention signal = NO ATTENTION (cassette motor line)
                STA $E813               ;

                ;raise CLOCK-line (cassette write-line)
                LDA $E842               ;data direction register of 6520 (PIA) (IC5 as indicated on 320349)
                ORA #%00001000          ;define PB3 as an output (make the DDR bit high)
                STA $E842               ;

                LDA $E840               ;data register of 6520 (PIA) (IC5 as indicated on 320349)
                ORA #%00001000          ;make PB3 high, raises CLOCK-line (cassette write-line)
                STA $E840               ;

                                        ;set the READ-line properties (CA1 interrupt settings to falling edge)
                                        ;Peripheral control register of 6520(IC7 as indicated on 320349), we need to trigger on falling edges
                LDA #%00111100          ;CA1 triggers on negative edge
                STA $E811               ;set PIA 1 CRA

                
                ;DATA-line (cassette button sense-line) must be set to an input (it is also pulled high by a resistor)
DATALINE_2INPUT JSR USE_PIA_DIR         ;select writing to the data-direction register (to define input and output) PIA1
                LDA $E810               ;data direction register of 6520 (PIA) (IC5 as indicated on 320349)
                AND #%11101111          ;define PA4, DATA-line (cassette sense-line), as an input (make the DDR bit low)
                STA $E810               ;
                ;JSR USE_PIA_DATA       ;select writing to the data-register (to define the states of the output(s) or read the input(s)) PIA1
                ;RTS                    ;

                ;select writing to the data-direction register (to define input and output) PIA1
USE_PIA_DATA    LDA $E811               ;Auxilary control register of 6520 (PIA) (IC5 as indicated on 320349)
                ORA #%00000100          ;set bit-2 to use the data-register (which is very important if we want to read or write data to the IO-port)
                STA $E811               ;
                RTS                     ;return to caller

                ;select writing to the data-register (to define the states of the output(s) or read the input(s)) PIA1
USE_PIA_DIR     LDA $E811               ;Auxilary control register of 6520 (PIA) (IC5 as indicated on 320349)
                AND #%11111011          ;clear bit-2 to use the data-direction-register (which is very important if we want to set the port pins to input or output)
                STA $E811               ;
                RTS                     ;return to caller

;*******************************************************************************
; JSR CPIO_WAIT4RDY     ;wait untill the slave signals that it is ready
;
        ;this routine just keeps polling the 6520(IC7 as indicated on 340349)

CPIO_WAIT4RDY   LDA $E811               ;get the interrupt flags of 6520 (reading port A of the 6520 clears the int flags, so there is no need for a clearing action)
                AND #%10000000          ;mask out bit CA1
                BEQ CPIO_WAIT4RDY       ;keep looping until the flag is set
                RTS                     ;return to caller


;*******************************************************************************
;LDA <data>     ;data is the requested operating mode of the slave
;JSR CPIO_START  ;raise attention signal, now communication is set up, we can read or write data from this point
CPIO_START      STA CPIO_DATA           ;store value in A (which holds the mode-byte) to working register
                JSR CPIO_BACKOFF    ;make sure that the attention low signal is long enough low to be detected by the Cassiopei (placing it here ensures that 2 sequential but different data transfers are separated by a long enough low state of the ATN signal)
                SEI                     ;disable interrupts
                LDA $E813               ;peripheral control register of 6520 (PIA) (IC7 as indicated on 320349)
                AND #%11110111          ;CB2 low (motor=ON) Attention signal = ATTENTION (cassette motor line)
                STA $E813               ;
                JMP SEND_DATA           ;send the mode byte to the slave

;*******************************************************************************
;this routine will lower the attention to indicate that the current is the last byte
CPIO_SEND_LAST  STA CPIO_DATA           ;safe the data (stored in the accu) to a working register

                JSR CPIO_WAIT4RDY       ;wait untill the slave signals that it is ready (we must check it now, otherwise the information about the edge will be lost, because the next routines will read and alter E811 and therefore destroy the possible detected edge)

                LDA $E813               ;peripheral control register of 6522 (VIA) (IC7 as indicated on 320349)
                ORA #%00001000          ;CB2 high (motor=OFF) Attention signal = NO ATTENTION (cassette motor line)
                STA $E813               ;with the attention signal being low (motor-off) the slave has been notified that communication has come to an end and that the current byte is the last byte within this session

                LDY #$08                ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine
                JMP SEND_DATA_00        ;
;...............................................................................
;this routine will send a byte to the slave
;LDA <data>
;JSR CPIO_SEND

CPIO_SEND       STA CPIO_DATA           ;safe the data (stored in the accu) to a working register
SEND_DATA       LDY #$08                ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine

                JSR CPIO_WAIT4RDY       ;wait untill the slave signals that it is ready (we must check it now, otherwise the information about the edge will be lost, because the next routines will read and alter E811 and therefore destroy the possible detected edge)

SEND_DATA_00    JSR USE_PIA_DIR         ;select writing to the data-direction register
                LDA $E810               ;data direction register of 6520 (PIA) (IC5 as indicated on 320349)
                ORA #%00010000          ;define PA4, DATA-line (cassette sense-line), as an output (make the DDR bit high)
                STA $E810               ;

                JSR USE_PIA_DATA        ;in order to write data to the IO-lines we must make this possible by selecting the data-register
                LDA $E810               ;data register of 6520 (PIA) (IC5 as indicated on 320349)
                ORA #%00010000          ;make PA4 high, DATA-line (cassette sense-line)
                STA $E810               ;
                
SEND_DATA_LP
SEND_CLOCK_0    LDA $E840               ;data register of 6522 (VIA) (IC5 as indicated on 320349)
                AND #%11110111          ;make PB3 low, lowers CLOCK-line (cassette write-line)
                STA $E840               ;

                BIT CPIO_DATA           ;bit moves bit-7 of CPIO_DATA into the N-flag of the status register
                BPL SEND_ZERO           ;BPL tests the N-flag, when it is 0 the branch to SEND_ZERO is executed (using the BIT instruction instead of conventional masking, we save 2 cycles, and 2 bytes)
SEND_ONE        LDA $E810               ;data register of 6520 (PIA) (IC5 as indicated on 320349)
                ORA #%00010000          ;make PA4 high, DATA-line (cassette sense-line)
                JMP SEND_BIT            ;
SEND_ZERO       LDA $E810               ;data register of 6520 (PIA) (B3)
                AND #%11101111          ;make PA4 low, DATA-line (cassette sense-line)

SEND_BIT        STA $E810               ;

SEND_CLOCK_1    LDA $E840               ;data register of 6522 (VIA) (IC5 as indicated on 320349)
                ORA #%00001000          ;make PB3 high, raises CLOCK-line (cassette write-line)
                STA $E840               ;

                ASL CPIO_DATA           ;rotate data in order to send each individual bit, we do it here so that we save time, we have to wait for the clock pulse high-time anyway

                DEY                     ;decrement the Y value
                BNE SEND_DATA_LP        ;exit loop after the eight bit


                ;make clock line low, the slave now reads the last bit of the data
                LDA $E840               ;data register of 6522 (VIA) (IC5 as indicated on 320349)
                AND #%11110111          ;make PB3 low, lowers CLOCK-line (cassette write-line)
                STA $E840               ;
                ;make clock line high, to indicate that the byte has come to an end
                ORA #%00001000          ;make PB3 high, raises CLOCK-line (cassette write-line)
                STA $E840               ;
                
                JSR DATALINE_2INPUT     ;DATA-line (cassette button sense-line), this is an input that is pulled up (so there is no need for us to make it high)

                RTS                     ;end of subroutine

;*******************************************************************************
;this routine will lower the attention to indicate that the current is the last byte
CPIO_REC_LAST   JSR CPIO_WAIT4RDY       ;wait untill the slave signals that it is ready                

                LDA $E813               ;peripheral control register of 6520 (PIA) (IC7 as indicated on 320349)
                ORA #%00001000          ;CB2 high (motor=OFF) Attention signal = NO ATTENTION (cassette motor line)
                STA $E813               ;with the attention signal being low (motor-off) the slave has been notified that communication has come to an end and that the current byte is the last byte within this session

                LDY #$08                ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine
                JMP REC_DATA_LP         ;
;...............................................................................

;this routine will recieve a byte to the slave
;JSR CPIO_RECIEVE
;data is in Accu

CPIO_RECIEVE    LDY #$08                ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine
                JSR CPIO_WAIT4RDY       ;wait untill the slave signals that it is ready

REC_DATA_LP
REC_CLOCK_0     LDA $E840               ;data register of 6522 (VIA) (IC5 as indicated on 320349)
                AND #%11110111          ;make PB3 low, lowers CLOCK-line (cassette write-line)
                STA $E840               ;make clock line low, the slave now prepares the data to be send


                CLC                     ;clear the carry, which is usefull for the ADC later, we clear it here in order to make the clock=0 time 2 cycles longer (keeps our clock duty cycle closer to 50% (which is allways nice))
REC_CLOCK_1     LDA $E840               ;data register of 6522 (VIA) (IC5 as indicated on 320349)
                ORA #%00001000          ;make PB3 high, raises CLOCK-line (cassette write-line)
                STA $E840               ;

                LDA $E810               ;data register of 6522 (VIA) (IC5 as indicated on 320349) (this register holds the DATA-line PA4)
                AND #%00010000          ;test input signal for '0' or '1'
                ADC #%11111111          ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position to the right and add the LSB which is located in the carry

                DEY                     ;decrement the Y value
                BNE REC_DATA_LP         ;exit loop after the eight bit

                LDA $E840               ;data register of 6522 (VIA) (IC5 as indicated on 320349)
                AND #%11110111          ;make PB3 low, lowers CLOCK-line (cassette write-line)
                STA $E840               ;
                ;make clock line high, this indicates to the slave that the master has read the data
                ORA #%00001000          ;make PB3 high, raises CLOCK-line (cassette write-line)
                STA $E840               ;
                
                LDA CPIO_DATA           ;move data to accu
                RTS                     ;end of subroutine

;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODOREPET20XX or COMMODOREPET30XX or COMMODOREPET40XX or COMMODOREPET80XX"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

