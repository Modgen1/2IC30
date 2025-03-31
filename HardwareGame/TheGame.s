@ Game_Template.s
@ Adam Watkins, Richard Verhoeven
@ December 2024

@ A simple random number guessing game
.global _start

.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_GETTIME, 0x4E
.equ STDOUT, 1
.equ STDIN, 0
.equ CLOCK_ADDR, 0x3F003004 @ Hardware clock address

.text
.include "Hardware.s"

@ Game control loop (between main: and _exit:)
@ Register usage:
@ R8: generated random number
@ R9: guesses remaining
_start:
        BL      open_mem            @ Open /dev/mem for hardware access
        LDR     R0, =CLOCK_ADDR     @ Load hardware clock address
        BL      map                 @ Map hardware clock to memory
        LDR     R1, =clockbase      @ Load address of clockbase variable
        STR     R0, [R1]            @ Store mapped memory address

        BL    gen_number

        MOV   R8, R0                @ Store 'hidden' number in R8
        MOV   R9, #8                @ Initialise remaining guesses to 3
        LDR   R0, =new_game         @ TASK: Load new game string
        MOV   R1, #new_game_len     @ TASK: Load new game string length
        BL    print                 @ Print the new game string
next_guess:
        LDR   R0, =prompt           @ TASK: Load prompt string address
        MOV   R1, #prompt_len       @ TASK: Load prompt length
        BL    print                 @ Print the prompt

        LDR   R0, =input            @ TASK: Load input buffer address
        MOV   R1, #3                @ TASK: Load input buffer length
        BL    read                  @ Read 3 chars to input buffer (including newline)

        LDR   R1, =input
        BL    asctonum          @ Convert string to integer.
        MOV   R1, R8            @ Copy hidden number
        MOV   R10, R0           @ Backup guessed number
        BL    print_hint        @ Print a hint

CMP   R10, R8           @ If the guess was correct,
        BEQ   extra_game             @   Exit
        SUBS  R9, #1            @ Reduce the remaining guesses (!)
        BGT   next_guess        @ Try next guess if available
        MOV   R0, R8            @ Pass 'hidden' number as argument.
        BL    print_lose        @ No guess remaining, you lose.

extra_game:
        BL    play_again        @ Ask for another game.
        CMP   R0, #0            @ IF answer is not ‘n’
        BNE   _start              @   restart the game.

exit:
        @ If using the RPI, uncomment the lines with the MOV and SWI instructions
        @ If using the simulator, comment the lines with the MOV and SWI instructions
        MOV     R7, #SYS_EXIT          @ Place code for Exit into R7
        SWI     0               @ Make a system call to end the program
        @ If using the RPI, comment the line with B exit
        @ If using the simulator, uncomment the line with B exit
        @B       exit

@ Functions

@@@@ play_again: Ask user if they want to play again or not
@ Parameters:
@   none
@ Returns:
@   R0: 0 if user entered 'n', non-zero otherwise
play_again:
        STMFD   SP!, {R1-R2, LR}    @ Push used registers and LR on the stack

        LDR     R0, =play_msg       @ Load address of play again message
        MOV     R1, #play_msg_len   @ Load length of play again message
        BL      print               @ Call print function

        LDR     R0, =input          @ Load input buffer address
        MOV     R1, #3              @ Read 3 characters (including newline)
        BL      read                @ Call read function

        LDR     R0, =input          @ Reload input buffer address
        LDRB    R0, [R0]            @ Load first character
        ORR     R0, R0, #0x20       @ Convert to lowercase

        SUB     R0, #0x6E        @ Subtract lowercase 'n'

        LDMFD   SP!, {R1-R2, LR}    @ Pop used registers from the stack
        MOV     PC, LR              @ Return

@@@@ print: Print a string to the terminal
@ Parameters:
@   R0: address of string
@   R1: length of string
@ Returns:
@   none
print:
        STMFD   SP!, {R7,LR}            @ Push used registers and LR on the stack;
        MOV R2, R1                              @ TASK: Move number of characters to print(R1) to R2
        MOV R1, R0                              @ TASK: Move address of output string(R0) to R1
        MOV R7, #SYS_WRITE                                      @ TASK: Put the Syscall number in R?
        MOV R0, #STDOUT                                 @ TASK: Put the monitor STDOUT in R?
        SWI 0                   @ TASK: Uncomment this line to make the syscall
        LDMFD   SP!, {R7,LR}            @ Restore used registers (update SP with !)
        MOV     PC, LR                  @ Return

@@@@ read: read a string from keyboard and store in variable
@ Parameters:
@   R0: address of where to store string
@   R1: number of characters to store
@ Returns:
@   none
read:
        STMFD SP!, {R7, LR}             @ Push used registers and LR to stack
        MOV R2, R1                              @ TASK: Move number of characters to read(R1) to R2
        MOV R1, R0                              @ TASK: Move address of input string(R0) to R1
        MOV R7, #SYS_READ                               @ TASK: Put the Syscall number in R?
        MOV R0, #STDIN                          @ TASK: Put the keyboard STDIN in R?
        SWI 0                                           @ TASK: Uncomment this line to make the syscall
        LDMFD SP!, {R7, LR}             @ Restore used registers (update SP with !)
        MOV  PC, LR

@@@@ asctonum: convert the ASCII hex characters in input to a number
@ Parameters:
@   R1: address of ASCII representation
@ Returns:
@   R0: calculated value
asctonum:
        STMFD   SP!, {R4-R5, LR}    @ TASK: Explain why this push occurs
        MOV     R4, #0              @ character count: find out where the newline is
        MOV     R5, #0              @ number entered in hex
nextchar:
        LDRB    R0, [R1,R4]         @ load byte from address R1 + R4
        CMP     R0, #0xA            @ TASK: Explain the purpose of this line of code
        BEQ     readall             @ done reading
        BL      atoi                @ convert to hex
        CMP     R4, #1              @ is this the first character read?
        BLT     first
                                    @ shift R5 4 bits to the left
        MOV     R5, R5, LSL #4      @ (most significant digit)
                                    @ TASK: Explain why (in the above) we perfom a shift
first:
        ADD     R5, R0              @ add R0
        ADD     R4, #1              @ increment counter
        BAL     nextchar
readall:
        MOV     R0, R5
        LDMFD   SP!, {R4-R5, LR}
        MOV     PC, LR

@@@@ numtoasc: Convert the number to a hexadecimal ASCII string
@ Parameters:
@   R0: value to convert
@   R1: address of string
@ Returns:
@   none
numtoasc:
        STMFD   SP!, {R4, LR}           @ TASK: Explain why this push occurs
        MOV     R4, R0                  @ copy number
        AND     R0, #0xF0               @ mask off ms-nibble
        MOV     R0, R0, LSR #4          @ shift to right
        BL      itoa                    @ convert to ASCII
        STRB    R0, [R1]                @ store byte at R1
        MOV     R0, R4                  @ reload R0
        AND     R0, #0xF                @ mask off ls-nibble
        BL      itoa                    @ convert to ASCII
        STRB    R0, [R1, #1]            @ store 2nd character
        MOV     R0, #0xA                @ newline
        STRB    R0, [R1, #2]            @ store at end of string
        LDMFD   SP!, {R4, LR}
        MOV     PC, LR

@@@@ atoi:              Convert ASCII hex character to its integer value
@ Parameters:
@   R0: ASCII character (assumed '0'-'9', 'A'-'F' or 'a'-'f')
@ Returns:
@   R0: Integer value of provided character
atoi:
        CMP     R0, #0x40               @ Compare with the character smaller than 'A/a'
        SUBLT   R0, #0x30               @ If in range 0-9, substract '0'
        ORRGT   R0, #0x60               @ If in range A-F or a-f, force lower case ...
        SUBGT   R0, #0x57               @    and substract 'a'-10
        MOV     PC, LR


@@@@ itoa:              Convert integer value to ASCII hex character
@ Parameters:
@   R0: integer value in range 0-15
@ Returns:
@   R0: related ASCII character ('0'-'9', 'A'-'F')
itoa:
        CMP     R0, #0x39               @ Compare with the character smaller than 'A/a'
        ADDLE   R0, #0x30               @ If in range 0-9, add '0'
        ADDGT   R0, #0x31               @    and add 'a'-10
        MOV     PC, LR

@@@@ gen_number: Generate a number based on the hardware clock
@ Parameters:
@   none
@ Returns:
@   R0: 7-bit 'random' value
gen_number:
        STMFD   SP!, {R1}
        LDR     R1, =clockbase      @ Load mapped memory address
        LDR     R1, [R1]            @ Load mapped memory address contents
        CMP     R1, #0              @ Check if clockbase was initialized
        MOVEQ   R0, #0x7F          @ If not initialized, return max value
        LDRGT   R0, [R1, #4]        @ Otherwise, load hardware clock value.
        AND     R0, #0x7F           @ Mask lower 7 bits (0-127)
        LDMFD   SP!, {R1}
        MOV     PC, LR

@@@@ print_hint:        Indicate whether the number is higher, lower or correct.
@ Parameters:
@   R0: guessed value
@   R1: 'hidden' random value
@ Returns:
@   none
print_hint:
        STMFD   SP!, {R1-R2,LR}
        CMP     R1, R0              @ Compare hidden and guessed value
        LDREQ   R0, =congrats       @ If equal, select congrats ...
        MOVEQ   R1, #congrats_len   @   ... and its length
        LDRLT   R0, =lower          @ If less than, select lower
        MOVLT   R1, #lower_len
        LDRGT   R0, =higher         @ If greater than, select higher
        MOVGT   R1, #higher_len
        BL      print               @ Print that was selected.
        LDMFD   SP!, {R1-R2,LR}
        MOV     PC, LR

@@@@ print_lose: Reveal the hidden number
@ Parameters:
@   R0: 'hidden' random value
@   none
print_lose:
        STMFD   SP!, {R1-R2, LR}
        LDR     R1, =lostgame       @ Load 'lost-game' string buffer reference
        ADD     R1, #value_offset   @ Adjust to the position of the number
        BL      numtoasc            @ Write hidden value to buffer
        LDR     R0, =lostgame       @ Restore buffer reference
        MOV     R1, #lostgame_len   @ ... and its length
        BL      print               @ Print string with the number
        LDMFD   SP!, {R1-R2, LR}
        MOV     PC, LR

@@@@@ Constants
.data

prompt:           .asciz  "Guess a number from 00 to FF\n"            @ TASK: Modify the prompt to include the range of values
.equ              prompt_len, 29
higher:           .asciz  "Higher\n"
.equ              higher_len, 7
lower:            .asciz  "Lower\n"
.equ              lower_len, 6
congrats:         .asciz  "Congrats, you guessed it\n"
.equ              congrats_len, 25
new_game:         .asciz  "You have 8 attempts to guess\n"
.equ              new_game_len, 29
lostgame:         .asciz  "You lose, the number was 00\n"
.equ              lostgame_len, 28
.equ              value_offset, 25  @ index into the lostgame
                                    @ string so the number
                                    @ can be written into it.
play_msg:         .asciz "Play again? (y/n)\n"
.equ              play_msg_len, 18

@@@@ Variables
.align
input:            .space 3                                      @ TASK: Create user guess variable here (input buffer)
.align
time:             .space 4              @ Time (s) since Jan 1 1970
musecs:           .space 4              @ Time (ms)
clockbase:        .word 0x0           @ Added for hardware access
file_desc:        .word 0x0           @ Added for hardware access
dev_mem:          .asciz "/dev/mem"   @ Added for hardware access