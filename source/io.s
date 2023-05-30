
#ifdef __arm__

#include "ARM6502/M6502.i"
#include "RenegadeVideo/RenegadeVideo.i"

	.global ioReset
	.global IO_R
	.global IO_W
	.global soundIO_R
	.global soundIO_W
	.global refreshEMUjoypads

	.global joyCfg
	.global EMUinput
	.global gDipSwitch0
	.global gDipSwitch1
	.global gDipSwitch2
	.global gDipSwitch3
	.global coinCounter0
	.global coinCounter1

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
ioReset:
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
refreshEMUjoypads:			;@ Call every frame
;@----------------------------------------------------------------------------
		ldr r4,=frameTotal
		ldr r4,[r4]
		movs r0,r4,lsr#2		;@ C=frame&2 (autofire alternates every other frame)
	ldr r4,EMUinput
	and r0,r4,#0xf0
	mov r3,r4
		ldr r2,joyCfg
		andcs r4,r4,r2
		tstcs r4,r4,lsr#10		;@ L?
		andcs r4,r4,r2,lsr#16
//	adr r1,rlud2lrud
//	ldrb r1,[r1,r0,lsr#4]
	mov r0,r0,lsr#4

	tst r3,#0x800				;@ Y
	orrne r0,r0,#0x10			;@ Button 1 (atk left)
	tst r3,#0x400				;@ X
	orrne r0,r0,#0x20			;@ Button 2 (jmp)
//	tst r3,#0x02				;@ B
	tst r3,#0x01				;@ A
	mov r3,#0
	orrne r3,r3,#0x04			;@ Button 3 (atk right)

	mov r1,#0
	tst r4,#0x4					;@ Select
	orrne r1,r1,#0x40			;@ Coin 1
	tst r4,#0x8					;@ Start
	orrne r1,r1,#0x4000			;@ Start 1
	tst r2,#0x20000000			;@ Player2?
	mov r2,#0
	movne r1,r1,lsl#1
	movne r3,r3,lsl#1
	movne r2,r0
	movne r0,#0
	orr r0,r0,r1,lsr#8
	orr r2,r2,r1

	strb r0,joy0State
	strb r2,joy1State
	and r3,r3,#0x0C				;@ Attack right, P1/P2
	strb r3,joy2State
	bx lr

joyCfg: .long 0x00ff01ff	;@ byte0=auto mask, byte1=(saves R), byte2=R auto mask
							;@ bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
nrPlayers:	.long 0			;@ Number of players in multilink.
joySerial:	.byte 0
joy0State:	.byte 0
joy1State:	.byte 0
joy2State:	.byte 0
rlud2lrud:		.byte 0x00,0x02,0x01,0x03, 0x04,0x06,0x05,0x07, 0x08,0x0a,0x09,0x0b, 0x0c,0x0e,0x0d,0x0f
rlud2lrud180:	.byte 0x00,0x01,0x02,0x03, 0x08,0x09,0x0a,0x0b, 0x04,0x05,0x06,0x07, 0x0c,0x0d,0x0e,0x0f
gDipSwitch0:	.byte 0
gDipSwitch1:	.byte 0x50		;@ Coins, lives, bonus, cabinet & flip.
gDipSwitch2:	.byte 0
gDipSwitch3:	.byte 0
coinCounter0:	.long 0
coinCounter1:	.long 0

EMUinput:			;@ This label here for main.c to use
	.long 0			;@ EMUjoypad (this is what Emu sees)

;@----------------------------------------------------------------------------
Input0_R:		;@ Player 1 + Start
;@----------------------------------------------------------------------------
;@	mov r11,r11					;@ No$GBA breakpoint
	ldrb r0,joy0State
	eor r0,r0,#0xFF				;@ 0x3F for test mode
	bx lr
;@----------------------------------------------------------------------------
Input1_R:		;@ Player 2 + Coin
;@----------------------------------------------------------------------------
	ldrb r0,joy1State
	eor r0,r0,#0xFF
	bx lr
;@----------------------------------------------------------------------------
Input2_R:		;@ Coin setting, Service, mcu, VBlank & attack right.
;@----------------------------------------------------------------------------
	ldrb r0,gDipSwitch2
	ldrb r1,joy2State
	orr r0,r0,r1
	eor r0,r0,#0x9F
	bx lr
;@----------------------------------------------------------------------------
Input3_R:
;@----------------------------------------------------------------------------
	ldrb r0,gDipSwitch1
	eor r0,r0,#0xFF
	bx lr

;@----------------------------------------------------------------------------
IO_R:				;@ I/O read, 0x2000-0x3FFFF
;@----------------------------------------------------------------------------
	subs r1,addy,#0x3800
	bmi More_IO_R
	cmp r1,#8
	ldrmi pc,[pc,r1,lsl#2]
;@---------------------------
	b empty_IO_R
;@ io_read_tbl
	.long Input0_R			;@ 0x3800
	.long Input1_R			;@ 0x3801
	.long Input2_R			;@ 0x3802
	.long Input3_R			;@ 0x3803
	.long MCU04_R			;@ 0x3804
	.long MCU05_R			;@ 0x3805
	.long empty_IO_R		;@ 0x3806
	.long empty_IO_R		;@ 0x3807
;@----------------------------------------------------------------------------
More_IO_R:			;@ ram,
;@----------------------------------------------------------------------------
	cmp addy,#0x3200
	movpl r0,#0
	ldrbmi r0,[m6502zpage,addy]
	bx lr

;@----------------------------------------------------------------------------
IO_W:				;@ I/O write, 0x2000-0x3FFFF
;@----------------------------------------------------------------------------

	cmp addy,#0x3200
	bmi ram6502IOW
	subs r1,addy,#0x3800
	ldrpl reptr,=reVideo_0
	bpl reIOWrite
	b empty_IO_W

;@----------------------------------------------------------------------------
soundIO_R:				;@ I/O read, 0x0000-0x3FFFF
;@----------------------------------------------------------------------------
	and r1,addy,#0x3800
	ldr pc,[pc,r1,lsr#9]
;@---------------------------
	b empty_IO_R
;@ io_read_tbl
	.long mem6809R0			;@ 0x0000-0x07FF
	.long mem6809R0			;@ 0x0800-0x0FFF
	.long soundLatchRead	;@ 0x1000-0x17FF
	.long empty_IO_R		;@ 0x1800-0x1FFF
	.long empty_IO_R		;@ 0x2000-0x27FF
	.long ym3526_0_R		;@ 0x2800-0x2FFF
	.long empty_IO_R		;@ 0x3000-0x37FF
	.long empty_IO_R		;@ 0x3800-0x3FFF
;@----------------------------------------------------------------------------
soundLatchRead:
;@----------------------------------------------------------------------------
	ldr reptr,=reVideo_0
	b reLatchR

;@----------------------------------------------------------------------------
soundIO_W:				;@ I/O write, 0x0000-0x3FFFF
;@----------------------------------------------------------------------------
	and r1,addy,#0x3800
	ldr pc,[pc,r1,lsr#9]
;@---------------------------
	b empty_W
;@ io_write_tbl
	.long ram6809W			;@ 0x0000-0x07FF
	.long ram6809W			;@ 0x0800-0x0FFF
	.long empty_IO_W		;@ 0x1000-0x17FF
	.long adpcmR_W			;@ 0x1800-0x1FFF
	.long adpcmR_W			;@ 0x2000-0x27FF
	.long ym3526_0_W		;@ 0x2800-0x2FFF
	.long adpcmR_W			;@ 0x3000-0x37FF
	.long empty_IO_W		;@ 0x3800-0x3FFF

adpcmR_W:
	mov r0,#0
	bx lr
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
