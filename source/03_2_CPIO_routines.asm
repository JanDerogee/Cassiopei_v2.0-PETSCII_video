;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREVIC20
;-------------------------------------------------------------------------------

DATA_DIR_6510   = $00   ;the MOS6510 data direction register of the peripheral IO pins (P7-0)
DATA_BIT_6510   = $01   ;the MOS6510 value f the bits of the peripheral IO pins (P7-0)

;###############################################################################


;///////////////////////////////////////////////////////////////////////////////
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;
;            C P I O   r o u t i n  e s   ( f o r   t h e   V I C - 2 0 )
;
;///////////////////////////////////////////////////////////////////////////////
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

;let op: omdat de write lijn van de cassettepoort aan de keyboard matrix vastzit
;moeten we er rekening mee houden dat CPIO en keyboard niet samen gaan
;dus interrupts uit of zo

;               ;lower ATTENTION-line (this signal is inverted therefore we need to write a '1' into the reg.)
;               LDA $911C               ;Attention signal = NO ATTENTION
;               ORA #%00001110          ;CA2 high (motor=OFF)
;               STA $911C               ;

;               ;raise ATTENTION-line (this signal is inverted therefore we need to write a '0' into the reg.)
;               LDA $911C               ;Attention signal = ATTENTION
;               ORA #%00001100          ;define IO CA to proper mode
;               AND #%11111101          ;CA2 low (motor=ON)
;               STA $911C               ;


;*******************************************************************************
; Cassette Port Input Output protocol initialisation
;******************************************************************************* 
CPIO_INIT       ;lower ATTENTION-line (cassette motor line)
                LDA $911C               ;peripheral control register of 6522(B3)
                ORA #%00001110          ;CA2 high (motor=OFF) Attention signal = NO ATTENTION
                STA $911C               ;

                ;raise CLOCK-line (cassette write-line)
                LDA $9122               ;data direction register of 6522(B1)
                ORA #%00001000          ;define PB3 as an output (make the DDR bit high)
                STA $9122               ;

                LDA $9120               ;data register of 6522(B1)
                ORA #%00001000          ;make PB3 high
                STA $9120               ;

                ;raise DATA-line (cassette button sense-line)
                LDA $911B               ;Auxilary control register of 6522(B3)
                AND #%11111110          ;clear bit 0 to disable latch on port A
                STA $911B               ;this setting is required further on in the code when we will use this pin as an INPUT

                LDA $9113               ;data direction register of 6522(B3)
                ORA #%01000000          ;define PA6 as an output
                STA $9113               ;

                LDA $911F               ;data register of 6522(B3)
                ORA #%01000000          ;make PA6 high
                STA $911F               ;


                ;set the READ-line properties (CA1 interrupt settings to falling edge)
                                        ;Peripheral control register of 6522(B1), we need to trigger on falling edges
                LDA #$DE                ;CB2 low, serial data out high, CB1 +ve edge, CA2 high, serial clock out low, CA1 -ve edge
                STA $912C               ;set VIA 2 PCR
        
                LDA #$82                ;enable CA1 interrupt
                STA $912E               ;set VIA 2 IER, enable interrupts

                RTS                     ;return to caller

;*******************************************************************************
; JSR CPIO_WAIT4RDY     ;wait untill the slave signals that it is ready
;
        ;this routine just keeps polling the 6522(B1)

CPIO_WAIT4RDY   LDA $912D               ;get the interrupt flags of 6522(B1)
                AND #%00000010          ;mask out bit CA1
                BEQ CPIO_WAIT4RDY       ;keep looping until the flag is set
                
                LDA $9121               ;reading port A of the 6522 clears the int flags
                RTS                     ;return to caller


;*******************************************************************************
;LDA <data>     ;data is the requested operating mode of the slave
;JSR CPIO_START  ;raise attention signal, now communication is set up, we can read or write data from this point
CPIO_START      STA CPIO_DATA       ;store value in A (which holds the mode-byte) to working register

                JSR CPIO_BACKOFF    ;make sure that the attention low signal is long enough low to be detected by the Cassiopei (placing it here ensures that 2 sequential but different data transfers are separated by a long enough low state of the ATN signal)

                SEI                 ;disable interrupts
  ;--this is a C64 line--;   LDA $DC0D           ;reading clears all flags, so when we do a Read here we clear the old interrupts so that our routines will trigger on the correct event (instead of an old unhandled event)
               
                LDA $911C           ;Attention signal = ATTENTION
                ORA #%00001100      ;define IO CA to proper mode
                AND #%11111101      ;CA2 low (motor=ON)
                STA $911C           ;

                JMP SEND_DATA       ;send the mode byte to the slave


;*******************************************************************************
;this routine will lower the attention to indicate that the current is the last byte
CPIO_SEND_LAST  STA CPIO_DATA       ;safe the data (stored in the accu) to a working register
                LDY #$08            ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine

                JSR CPIO_WAIT4RDY   ;wait untill the slave signals that it is ready

                LDA $911C           ;Attention signal = NO ATTENTION
                ORA #%00001110      ;CA2 high (motor=OFF)
                STA $911C           ;with the attention signal being low (motor-off) the slave has been notified that communication has come to an end and that the current byte is the last byte within this session

                LDA $9113           ;data direction register of 6522(B3)
                ORA #%01000000      ;define PA6 (data line) as an output
                STA $9113           ;

                JMP SEND_DATA_LP
;...............................................................................
;this routine will send a byte to the slave
;LDA <data>
;JSR CPIO_SEND

CPIO_SEND       STA CPIO_DATA       ;safe the data (stored in the accu) to a working register
SEND_DATA       LDY #$08            ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine

                LDA $9113           ;data direction register of 6522(B3)
                ORA #%01000000      ;define PA6 (data line) as an output
                STA $9113           ;

                JSR CPIO_WAIT4RDY   ;wait untill the slave signals that it is ready
                
SEND_DATA_LP
SEND_CLOCK_0    LDA $9120           ;data register of 6522(B1)
                AND #%11110111      ;make clock line low              
                STA $9120           ;

                BIT CPIO_DATA       ;bit moves bit-7 of CPIO_DATA into the N-flag of the status register
                BPL SEND_ZERO       ;BPL tests the N-flag, when it is 0 the branch to SEND_ZERO is executed (using the BIT instruction instead of conventional masking, we save 2 cycles, and 2 bytes)
SEND_ONE        LDA $911F           ;data register of 6522(B3)
                ORA #%01000000      ;make PA6 high
                JMP SEND_BIT        ;
SEND_ZERO       LDA $911F           ;data register of 6522(B3)
                AND #%10111111      ;make PA6 low

SEND_BIT        STA $911F           ;
SEND_CLOCK_1    LDA $9120           ;data register of 6522(B1)
                ORA #%00001000      ;make clock line high
                STA $9120           ;

                ASL CPIO_DATA       ;rotate data in order to send each individual bit, we do it here so that we save time, we have to wait for the clock pulse high-time anyway

                DEY                 ;decrement the Y value
                BNE SEND_DATA_LP    ;exit loop after the eight bit

                LDA $9120           ;data register of 6522(B1)
                AND #%11110111      ;make clock line low, the slave now reads the last bit of the data
                STA $9120           ;
                ORA #%00001000      ;make clock line high, to indicate that the byte has come to an end
                STA $9120           ;

                LDA $9113           ;data direction register of 6522(B3)
                AND #%10111111      ;define PA6 (data line) as an input
                STA $9113           ;

                RTS                 ;end of subroutine

;*******************************************************************************
;This routine will lower the attention to indicate that the current is the last byte
;
;example:       JSR CPIO_REC_LAST
;               data is in Accu
;...............................................................................
CPIO_REC_LAST   JSR CPIO_WAIT4RDY   ;wait untill the slave signals that it is ready

                LDA $911C           ;Attention signal = NO ATTENTION
                ORA #%00001110      ;CA2 high (motor=OFF)
                STA $911C           ;with the attention signal being low (motor-off) the slave has been notified that communication has come to an end and that the current byte is the last byte within this session

                LDY #$08            ;every byte consists of 8 bits, this will be use in the CPIO_send and CPIO_recieve routine which are calling this routine

REC_DATA_LP
REC_CLOCK_0     LDA $9120           ;data register of 6522(B1)
                AND #%11110111      ;make clock line low, the slave now prepares the data to be send
                STA $9120           ;

                LDA #$0             ;clear CPIO_DATA because it's value will eventually end up in the carry (because of ROL) and might screw up the ADC calculation
                STA CPIO_DATA       ;
                CLC                 ;clear the carry, which is usefull for the ADC later, we clear it here in order to make the clock=0 time 2 cycles longer (keeps our clock duty cycle closer to 50% (which is allways nice))
REC_CLOCK_1     LDA $9120           ;
                ORA #%00001000      ;make clock line high
                STA $9120           ;

                LDA $911F           ;read data line
                AND #%01000000      ;test input signal for '0' or '1'
                ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA       ;shift all the bits one position to the right and add the LSB which is located in the carry

                DEY                 ;decrement the Y value
                BNE REC_DATA_LP     ;exit loop after the eight bit

                LDA $9120           ;data register of 6522(B1)
                AND #%11110111      ;make clock line low, the slave now prepares the data to be send
                STA $9120           ;(this indicates to the slave that the master has read the data)
                ORA #%00001000      ;make clock line high to return to the default state
                STA $9120           ;
                
                LDA CPIO_DATA       ;move data to accu
                RTS                 ;end of subroutine


;*******************************************************************************
;this is an unrolled version of the CPIO_RECIEVE routine optimized for speed
;
;example:       JSR CPIO_RECIEVE
;               data is in Accu
;
;Attention: affects X and Y register
;...............................................................................
CPIO_RECIEVE    
                ;wait untill the slave signals that it is ready
                LDA #%00000010          ;the bitmask
CPIO_REC_W4R    BIT $912D               ;get the interrupt flags of 6522(B1)
                BEQ CPIO_REC_W4R        ;keep looping until the flag is set                
                LDA $9121               ;reading port A of the 6522 clears the int flags

                LDA $9120               ;data register of 6522(B1)
                AND #%11110111          ;make clock line low, the slave now prepares the data to be send
                STA $9120               ;
                TAX                     ;save for later use 
                ORA #%00001111          ;calculate state of write line (CLOCK) set to '1' (also set the memory configuration bits to a defined state, we choose to set them to the default state for a C64)
                TAY                     ;save for later use
                NOP                     ; waste time to honor the data setup times...
                NOP                     ;

                LDA #$00                ;must be zero, because every bit goes (because of the ROL instruction) through the carry and the carry must remain cleared
                STA CPIO_DATA           ;
                CLC                     ;clear the carry, which is usefull for the ADC later, we clear it here in order to make the clock=0 time 2 cycles longer (keeps our clock duty cycle closer to 50% (which is allways nice))

                ;bit 7
                STY $9120               ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA $911F               ;sample the data
                STX $9120               ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
               AND #%01000000      ;test input signal for '0' or '1'
               ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 6
                STY $9120               ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA $911F               ;sample the data
                STX $9120               ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
               AND #%01000000      ;test input signal for '0' or '1'
               ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 5
                STY $9120               ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA $911F               ;sample the data
                STX $9120               ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
               AND #%01000000      ;test input signal for '0' or '1'
               ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 4
                STY $9120               ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA $911F               ;sample the data
                STX $9120               ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
               AND #%01000000      ;test input signal for '0' or '1'
               ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 3
                STY $9120               ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA $911F               ;sample the data
                STX $9120               ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
               AND #%01000000      ;test input signal for '0' or '1'
               ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 2
                STY $9120               ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA $911F               ;sample the data
                STX $9120               ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
               AND #%01000000      ;test input signal for '0' or '1'
               ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 1
                STY $9120               ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA $911F               ;sample the data
                STX $9120               ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
               AND #%01000000      ;test input signal for '0' or '1'
               ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                ;bit 0
                STY $9120               ;changing state of write line (CLOCK) to '1', indicating that the data will be sampled
                LDA $911F               ;sample the data
                STX $9120               ;changing state of write line (CLOCK) to '0', this enables the Cassiopei to setup the mext databit
               AND #%01000000      ;test input signal for '0' or '1'
               ADC #%11111111      ;when our input is a '1' it will cause the carry bit to be set
                ROL CPIO_DATA           ;shift all the bits one position and add the LSB which is located in the carry

                STY $9120               ;changing state of write line (CLOCK) to '1', the idle state of this signal
                
                LDA CPIO_DATA       ;move data to accu
                RTS                 ;end of subroutine
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODOREVIC20"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
