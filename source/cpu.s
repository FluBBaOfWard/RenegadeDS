
#ifdef __arm__

#include "Shared/nds_asm.h"
#include "ARM6502/M6502mac.h"
#include "ARM6809/ARM6809.i"
#include "RenegadeVideo/RenegadeVideo.i"

#define CYCLE_PSL (96)

	.global run
	.global stepFrame
	.global cpuInit
	.global cpuReset
	.global frameTotal
	.global waitMaskIn
	.global waitMaskOut
	.global soundCpuSetIRQ

	.global m6502Base

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
run:					;@ Return after 1 frame
	.type   run STT_FUNC
;@----------------------------------------------------------------------------
	ldrh r0,waitCountIn
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountIn
	bxne lr
	stmfd sp!,{r4-r11,lr}

;@----------------------------------------------------------------------------
runStart:
;@----------------------------------------------------------------------------
	ldr r0,=EMUinput
	ldr r0,[r0]

	ldr r2,=yStart
	ldrb r1,[r2]
	tst r0,#0x200				;@ L?
	subsne r1,#1
	movmi r1,#0
	tst r0,#0x100				;@ R?
	addne r1,#1
	cmp r1,#GAME_HEIGHT-SCREEN_HEIGHT
	movpl r1,#GAME_HEIGHT-SCREEN_HEIGHT
	strb r1,[r2]

	bl refreshEMUjoypads		;@ Z=1 if communication ok
;@----------------------------------------------------------------------------
reFrameLoop:
;@----------------------------------------------------------------------------
	ldr m6809optbl,=m6809OpTable
	ldr r0,m6809CyclesPerScanline
	bl m6809RestoreAndRunXCycles
	add r0,m6809optbl,#m6809Regs
	stmia r0,{m6809f-m6809pc,m6809sp}		;@ Save M6809 state
;@--------------------------------------
	ldr m6502ptr,=m6502Base
	ldr r0,m6502CyclesPerScanline
	bl m6502RestoreAndRunXCycles
	add r0,m6502ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}				;@ Save M6502 state
;@--------------------------------------
	ldr reptr,=reVideo_0
	bl doScanline
	cmp r0,#0
	bne reFrameLoop
;@----------------------------------------------------------------------------

	ldr r1,=fpsValue
	ldr r0,[r1]
	add r0,r0,#1
	str r0,[r1]

	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldrh r0,waitCountOut
	add r0,r0,#1
	ands r0,r0,r0,lsr#8
	strb r0,waitCountOut
	ldmfdeq sp!,{r4-r11,lr}		;@ Exit here if doing single frame:
	bxeq lr						;@ Return to rommenu()
	b runStart

;@----------------------------------------------------------------------------
soundCpuSetIRQ:					;@ Sound latch write/read
;@----------------------------------------------------------------------------
	stmfd sp!,{m6809optbl,lr}
	ldr m6809optbl,=m6809OpTable
	bl m6809SetIRQPin
	ldmfd sp!,{m6809optbl,pc}
;@----------------------------------------------------------------------------
m6502CyclesPerScanline:	.long 0
m6809CyclesPerScanline:	.long 0
frameTotal:			.long 0		;@ Let Gui.c see frame count for savestates
waitCountIn:		.byte 0
waitMaskIn:			.byte 0
waitCountOut:		.byte 0
waitMaskOut:		.byte 0

;@----------------------------------------------------------------------------
stepFrame:					;@ Return after 1 frame
	.type   stepFrame STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
;@----------------------------------------------------------------------------
reStepLoop:
;@----------------------------------------------------------------------------
	ldr m6809optbl,=m6809OpTable
	ldr r0,m6809CyclesPerScanline
	bl m6809RestoreAndRunXCycles
	add r0,m6809optbl,#m6809Regs
	stmia r0,{m6809f-m6809pc,m6809sp}		;@ Save M6809 state
;@--------------------------------------
	ldr m6502ptr,=m6502Base
	ldr r0,m6502CyclesPerScanline
	bl m6502RestoreAndRunXCycles
	add r0,m6502ptr,#m6502Regs
	stmia r0,{m6502nz-m6502pc}				;@ Save M6502 state
;@--------------------------------------
	ldr reptr,=reVideo_0
	bl doScanline
	cmp r0,#0
	bne reStepLoop
;@----------------------------------------------------------------------------
	ldr r1,frameTotal
	add r1,r1,#1
	str r1,frameTotal

	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
bneHack:		;@ BNE -4 (0xD0 0xFC), gameplay speed hack.
;@----------------------------------------------------------------------------
	ldrsb r0,[m6502pc],#1
	tst m6502nz,#0xff
	beq skipBne
	subne cycles,cycles,#1*CYCLE
	addne m6502pc,m6502pc,r0
	cmp r0,#-4
	andeq cycles,cycles,#CYC_MASK
skipBne:
	fetch 2
;@----------------------------------------------------------------------------
cpuInit:
	ldr r0,=m6502Base
	b m6502Init
;@----------------------------------------------------------------------------
cpuReset:		;@ Called by loadCart/resetGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

;@---Speed - 1.5MHz / 60Hz / 272 lines		;Renegade M6502.
	ldr r0,=CYCLE_PSL
	str r0,m6502CyclesPerScanline
;@--------------------------------------
	ldr m6502ptr,=m6502Base

	adr r4,cpuMapData
	bl mapM6502Memory

	mov r0,m6502ptr
	bl m6502Reset

//	adr r0,bneHack
//	str r0,[m6502ptr,#0xD0*4]
	

;@---Speed - 1.5MHz / 60Hz / 272 lines		;Renegade M6809. 6MHz/4?
	ldr r0,=CYCLE_PSL
	str r0,m6809CyclesPerScanline
;@--------------------------------------
	ldr m6809optbl,=m6809OpTable

	adr r4,cpuMapData+8
	bl map6809Memory

	mov r0,m6809optbl
	bl m6809Reset

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
cpuMapData:
;@	.byte 0x07,0x06,0x05,0x04,0xFD,0xF8,0xFE,0xFF			;@ Double Dribble CPU0
;@	.byte 0x0B,0x0A,0x09,0x08,0xFB,0xFB,0xF9,0xF8			;@ Double Dribble CPU1
;@	.byte 0x0F,0x0E,0x0D,0x0C,0xFB,0xFB,0xFB,0xFA			;@ Double Dribble CPU2
;@	.byte 0x05,0x04,0x03,0x02,0x01,0x00,0xFE,0xFF			;@ Finalizer
;@	.byte 0xFF,0xFE,0x05,0x04,0x03,0x02,0x01,0x00			;@ Green Beret
;@	.byte 0x05,0x04,0x03,0x02,0x01,0x00,0xFE,0xFF			;@ Iron Horse
;@	.byte 0x09,0x08,0x03,0x02,0x01,0x00,0xFE,0xFF			;@ Jackal CPU0
;@	.byte 0x0D,0x0C,0x0B,0x0A,0xF8,0xFD,0xFA,0xFB			;@ Jackal CPU1
;@	.byte 0x03,0x02,0x01,0x00,0xF9,0xF9,0xFF,0xFE			;@ Jail Break
;@	.byte 0xFF,0xFE,0x05,0x04,0x03,0x02,0x01,0x00			;@ Punch-Out!! Z80
;@	.byte 0x06,0xFB,0xFB,0xF0,0xFB,0xFC,0xFB,0xFD			;@ Punch-Out!! M6502
	.byte 0x07,0x06,0x05,0x04,0x01,0x00,0xFF,0xF8			;@ Renegade M6502
	.byte 0x0B,0x0A,0x09,0x08,0xF0,0xF0,0xF9,0xF9			;@ Renegade M6809
;@----------------------------------------------------------------------------
mapM6502Memory:
	stmfd sp!,{lr}
	mov r5,#0x80
m6502DataLoop:
	mov r0,r5
	ldrb r1,[r4],#1
	bl m6502Mapper
	movs r5,r5,lsr#1
	bne m6502DataLoop
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
map6809Memory:
	stmfd sp!,{lr}
	mov r5,#0x80
m6809DataLoop:
	mov r0,r5
	ldrb r1,[r4],#1
	bl m6809Mapper
	movs r5,r5,lsr#1
	bne m6809DataLoop
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
#ifdef NDS
	.section .dtcm, "ax", %progbits			;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits		;@ For the GBA
#else
	.section .text
#endif
;@----------------------------------------------------------------------------
m6502Base:
	.space m6502Size
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
