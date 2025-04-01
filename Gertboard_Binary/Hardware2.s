@ Hardware.s
@ Adam Watkins, Richard Verhoeven
@ December 2021

.equ        SYS_OPEN,   0x5             @ Add system call numbers
.equ        SYS_CLOSE,  0x6             @ Can be hex or dec
.equ        SYS_MAP,    0xC0
.equ        SYS_UNMAP,  0x5B

.equ		GPIO_ADDR,	0x3F200000		@ GPIO_Base for RPi 3 
.equ		CLOCK_ADDR, 0x3F003000		@ Clock address for RPi3

.equ	    PROT_FLAGS, 	0x101002	@ Create the flags constant
.equ        MAP_SIZE,   4096
.equ        MAP_RDorWR, 0x03    		@ PROT_READ || PROT_WRITE
.equ	    MAP_SHARED,	0x01    		@ We will share the mapped mem with any other
                                		@ processes that require it.

@Functions

@@@@ map_io : map all required hardware addresses to memory
@ Parameters :
@   None
@ Returns :
@   None
map_io:
        STMFD 	SP!, {R0-R1, LR}
		BL		open_mem            @ open /dev/mem
		LDR		R0, =GPIO_ADDR	    @ load GPIO hardware address
		BL		map		            @ map GPIO block in memory
		LDR 	R1, =gpiobase	    @ store address in gpiobase variable
	   	STR		R0, [R1]
    	LDR		R0, =CLOCK_ADDR	    @ load clock hardware address
    	BL		map		            @ map clock block in memory
    	LDR		R1, =clockbase	    @ store address in clockbase variable
    	STR		R0, [R1]
    	LDMFD 	SP!, {R0-R1, LR}
    	MOV     PC, LR

@@@@ unmap_io : unmap all hardware addresses from memory and close file ref
@ Parameters :
@   None
@ Returns :
@   None
unmap_io:
		STMFD 	SP!, {R0, LR}
		LDR		R0, =gpiobase           @ Load mapped GPIO address
		LDR		R0, [R0]
		BL		unmap                   @ Unmap it
		LDR		R0, =clockbase          @ Load mapped System Timer address
		LDR		R0, [R0]
		BL		unmap                   @ Unmap it
		LDR	    R1, =file_desc 	    	@ Load file decriptor address
        LDR	    R0, [R1]            	@ Load file descriptor value
		BL		close_mem               @ Close device file
		LDMFD 	SP!, {R0, LR}
		MOV     PC, LR



@@@@ open_mem:      Open a hardware memory location
@ Parameters:
@   None
@ Returns:  
@   R0:             File descriptor (descriptor) of /dev/mem file 
open_mem:
        STMFD   SP!, {R1,R7,LR} 
        LDR     R0, =dev_mem        @ Load address of the string "/dev/mem"
        LDR     R1, =PROT_FLAGS     @ Load value of flags to set permissions
        MOV     R7, #SYS_OPEN       @ Load open system call number
        SWI     0                   @ open /dev/mem returns file descriptor R0
        CMP     R0, #0              @ If file descriptor value
        LDRGE   R1, =file_desc      @   >0 then load address of file descriptor variable
        STRGE   R0, [R1]            @           and store descriptor value  to variable
        LDMFD   SP!, {R1, R7, LR}
        MOV     PC, LR

@@@@ map:           Map a 4096 byte block of physical memory to Pi's address space
@ Parameters:
@   R0:             Start address of memory to be mapped
@ Returns:
@   R0:             Start address of mapped memory in Pi's address space
@   R1:             Base of the memory block (4096 boundary)
map:
         STMFD   SP!, {R2-R7, LR}    @ Push used registers to stack
        MOV     R7, #SYS_MAP        @ Load map system call number
                                    @ Set parameters for map system call:
        MOV     R1, #MAP_SIZE       @ Set parameter to use a 4KB size subset of memory
        MOV     R2, #MAP_RDorWR     @ Set parameter for protection to PROT_READ || PROT_WRITE
        MOV     R3, #MAP_SHARED     @ Set parameter for map flags (MAP_SHARED)
        MOV		R5, R0, LSR #12     @ Right Shift the address to map (currently in R0) by 12
                                    @       and place in page offset parameter register
                                    @ Add comment - why right shift by 12?
                                    @       Divides address by 4096 (map requires address in blocks
                                    @       of 4096)
        MOV     R0, #0              @ Set parameter to let the kernel choose where to map the memory
        LDR     R4, =file_desc      @ Set parameter for file descriptor value
        LDR     R4, [R4]
        CMP     R4, #0              @ If value of file descriptor
        SWIGT   0                   @      > 0 then make the system call
        CMP     R4, #-1             @ If value of file descriptor 
        MOVEQ   R0, #0              @      =-1 then return base of memory block 
                                    @ The address to use in the program
                                    @ is returned in R0

        LDMFD   SP!, {R2-R7, LR}    @ Restore used registers
        MOV     PC, LR

@@@@ unmap: Unmap the physical memory from the Pi's address space
@ Parameters:
@   R0: Start address of map
@ Returns:
@   None
unmap:
        STMFD   SP!, {R1, R7, LR}
        MOV     R1, #MAP_SIZE       @ set the length of the map
        MOV     R7, #SYS_UNMAP      @ set the unmap system call
        SWI     0                   @ 
        LDMFD   SP!, {R1, R7, LR}
        MOV     PC, LR

@@@@ close: Release access to a hardware memory location
@ Parameters:
@   R0: File descriptor
@ Returns:
@   None
close_mem:
        STMFD SP!, {R0,R1,R7,LR}
        MOV     R7, #SYS_CLOSE      @ Close system call
        CMP     R0, #0              @ If file was opened
        SWINE   0                   @     then close
        MOV     R7,#0               @ Clear file decriptor in register
        STR     R7, [R1]            @ Store cleared descriptor in variable
        LDMFD   SP!, {R0,R1,R7,LR}
        MOV     PC, LR
