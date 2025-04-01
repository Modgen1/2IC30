
.global main

.equ        SYS_EXIT,   0x1
.equ        DELAY_MS,   100         @ Delay between counts in milliseconds
.equ        MAX_CYCLES, 10          @ Number of complete 0-1023 cycles to run

.text
.include "Init_pins.s"
.include "Hardware2.s"
.include "Wait.s"
.include "Binary.s"

main:
        BL      map_io              @ Open /dev/mem and map hardware
        BL      init_pins           @ Initialize GPIO pins
        
        MOV     R4, #0              @ R4 = cycle counter
        MOV     R5, #0              @ R5 = current count value
        
main_loop:
        @ Display current count
        MOV     R0, R5
        BL      disp_num
        
        @ Delay
        MOV     R0, #DELAY_MS
        BL      wait
        
        @ Increment count
        ADD     R5, R5, #1
        
        @ Check if we've reached 1023
        CMP     R5, #1024
        BLT     check_cycles
        
        @ Reset count and increment cycle counter
        MOV     R5, #0
        ADD     R4, R4, #1
        
check_cycles:
        @ Check if we've completed enough cycles
        CMP     R4, #MAX_CYCLES
        BLT     main_loop
        
exit:
        BL      unmap_io            @ Unmap and close hardware addresses
        MOV     R7, #SYS_EXIT
        SWI     0

