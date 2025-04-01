
.global main

.equ        SYS_EXIT,   0x1
.equ        SYS_READ,   0x3
.equ        STDIN,      0x0
.equ        DELAY_MS,   100         @ Delay between counts in milliseconds
.equ        MAX_CYCLES, 5           @ Number of complete cycles to run

.text
.include "Init_pins.s"
.include "Hardware2.s"
.include "Wait.s"
.include "Binary.s"

main:
        BL      map_io              @ Open /dev/mem and map hardware
        BL      init_pins           @ Initialize GPIO pins
        
        @ Read user input 
        MOV     R7, #SYS_READ
        MOV     R0, #STDIN
        LDR     R1, =input_buffer
        MOV     R2, #1              @ Read 1 character
        SWI     0
        
        @ Determine counting direction based on input
        LDR     R0, =input_buffer
        LDRB    R0, [R0]
        CMP     R0, #'1'
        MOVEQ   R6, #1              @ R6 = 1 for counting up
        MOVNE   R6, #0              @ R6 = 0 for counting down
        
        MOV     R4, #0              @ R4 = cycle counter
        
        @ Set initial count based on direction
        CMP     R6, #1
        MOVEQ   R5, #0              @ Start at 0 for counting up
        MOVNE   R5, #1023           @ Start at 1023 for counting down
        
main_loop:
        @ Display current count
        MOV     R0, R5
        BL      disp_num
        
        @ Delay
        MOV     R0, #DELAY_MS
        BL      wait
        
        @ Update count based on direction
        CMP     R6, #1
        ADDEQ   R5, R5, #1          @ Increment if counting up
        SUBNE   R5, R5, #1          @ Decrement if counting down
        
        @ Check if we've completed a full cycle
        CMP     R6, #1
        BNE     check_down_cycle
        
        @ For counting up, check if we've reached 1023
        CMP     R5, #1024
        BLT     check_cycles
        
        @ Reset count and increment cycle counter
        MOV     R5, #0
        ADD     R4, R4, #1
        B       check_cycles
        
check_down_cycle:
        @ For counting down, check if we've reached 0
        CMP     R5, #0
        BGT     check_cycles
        
        @ Reset count and increment cycle counter
        MOV     R5, #1023
        ADD     R4, R4, #1
        
check_cycles:
        @ Check if we've completed enough cycles
        CMP     R4, #MAX_CYCLES
        BLT     main_loop
        
exit:
        BL      unmap_io            @ Unmap and close hardware addresses
        MOV     R7, #SYS_EXIT
        SWI     0

.data
input_buffer:   .space 2