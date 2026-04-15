ADC_DATA:   EQU &H0C0
ADC_STATUS: EQU &H0C1
HEX_LO:     EQU &H004
HEX_HI:     EQU &H005

ORG 0

Loop:
    -- Upper two digits show the status register, including busy on bit 1.
    IN ADC_STATUS
    OUT HEX_HI

    -- Lower four digits show the most recent 12-bit ADC sample.
    IN ADC_DATA
    OUT HEX_LO

    JUMP Loop
