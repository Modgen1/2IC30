@ Init_Pins.s
@ Adam Watkins, Richard Verhoeven
@ November 2020

@ A function to initilise all GPIO pins for the gertboard LEDs to output.
@ This file will not assemble/compile as a standalone


@@@@@ init_pins : initialize multiple pins of routput only
@ Parameters:
@  none
@ Returns:
@  none
init_pins:
	    STMFD SP!, {R0-R4,LR}
	    MOV	    R3, #1			    @ loop counter
next_pin:
	    MOV	    R0, R3			    @ pin number
	    MOV	    R1, #0			    @ input
	    BL	    set_pin_function	@ set to input
	    CMP	    R0, #0			    @ error (not in use or other
					                @ purpose for pin)
	    BLT	    incpinloop		    @ next pin
	    MOV	    R0, R3			    @ reload pin number
	    MOV	    R1, #1			    @ output
	    BL	    set_pin_function	@ set to output
	    MOV	    R0, R3			    @ reload pin number
	    MOV 	R1, #0x28		    @ clear pin
	    BL	    set_pin_value		@ no need to check for error again
incpinloop:
	    ADD	    R3, #1			    @ loop_counter++
	    CMP 	R3, #27			    @ last pin?
	    BLE	next_pin
	    LDMFD	SP!, {R0-R4,LR}
	    MOV     PC, LR
