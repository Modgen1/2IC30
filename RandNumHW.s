@ RandNumHW.s
@ Adam Watkins 
@ November 2024

.global     main

.equ        RAND_LIMIT, 0xF     @ Question: What is the maximum value possible?
.equ        SYS_EXIT,   0x1
.equ        CLOCK_ADDR, 0x3F003004   @ TASK: Add clock hardware address constant

.text 
.include "Hardware.s"


main:     
    BL      open_mem            @ Open /dev/mem  (requires sudo)
    LDR     R0, =CLOCK_ADDR     @ TASK: Load hardware clock address
    BL      map                 @ Map hardware clock to memory (R0 contains address)
    LDR     R1, =clockbase      @ TASK: Load address of clockbase variable
    STR     R0, [R1]            @ Store mapped memory start address in variable clockbase

    BL      gen_number_hardware @ Generate a random number (returned in R0)
    MOV     R8, R0              @ Temporary store for random number

exit:
    LDR     R0, =clockbase      @ Load start address of map
    BL      unmap               @ Unmap the access to hardware
    LDR     R0, file_desc       @ TASK: Load the value of the file descriptor
    @ LDR R0, =file_desc
    @ LDR R0, [R0]
    BL      close_mem           @ Close /dev/mem
    MOV     R0, R8              @ Place random number in R0 (view on terminal with echo $?)
    MOV     R7, #SYS_EXIT       @ exit syscall
    SWI     0

@ Functions

@@@@ gen_number_hardware: Generate a number based on the hardware clock
@ Parameters:
@   none
@ Returns: 
@   R0:             7-bit 'random' value
gen_number_hardware:
    STMFD   SP!, {R1}           @ R1 used in this function so store on stack
    LDR     R1, =clockbase      @ Load mapped memory address
    LDR     R1, [R1]            @ Load mapped memory address contents
    CMP     R1, #0              @ Check if clockbase was initialized
    MOVEQ   R0, #RAND_LIMIT     @ If not initialized, return a fixed number.
    LDRGT   R0, [R1, #4]        @ Otherwise, load hardware clock value.
    AND     R0, #RAND_LIMIT     @ Mask lower 7 bits
    LDMFD   SP!, {R1}
    MOV     PC, LR


                                    
.data     

@@@@ Constants

dev_mem:        .asciz "/dev/mem"   @ TASK: Add string constant for filename

.align 4
file_desc:      .word 0x0           @ File descriptor for /dev/mem
clockbase:      .word 0x0           @ TASK: Add variable to store start of mapped hardware address

