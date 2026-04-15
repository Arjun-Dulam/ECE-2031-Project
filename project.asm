; --- SCOMP ADC to Decimal Display ---
; Reads LTC2308 ADC (Address &H0C0)
; Converts 12-bit value to decimal and displays on HEX DISP (&H004)

ADC_DATA:   EQU &H0C0
ADC_STATUS: EQU &H0C1
HEX_DISP:   EQU &H004

            ORG  0

; --- Main Loop ---
POLL_ADC:   IN   ADC_DATA   ; Grab the latest 12-bit sample (0-4095)
            STORE REMAIND   ; This is our "Input" for the division logic

            ; Reset counters for a fresh conversion
            LOADI 0
            STORE THOUS
            STORE HUNDS
            STORE TENS

; --- Thousands Extraction ---
T_LOOP:     LOAD  REMAIND
            SUB   C_1000
            JNEG  T_DONE
            STORE REMAIND
            LOAD  THOUS
            ADDI  1
            STORE THOUS
            JUMP  T_LOOP

; --- Hundreds Extraction ---
T_DONE:     
H_LOOP:
            LOAD  REMAIND
            SUB   C_100
            JNEG  H_DONE
            STORE REMAIND
            LOAD  HUNDS
            ADDI  1
            STORE HUNDS
            JUMP  H_LOOP

; --- Tens Extraction ---
H_DONE:     
TE_LOOP:
            LOAD  REMAIND
            SUB   C_10
            JNEG  TE_DONE
            STORE REMAIND
            LOAD  TENS
            ADDI  1
            STORE TENS
            JUMP  TE_LOOP

TE_DONE:    ; REMAIND now holds the ones digit

; --- Pack Digits for Hex Display ---
; AC = [THOUS][HUNDS][TENS][ONES]
            LOAD  THOUS
            SHIFT 4
            ADD   HUNDS
            SHIFT 4
            ADD   TENS
            SHIFT 4
            ADD   REMAIND

            OUT   HEX_DISP  ; Update the physical 7-segment display

            JUMP  POLL_ADC  ; Go back and read the ADC again

; --- Data Section ---
REMAIND:  DW 0
THOUS:    DW 0
HUNDS:    DW 0
TENS:     DW 0
C_1000:   DW 1000
C_100:    DW 100
C_10:     DW 10