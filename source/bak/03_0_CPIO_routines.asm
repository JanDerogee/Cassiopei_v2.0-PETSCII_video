;When the ATN signal goes down (end of attention) but the rises again very shortly
;afterwards it could be missed by the Cassiopei. Because the Cassiopei cannot
;confirm that ATN has been dropped. To make sure that the Cassiopei will not miss
;a falling attention signal a safe backoff time must be created. This routine will
;wait for 100ms. which is enough for he Cassiopei to detect.
;
;Although this routine is to be called after atn has been dropped, it would make
;programming more difficult because the read and write routines are generic and
;cannot really see if it is the last byte transmitted/received. Therefore the
;best place to call this routine is before start (or from within start).
;Because then it is always present and cannot be forgotten.

CPIO_BACKOFF    
                LDY #100                
BCKOFF_01       LDX #65         ;this loop will run for 1 ms (with screen=enabled, interrupts=enabled)

BCKOFF_02       PHA             ;3 cycles (1 cycle is 1,0149729 us (PAL))
                PLA             ;4 cycles
                DEX             ;2 cycles
                BNE BCKOFF_02   ;2 cycles

                DEY             ;2 cycles
                BNE BCKOFF_01   ;2 cycles

                RTS

