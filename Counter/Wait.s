@ Wait.s
@ Adam Watkins, Richard Verhoeven
@ November 2020

@ A function to implement a delay based on the System Timer
@ This file will not assemble/compile as a standalone

@@@@@ wait: wait for R0 milliseconds.
@ Arguments:
@	R0: number of milliseconds
@ Returns:
@   None
wait:
        STMFD	SP!, {R2-R5,LR}
        CMP	    R0, #0
        BLE	    wait_exit	        @ Don't wait zero or negative time.
        MOV	    R2, #125
        MOV	    R2, R2, LSL #3      @ R2 = 1000
        MULS    R0, R0, R2	        @ Convert milliseconds to microseconds
        BVS	    wait_exit	        @ In case of an overflow, exit.
        LDR	    R3, =clockbase		@ Load clockbase address
        LDR	    R3, [R3]	        @ Load clockbase value
        LDR	    R2, [R3,#4]         @ Read current CLO value
        SUB	    R5, R2, #1	        @ Save current CLO - 1
        ADDS    R4, R2, R0	        @ Add number of microseconds
        BCC	    wait_clk	        @ No carry, skip waiting for rollover.
wait_rollover:
        LDR	    R2, [R3,#4]
        CMP	    R2, R5		        @ Compare current to past time
        BHI	wait_rollover	        @ If higher/same, wait some more
        @ special condition:
        @ R4 = 2^32-N and process is not active during N microseconds
        @ overflow will happen while waiting
        MOV	    R5, R2		        @ Save last CLO value
wait_clk:
        LDR	    R2, [R3,#4]			@ Read current CLO value
        CMP	    R5, R2				@ Compare current to past time
        BHI	    wait_exit	        @ If higher then exit
        MOV	    R5, R2				@ Save last CLO value
        CMP	    R4, R2				@ Compare to target time
        BHI	    wait_clk	        @ If higher, wait some more
wait_exit:
        LDMFD   SP!, {R2-R5,LR}
        MOV     PC, LR
