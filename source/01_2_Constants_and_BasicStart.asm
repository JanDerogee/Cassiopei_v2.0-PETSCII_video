;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ifdef COMMODOREVIC20
;-------------------------------------------------------------------------------

*=$1201
        ;Start address $1201, end address $1214, size 20, on 27-9-2014 10:24:15, to file %file%
        BYTE $13,$10,$01,$00,$9e,$33,$32,$aa,$32,$35,$36,$ac,$c2,$28,$34,$34,$29,$00,$00,$00
        ;End address $1214

*=$1220
        
    ;The VIC-20 is a strange beast, because it will move basic start and charscreen depending on
    ;the memory expansion placed. Therefore because the program is loaded to an (during programming)
    ;unknown loaction and may require to be relocated to the intended memory locations.

    ;This routine is started with the basic stub:
    ; 1 SYS32+256*peek(44) (32=$20, meaning that our .asm must start from $xx20)
    ;
    ;First we must check if relocation is required! So where are we now?
    ;or actually where is basic start, because if it is $1201 we are ok.
    ;
    ;To make things a little more complicated, our source and destination
    ;might overlap! Therefore in order to copy it safely to the new location
    ;(which is in the always available $12XX region) we copy from end to start (backwards)
    ;
    ;ATTENTION PROGRAMMER: relocating code can not use absolute jumps or addressing!

RELOC           LDA $2C                 ;
                CMP #$12                ;$12XX (XX is always 01 unless somebody messed with it, which is highly unlikely)
                BEQ RELOC_DONE          ;code already at the correct location

                ;program_size = END_OF_PROGRAM - INIT
                ;first byte in memory = contents of $2C + low byte of label INIT
                ;last byte in memory = first byte in memory + program_size

RELOC_REQ       LDA #<END_OF_PROGRAM    ;store destination address in zero-page variable
                STA DEST_ADR            ;===============================================
                LDA #>END_OF_PROGRAM    ;  
                STA DEST_ADR+1          ;high byte

                LDA #<INIT              ;calculate first byte of code to be relocated in memory
                STA SOURCE_ADR          ;======================================================
                LDA $2C                 ;  
                STA SOURCE_ADR+1        ;high byte

        ;------------------------------------------------------------------------------
        ;ATTENTION: make sure that the option "calc address first then high/low byte"
        ;in CBM program studio is selected. Otherwise the lines below WILL fail!!!!!!!
        ;------------------------------------------------------------------------------
                
                CLC                     ;add program size to get to the last byte
                LDA SOURCE_ADR          ;========================================
                ADC #<PRGSIZE           ;this might cause a carry that we will use in the next addition
                STA SOURCE_ADR          ;
                LDA #>PRGSIZE           ;
                ADC SOURCE_ADR+1        ;add carry to high byte (if there was any)
                STA SOURCE_ADR+1        ;

                CLV                     ;the overflow flag is not affected by any of the opcodes below, so it does not change in our loop, clearing it here keeps the loop faster
                LDY #$00                ;the Y-reg is not affected by any of the opcodes below, so it does not change in our loop, clearing it here keeps the loop smaller
RELOC_LP        LDA (SOURCE_ADR),Y      ;the actual moving of the program (the copy loop)
                STA (DEST_ADR),Y        ;================================================
                ;STA $900F  ;!DEBUG ONLY!

                LDA DEST_ADR+1          ;check if we reached the last byte that must be relocated (which is actually the first byte of our program because we are relocating backwards)
                CMP #>INIT              ;==============================================================================================================================================
                BNE RELOC_00            ;
                LDA DEST_ADR            ;low byte of last written address
                CMP #<INIT              ;
                BEQ RELOC_DONE          ;
                                                
RELOC_00        DEC SOURCE_ADR          ;calculate next addresses
                LDA SOURCE_ADR          ;
                CMP #$FF                ;
                BNE RELOC_01            ;========================
                DEC SOURCE_ADR+1        ;overflow detected, so we must also decrement high-byte
RELOC_01        DEC DEST_ADR            ;decrement low-byte
                LDA DEST_ADR            ;
                CMP #$FF                ;
                BNE RELOC_02            ;check for overflow of low byte
                DEC DEST_ADR+1          ;overflow detected, so we must also decrement high-byte
RELOC_02        ;CLV                    ;force conditional branch, we must do this because we can't
                BVC RELOC_LP            ;use an absolute jump and conditinal branches are relative jumps

RELOC_DONE      ;relocate warm-start vector
                LDA #<INIT              ;to stop the animation, use runstop+restore
                STA $0328               ;however this requires us to re-route the vector
                LDA #>INIT              ;to our own program instead of the warm-start vector
                STA $0329               ;This is the only way because the keyboard IO could interfere with the Cassiopei CPIO communication

                JMP INIT                ;code is now at the correct location, so we may start it





;;-- zeropage RAM registers --
;we use only the 0-page locations that are marked as "unused" or "free 0-page space for user programs"
CPIO_DATA       = $02   ;this zeropage memory location is used to parse the CPIO data

ADDR            = $61  ;pointer
ADDR+1          = $62  ;     
 
ADDR_LAST_TILE  = $F7  ;pointer (used in NORMAL mode, for detection of the last tile,
;ADDR_LAST_TILE+1= $F8  ;this way we don't have to keep a counter, we just compare two 16-bit values)
CNTR            = $F9  ;pointer (used in DELTA mode, since the last tile is unpredictable, this counter just counts the number of tiles
;CNTR+1          = $FA  ;until it matches the "changed tiles" value of the image)      

STR_ADDR        = $6E  ;pointer to string
;STR_ADDR+1     = $6F  ;           

SOURCE_ADR      = $F7   ;for relocation we must have a pointer (of location of source data)
;SOURCE_ADR+1   = $F8   ;
DEST_ADR        = $F9   ;for relocation we must have a pointer (of destination location)
;DEST_ADR+1     = $FA   ;

CHAR_ADDR       = $FC
;CHAR_ADDR+1    = $FD



;-- build related settings --
WINDOW_X_POS    = 0             ;the X-distance from top-left
WINDOW_Y_POS    = 5             ;the Y-distance from top-left
WINDOW_X_SIZE   = 22            ;the X-size of the window to be scrolled
WINDOW_Y_SIZE   = 10            ;the Y-size of the window to be scrolled

SUPPORTED_X_SIZE = 22           ;screen width of a VIC20 is 22 columns
SUPPORTED_Y_SIZE = 23           ;screen width of a VIC20 is 23 rows

;-------------------------------------------------------------------------------
endif   ;this endif belongs to "ifdef COMMODOREVIC20"
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
