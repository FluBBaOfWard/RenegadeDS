#include <nds.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Main.h"
#include "FileHandling.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "ARM6502/Version.h"
#include "ARM6809/Version.h"
#include "RenegadeVideo/Version.h"

#define EMUVERSION "V0.1.0 2021-09-12"

const fptr fnMain[] = {nullUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI, subUI};

const fptr fnList0[] = {uiDummy};
const fptr fnList1[] = {ui8, loadState, saveState, saveSettings, resetGame};
const fptr fnList2[] = {ui4, ui5, ui6, ui7};
const fptr fnList3[] = {uiDummy};
const fptr fnList4[] = {autoBSet, autoASet, controllerSet, swapABSet};
const fptr fnList5[] = {scalingSet, flickSet, gammaSet, fgrLayerSet, bgrLayerSet, sprLayerSet};
const fptr fnList6[] = {speedSet, autoStateSet, autoSettingsSet, autoNVRAMSet, autoPauseGameSet, powerSaveSet, screenSwapSet, debugTextSet, sleepSet};
const fptr fnList7[] = {coinASet, coinBSet, difficultSet, livesSet, bonusSet, cabinetSet, flipSet};
const fptr fnList8[] = {quickSelectGame, quickSelectGame, quickSelectGame, quickSelectGame};
const fptr fnList9[] = {uiDummy};
const fptr *const fnListX[] = {fnList0, fnList1, fnList2, fnList3, fnList4, fnList5, fnList6, fnList7, fnList8, fnList9};
const u8 menuXitems[] = {ARRSIZE(fnList0), ARRSIZE(fnList1), ARRSIZE(fnList2), ARRSIZE(fnList3), ARRSIZE(fnList4), ARRSIZE(fnList5), ARRSIZE(fnList6), ARRSIZE(fnList7), ARRSIZE(fnList8), ARRSIZE(fnList9)};
const fptr drawuiX[] = {uiNullNormal, uiFile, uiOptions, uiAbout, uiController, uiDisplay, uiSettings, uiDipswitches, uiLoadGame, uiDummy};
const u8 menuXback[] = {0,0,0,0,2,2,2,2,1,8};

u8 g_gammaValue = 0;

char *const autoTxt[] = {"Off","On","With R"};
char *const speedTxt[] = {"Normal","200%","Max","50%"};
char *const sleepTxt[] = {"5min","10min","30min","Off"};
char *const brighTxt[] = {"I","II","III","IIII","IIIII"};
char *const ctrlTxt[] = {"1P","2P"};
char *const dispTxt[] = {"Unscaled","Scaled"};
char *const flickTxt[] = {"No Flicker","Flicker"};
char *const diffTxt[] = {"Easy","Normal","Hard","Very Hard"};
char *const coinTxt[] = { "1 Coin - 1 Credit","1 Coin - 2 Credits","1 Coin - 3 Credits","2 Coins - 1 Credit"};
char *const livesTxt[] = {"1","2"};
char *const bonusTxt[] = {"30K","None"};
char *const cabTxt[] = {"Cocktail","Upright"};


void setupGUI() {
	emuSettings = AUTOPAUSE_EMULATION;
	keysSetRepeat(25, 4);	// Delay, repeat.
	openMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
}

/// This is called going from ui to emu.
void exitGUI() {
}

void quickSelectGame(void) {
	int game = selected;
	while (loadGame(game)) {
		setSelectedMenu(9);
		if (!browseForFileType(FILEEXTENSIONS)) {
			backOutOfMenu();
			return;
		}
	}
	closeMenu();
}

void uiNullNormal() {
	uiNullDefault();
}

void uiFile() {
	setupMenu();
	drawMenuItem("Load Game");
	drawMenuItem("Load State");
	drawMenuItem("Save State");
	drawMenuItem("Save Settings");
	drawMenuItem("Reset Game");
	if (enableExit) {
		drawMenuItem("Quit Emulator");
	}
}

void uiOptions() {
	setupMenu();
	drawMenuItem("Controller");
	drawMenuItem("Display");
	drawMenuItem("Settings");
	drawMenuItem("DipSwitches");
}

void uiAbout() {
	cls(1);
	drawTabs();
	drawText(" Select:      Insert coin",4,0);
	drawText(" Start:       Start",5,0);
	drawText(" DPad:        Move around",6,0);
	drawText(" <-<- / ->->: Start running",7,0);
	drawText(" Y:           Left atack",8,0);
	drawText(" X:           Jump",9,0);
	drawText(" A:           Right attack",10,0);
	drawText(" B:           -",11,0);

	drawText(" RenegadeDS   " EMUVERSION, 21, 0);
	drawText(" ARM6502      " ARM6502VERSION, 22, 0);
	drawText(" ARM6809      " ARM6809VERSION, 23, 0);
}

void uiController() {
	setupSubMenu(" Controller Settings");
	drawSubItem("B Autofire: ", autoTxt[autoB]);
	drawSubItem("A Autofire: ", autoTxt[autoA]);
	drawSubItem("Controller: ", ctrlTxt[(joyCfg>>29)&1]);
	drawSubItem("Swap A-B:   ", autoTxt[(joyCfg>>10)&1]);
}

void uiDisplay() {
	setupSubMenu(" Display Settings");
	drawSubItem("Display: ", dispTxt[g_scaling]);
	drawSubItem("Scaling: ", flickTxt[g_flicker]);
	drawSubItem("Gamma: ", brighTxt[g_gammaValue]);
	drawSubItem("Disable Foreground: ", autoTxt[g_gfxMask&1]);
	drawSubItem("Disable Background: ", autoTxt[(g_gfxMask>>1)&1]);
	drawSubItem("Disable Sprites: ", autoTxt[(g_gfxMask>>4)&1]);
}

void uiSettings() {
	setupSubMenu(" Settings");
	drawSubItem("Speed: ", speedTxt[(emuSettings>>6)&3]);
	drawSubItem("Autoload State: ", autoTxt[(emuSettings>>2)&1]);
	drawSubItem("Autosave Settings: ", autoTxt[(emuSettings>>9)&1]);
	drawSubItem("Autosave NVRAM: ", autoTxt[(emuSettings>>10)&1]);
	drawSubItem("Autopause Game: ", autoTxt[emuSettings&1]);
	drawSubItem("Powersave 2nd Screen: ",autoTxt[(emuSettings>>1)&1]);
	drawSubItem("Emulator on Bottom: ", autoTxt[(emuSettings>>8)&1]);
	drawSubItem("Debug Output: ", autoTxt[g_debugSet&1]);
	drawSubItem("Autosleep: ", sleepTxt[(emuSettings>>4)&3]);
}

void uiDipswitches() {
	setupSubMenu(" Dipswitch Settings");
	drawSubItem("Coin A: ", coinTxt[g_dipSwitch1 & 0x3]);
	drawSubItem("Coin B: ", coinTxt[(g_dipSwitch1>>2) & 0x3]);
	drawSubItem("Difficulty: ", diffTxt[g_dipSwitch2 & 3]);
	drawSubItem("Lives: ", livesTxt[(g_dipSwitch1>>4) & 1]);
	drawSubItem("Bonus: ", bonusTxt[(g_dipSwitch1>>5) & 1]);
	drawSubItem("Cabinet: ", cabTxt[(g_dipSwitch1>>6) & 1]);
	drawSubItem("Flip Screen: ", autoTxt[(g_dipSwitch1>>7) & 1]);
}

void uiLoadGame() {
	setupSubMenu(" Load game");
	drawMenuItem(" Renegade (US)");
	drawMenuItem(" Renegade (US bootleg)");
	drawMenuItem(" Nekketsu Kouha Kunio-Kun (Japan)");
	drawMenuItem(" Nekketsu Kouha Kunio-Kun (Japan bootleg)");
}

void nullUINormal(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void nullUIDebug(int key) {
	if (key & KEY_TOUCH) {
		openMenu();
	}
}

void resetGame() {
	loadCart(romNum,0);
}


//---------------------------------------------------------------------------------
/// Switch between Player 1 & Player 2 controls
void controllerSet() {				// See io.s: refreshEMUjoypads
	joyCfg ^= 0x20000000;
}

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}

/// Turn on/off scaling
void scalingSet(){
	g_scaling ^= 0x01;
	refreshGfx();
}

/// Change gamma (brightness)
void gammaSet() {
	g_gammaValue++;
	if (g_gammaValue > 4) g_gammaValue=0;
	paletteInit(g_gammaValue);
	paletteTxAll();					// Make new palette visible
	setupMenuPalette();
}

/// Turn on/off rendering of foreground
void fgrLayerSet(){
	g_gfxMask ^= 0x01;
}
/// Turn on/off rendering of background
void bgrLayerSet(){
	g_gfxMask ^= 0x02;
}
/// Turn on/off rendering of sprites
void sprLayerSet(){
	g_gfxMask ^= 0x10;
}


/// Number of coins for credits
void coinASet() {
	int i = (g_dipSwitch1+1) & 0x3;
	g_dipSwitch1 = (g_dipSwitch1 & ~0x3) | i;
}
/// Number of coins for credits
void coinBSet() {
	int i = (g_dipSwitch1+4) & 0xC;
	g_dipSwitch1 = (g_dipSwitch1 & ~0xC) | i;
}
/// Game difficulty
void difficultSet() {
	int i = (g_dipSwitch2+0x01) & 0x03;
	g_dipSwitch2 = (g_dipSwitch2 & ~0x03) | i;
}
void livesSet() {
	g_dipSwitch1 ^= 0x10;
}
/// At which score you get bonus lifes
void bonusSet() {
	g_dipSwitch1 ^= 0x20;
}
/// Cocktail/upright
void cabinetSet() {
	g_dipSwitch1 ^= 0x40;
}
/// Flip screen
void flipSet() {
	g_dipSwitch1 ^= 0x80;
}
