#ifdef __arm__

#include "Shared/nds_asm.h"
#include "Shared/EmuSettings.h"
#include "RenegadeVideo/RenegadeVideo.i"

	.global gfxInit
	.global gfxReset
	.global paletteInit
	.global paletteTxAll
	.global refreshGfx
	.global endFrame
	.global gfxState
//	.global oamBufferReady
	.global gFlicker
	.global gTwitch
	.global gScaling
	.global gGfxMask
	.global vblIrqHandler
	.global yStart
	.global EMUPALBUFF

	.global reVideo_0



	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
gfxInit:					;@ Called from machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=OAM_BUFFER1			;@ No stray sprites please
	mov r1,#0x200+SCREEN_HEIGHT
	mov r2,#0x100
	bl memset_
	adr r0,scaleParms
	bl setupSpriteScaling

	ldr r0,=gGammaValue
	ldrb r0,[r0]
	bl paletteInit				;@ Do palette mapping

	bl reVideoInit

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
scaleParms:					;@  NH     FH     NV     FV
	.long OAM_BUFFER1,0x0000,0x0100,0xff01,0x0120,0xfeb6
;@----------------------------------------------------------------------------
gfxReset:					;@ Called with CPU reset, r0 = selectedGame
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=gfxState
	mov r1,#5					;@ 5*4
	bl memclr_					;@ Clear GFX regs

	mov r1,#REG_BASE
	ldr r0,=0x00FF				;@ Start-end
	strh r0,[r1,#REG_WIN0H]
	mov r0,#0x00C0				;@ Start-end
	strh r0,[r1,#REG_WIN0V]
	mov r0,#0x0000
	strh r0,[r1,#REG_WINOUT]

	ldr r0,=m6502SetNMIPin		;@ Frame irq
	ldr r1,=m6502SetIRQPin		;@ Periodic irq
	ldr r2,=soundCpuSetIRQ		;@ Latch irq
	ldr r3,=EMU_RAM
	ldr reptr,=reVideo_0
	bl reVideoReset

	ldr r0,=BG_GFX+0x4000		;@ r0 = GBA/NDS BG tileset
	str r0,[reptr,#chrGfxDest]
	ldr r0,=BG_GFX+0x8000		;@ r0 = GBA/NDS BG tileset
	str r0,[reptr,#bgrGfxDest]

	ldr r0,=vromBase0
	ldr r0,[r0]
	str r0,[reptr,#chrRomBase]
	ldr r0,=vromBase1
	ldr r0,[r0]
	str r0,[reptr,#bgrRomBase]
	ldr r0,=vromBase2
	ldr r0,[r0]
	str r0,[reptr,#spriteRomBase]

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
paletteInit:		;@ r0-r3 modified.
	.type paletteInit STT_FUNC
;@ Called by ui.c:  void paletteInit(u8 gammaVal);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,lr}
	mov r1,r0					;@ Gamma value = 0 -> 4
	mov r7,#0xF0
	ldr r6,=MAPPED_RGB
	mov r4,#8192				;@ Renegade 4096 colors
	sub r4,r4,#2
noMap:							;@ Map 0000bbbbggggrrrr  ->  0bbbbbgggggrrrrr
	and r0,r7,r4,lsr#5			;@ Blue ready
	bl gPrefix
	mov r5,r0

	and r0,r7,r4,lsr#1			;@ Green ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	and r0,r7,r4,lsl#3			;@ Red ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	strh r5,[r6,r4]
	subs r4,r4,#2
	bpl noMap

	ldmfd sp!,{r4-r7,lr}
	bx lr

;@----------------------------------------------------------------------------
gPrefix:
	orr r0,r0,r0,lsr#4
;@----------------------------------------------------------------------------
gammaConvert:	;@ Takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;@----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr
;@----------------------------------------------------------------------------
paletteTxAll:				;@ Called from ui.c
	.type paletteTxAll STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r9,lr}
	ldr r4,=0x1FFE			;@ Mask
	ldr r2,=EMU_RAM+0x3000
	add r3,r2,#0x100
	ldr r7,=MAPPED_RGB
	ldr r5,=EMUPALBUFF

	mov r6,#0				;@ Source, FG
	mov r8,#128*2			;@ Destination
	mov r9,#8*4				;@ Len
	bl PalCpy

	mov r6,#192*2			;@ Source, BG
	mov r8,#0				;@ Destination
	mov r9,#8*8				;@ Len
	bl PalCpy

	mov r6,#128*2			;@ Source, Spr
	mov r8,#256*2			;@ Destination
	mov r9,#8*4				;@ Len
	bl PalCpy

	ldmfd sp!,{r4-r9,lr}
	bx lr

;@----------------------------------------------------------------------------
PalCpy:
	ldrb r0,[r2,r6,lsr#1]	;@ Source GR
	ldrb r1,[r3,r6,lsr#1]	;@ Source B
	orr r0,r0,r1,lsl#8
	and r0,r4,r0,lsl#1
	ldrh r0,[r7,r0]			;@ Palette LUT
	strh r0,[r5,r8]			;@ Destination
	add r6,r6,#2
	add r8,r8,#2
	tst r8,#0x10
	addne r8,r8,#0x10
	subs r9,r9,#1
	bne PalCpy
	bx lr

;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	bl calculateFPS

	ldrb r0,gScaling
	cmp r0,#UNSCALED
	moveq r6,#0
	ldrne r6,=0x80000000 + ((GAME_HEIGHT-SCREEN_HEIGHT)*0x10000) / (SCREEN_HEIGHT-1)		;@ NDS 0x2B10 (was 0x2AAB)
	ldrbeq r8,yStart
	movne r8,#0
	add r8,r8,#0x08
	mov r7,r8,lsl#16
	orr r7,r7,#(GAME_WIDTH-SCREEN_WIDTH)/2

	ldr r0,gFlicker
	eors r0,r0,r0,lsl#31
	str r0,gFlicker
	addpl r6,r6,r6,lsl#16

	ldr r11,=scrollBuff
	mov r4,r11

	ldr r5,=scrollTemp
	mov r12,#SCREEN_HEIGHT
scrolLoop2:
	ldr r1,[r5,r8,lsl#2]
	add r0,r7,#0
	add r1,r1,r7
	stmia r4!,{r0-r1}
	adds r6,r6,r6,lsl#16
	addcs r7,r7,#0x10000
	adc r8,r8,#1
	subs r12,r12,#1
	bne scrolLoop2


	mov r8,#REG_BASE
	strh r8,[r8,#REG_DMA0CNT_H]	;@ DMA0 stop

	add r0,r8,#REG_DMA0SAD
	mov r1,r11					;@ Setup DMA buffer for scrolling:
	ldmia r1!,{r3-r4}			;@ Read
	add r2,r8,#REG_BG0HOFS		;@ DMA0 always goes here
	stmia r2,{r3-r4}			;@ Set 1st value manually, HBL is AFTER 1st line
	ldr r3,=0x96600002			;@ noIRQ hblank 32bit repeat incsrc inc_reloaddst, 2 word
	stmia r0,{r1-r3}			;@ DMA0 go

	add r1,r8,#REG_DMA3SAD

	ldr r2,dmaOamBuffer			;@ DMA3 src, OAM transfer:
	mov r3,#OAM					;@ DMA3 dst
	mov r4,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r4,r4,#96*2				;@ 96 sprites * 2 longwords
	stmia r1,{r2-r4}			;@ DMA3 go

	ldr r2,=EMUPALBUFF			;@ DMA3 src, Palette transfer:
	mov r3,#BG_PALETTE			;@ DMA3 dst
	mov r4,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r4,r4,#0x100			;@ 256 words (1024 bytes)
	stmia r1,{r2-r4}			;@ DMA3 go

	mov r0,#0x0013
	ldrb r1,gGfxMask
	bic r0,r0,r1
	strh r0,[r8,#REG_WININ]

	blx scanKeys
	ldmfd sp!,{r4-r11,pc}


;@----------------------------------------------------------------------------
gFlicker:		.byte 1
				.space 2
gTwitch:		.byte 0

gScaling:		.byte 1
gGfxMask:		.byte 0
yStart:			.byte 0
				.byte 0
;@----------------------------------------------------------------------------
refreshGfx:					;@ Called from C when changing scaling.
	.type refreshGfx STT_FUNC
;@----------------------------------------------------------------------------
	adr reptr,reVideo_0
;@----------------------------------------------------------------------------
endFrame:					;@ Called just before screen end (~line 224)	(r0-r2 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}

	ldr r0,=scrollTemp
	bl copyScrollValues

endFrameRE:
	ldr r0,=BG_GFX
	bl convertChrTileMap
	ldr r0,=BG_GFX+0x1000
	bl convertBgrTileMap
	ldr r0,tmpOamBuffer
	bl convertSpritesRenegade
	bl paletteTxAll
;@--------------------------
	ldr r0,dmaOamBuffer
	ldr r1,tmpOamBuffer
	str r0,tmpOamBuffer
	str r1,dmaOamBuffer

	mov r0,#1
	str r0,oamBufferReady

	ldr r0,=windowTop			;@ Load wTop, store in wTop+4.......load wTop+8, store in wTop+12
	ldmia r0,{r1-r3}			;@ Load with increment after
	stmib r0,{r1-r3}			;@ Store with increment before

	ldmfd sp!,{r3,lr}
	bx lr

;@----------------------------------------------------------------------------

tmpOamBuffer:		.long OAM_BUFFER1
dmaOamBuffer:		.long OAM_BUFFER2

oamBufferReady:		.long 0
;@----------------------------------------------------------------------------
reVideo_0:
	.space renegadeVideoSize

gfxState:
adjustBlend:
	.long 0
windowTop:
	.long 0
wTop:
	.long 0,0,0		;@ windowtop  (this label too)   L/R scrolling in unscaled mode

	.byte 0
	.byte 0
	.byte 0,0

	.section .bss
scrollTemp:
	.space 0x400*2
OAM_BUFFER1:
	.space 0x400
OAM_BUFFER2:
	.space 0x400
DMA0BUFF:
	.space 0x200
scrollBuff:
	.space 0x300*4				;@ Scrollbuffer. SCREEN_HEIGHT * 3 * 4
MAPPED_RGB:
	.space 0x2000				;@ 12bit * 2
EMUPALBUFF:
	.space 0x400

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
