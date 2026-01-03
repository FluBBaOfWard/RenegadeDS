#include <nds.h>

#include "Renegade.h"
#include "Cart.h"
#include "Gfx.h"
#include "mcu.h"
#include "cpu.h"
#include "RenegadeVideo/RenegadeVideo.h"
#include "ARM6502/M6502.h"
//#include "ARM6809/ARM6809.h"


int packState(void *statePtr) {
	int size = 0;
	size += renegadeSaveState(statePtr+size, &reVideo_0);
	size += mcuSaveState(statePtr+size);
	size += m6502SaveState(statePtr+size, &m6502Base);
//	size += m6809SaveState(statePtr+size, &m6809CPU0);
	return size;
}

void unpackState(const void *statePtr) {
	int size = 0;
	size += renegadeLoadState(&reVideo_0, statePtr+size);
	size += mcuLoadState(statePtr+size);
	size += m6502LoadState(&m6502Base, statePtr+size);
//	size += m6809LoadState(&m6809CPU0, statePtr+size);
}

int getStateSize() {
	int size = 0;
	size += renegadeGetStateSize();
	size += mcuGetStateSize();
	size += m6502GetStateSize();
//	size += m6809GetStateSize();
	return size;
}

static const ArcadeRom renegadeRoms[31] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code + bank switched ROM
	{"na-5.ic52",   0x8000, 0xde7e7df4},
	{"nb-5.ic51",   0x8000, 0xba683ddf},
	{ROM_REGION,   0x10000, (int)&soundCpu},
	{"n0-5.ic13",   0x8000, 0x3587de3b},
	//ROM_REGION( 0x0800, "mcu:mcu", 0 ) // MC68705P5
//	{"nz-5.ic97",   0x0800, 0x32e47560},
	{ROM_REGION,   0x08000, (int)&vromBase0}, // Chars
	{"nc-5.bin",    0x8000, 0x9adfaa5d},
	{ROM_REGION,   0x30000, (int)&vromBase1}, // Tiles
	{"n1-5.ic1",    0x8000, 0x4a9f47f3},
	{"n2-5.ic14",   0x8000, 0x8d2e7982},
	{"n6-5.ic28",   0x8000, 0xd62a0aa8},
	{"n7-5.ic27",   0x8000, 0x7ca5a532},
	{"n8-5.ic26",   0x8000, 0x0dba31d3},
	{"n9-5.ic25",   0x8000, 0x5b621b6a},
	{ROM_REGION,   0x60000, (int)&vromBase2}, // Sprites
	{"nh-5.bin",    0x8000, 0xdcd7857c},
	{"nn-5.bin",    0x8000, 0x1bf15787},
	{"ni-5.bin",    0x8000, 0x6f597ed2},
	{"no-5.bin",    0x8000, 0x147dd23b},
	{"nd-5.bin",    0x8000, 0x2de1717c},
	{"nj-5.bin",    0x8000, 0x0f96a18e},
	{"ne-5.bin",    0x8000, 0x924c7388},
	{"nk-5.bin",    0x8000, 0x69499a94},
	{"nf-5.bin",    0x8000, 0x0efc8d45},
	{"nl-5.bin",    0x8000, 0x14778336},
	{"ng-5.bin",    0x8000, 0xa8ee3720},
	{"nm-5.bin",    0x8000, 0xc100258e},
	{ROM_REGION,   0x18000, (int)&adpcmBase},
	{"n3-5.ic33",   0x8000, 0x78fd6190},
	{"n4-5.ic32",   0x8000, 0x6557564c},
	{"n5-5.ic31",   0x8000, 0x7ee43a3c},
};

static const ArcadeRom renegadebRoms[31] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code + bank switched ROM
	{"na-5.ic52",   0x8000, 0xde7e7df4},
	{"40.ic51",     0x8000, 0x3dbaac11},
	{ROM_REGION,   0x10000, (int)&soundCpu},
	{"n0-5.ic13",   0x8000, 0x3587de3b},
	{ROM_REGION,   0x08000, (int)&vromBase0}, // Chars
	{"nc-5.bin",    0x8000, 0x9adfaa5d},
	{ROM_REGION,   0x30000, (int)&vromBase1}, // Tiles
	{"n1-5.ic1",    0x8000, 0x4a9f47f3},
	{"n2-5.ic14",   0x8000, 0x8d2e7982},
	{"n6-5.ic28",   0x8000, 0xd62a0aa8},
	{"n7-5.ic27",   0x8000, 0x7ca5a532},
	{"n8-5.ic26",   0x8000, 0x0dba31d3},
	{"n9-5.ic25",   0x8000, 0x5b621b6a},
	{ROM_REGION,   0x60000, (int)&vromBase2}, // Sprites
	{"nh-5.bin",    0x8000, 0xdcd7857c},
	{"nn-5.bin",    0x8000, 0x1bf15787},
	{"ni-5.bin",    0x8000, 0x6f597ed2},
	{"no-5.bin",    0x8000, 0x147dd23b},
	{"nd-5.bin",    0x8000, 0x2de1717c},
	{"nj-5.bin",    0x8000, 0x0f96a18e},
	{"ne-5.bin",    0x8000, 0x924c7388},
	{"nk-5.bin",    0x8000, 0x69499a94},
	{"nf-5.bin",    0x8000, 0x0efc8d45},
	{"nl-5.bin",    0x8000, 0x14778336},
	{"ng-5.bin",    0x8000, 0xa8ee3720},
	{"nm-5.bin",    0x8000, 0xc100258e},
	{ROM_REGION,   0x18000, (int)&adpcmBase},
	{"n3-5.ic33",   0x8000, 0x78fd6190},
	{"n4-5.ic32",   0x8000, 0x6557564c},
	{"n5-5.ic31",   0x8000, 0x7ee43a3c},
};

static const ArcadeRom kuniokunRoms[31] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code + bank switched ROM
	{"ta18-11.bin", 0x8000, 0xf240f5cd},
	{"nb-01.bin",   0x8000, 0x93fcfdf5},
	{ROM_REGION,   0x10000, (int)&soundCpu},
	{"n0-5.bin",    0x8000, 0x3587de3b},
	//ROM_REGION(   0x0800, "mcu:mcu", 0 ) // MC68705P3
//	{"nz-0.bin",    0x0800, 0x98a39880},
	{ROM_REGION,   0x08000, (int)&vromBase0}, // Chars
	{"ta18-25.bin", 0x8000, 0x9bd2bea3},
	{ROM_REGION,   0x30000, (int)&vromBase1}, // Tiles
	{"ta18-01.bin", 0x8000, 0xdaf15024},
	{"ta18-02.bin", 0x8000, 0x994c0021},
	{"ta18-06.bin", 0x8000, 0x1f59a248},
	{"n7-5.bin",    0x8000, 0x7ca5a532},
	{"ta18-04.bin", 0x8000, 0x55b9e8aa},
	{"ta18-03.bin", 0x8000, 0x0475c99a},
	{ROM_REGION,   0x60000, (int)&vromBase2}, // Sprites
	{"ta18-20.bin", 0x8000, 0xc7d54139},
	{"ta18-14.bin", 0x8000, 0xaf656017},
	{"ta18-19.bin", 0x8000, 0xc8795fd7},
	{"ta18-13.bin", 0x8000, 0xb6b14d46},
	{"ta18-24.bin", 0x8000, 0x84677d45},
	{"ta18-18.bin", 0x8000, 0x1c770853},
	{"ta18-23.bin", 0x8000, 0x3fd19cf7},
	{"ta18-17.bin", 0x8000, 0x74c64c6e},
	{"ta18-22.bin", 0x8000, 0xdf3a2ff5},
	{"ta18-16.bin", 0x8000, 0x7244bad0},
	{"ta18-21.bin", 0x8000, 0xc95e009b},
	{"ta18-15.bin", 0x8000, 0xa5d61d01},
	{ROM_REGION,   0x18000, (int)&adpcmBase},
	{"ta18-09.bin", 0x8000, 0x07ed4705},
	{"ta18-08.bin", 0x8000, 0xc9312613},
	{"ta18-07.bin", 0x8000, 0x02e3f3ed},
};

static const ArcadeRom kuniokunbRoms[31] = {
	{ROM_REGION,   0x10000, (int)&mainCpu}, // 64k for code + bank switched ROM
	{"ta18-11.bin", 0x8000, 0xf240f5cd},
	{"ta18-10.bin", 0x8000, 0xa90cf44a},
	{ROM_REGION,   0x10000, (int)&soundCpu},
	{"n0-5.bin",    0x8000, 0x3587de3b},
	{ROM_REGION,   0x08000, (int)&vromBase0}, // Chars
	{"ta18-25.bin", 0x8000, 0x9bd2bea3},
	{ROM_REGION,   0x30000, (int)&vromBase1}, // Tiles
	{"ta18-01.bin", 0x8000, 0xdaf15024},
	{"ta18-02.bin", 0x8000, 0x994c0021},
	{"ta18-06.bin", 0x8000, 0x1f59a248},
	{"n7-5.bin",    0x8000, 0x7ca5a532},
	{"ta18-04.bin", 0x8000, 0x55b9e8aa},
	{"ta18-03.bin", 0x8000, 0x0475c99a},
	{ROM_REGION,   0x60000, (int)&vromBase2}, // Sprites
	{"ta18-20.bin", 0x8000, 0xc7d54139},
	{"ta18-14.bin", 0x8000, 0xaf656017},
	{"ta18-19.bin", 0x8000, 0xc8795fd7},
	{"ta18-13.bin", 0x8000, 0xb6b14d46},
	{"ta18-24.bin", 0x8000, 0x84677d45},
	{"ta18-18.bin", 0x8000, 0x1c770853},
	{"ta18-23.bin", 0x8000, 0x3fd19cf7},
	{"ta18-17.bin", 0x8000, 0x74c64c6e},
	{"ta18-22.bin", 0x8000, 0xdf3a2ff5},
	{"ta18-16.bin", 0x8000, 0x7244bad0},
	{"ta18-21.bin", 0x8000, 0xc95e009b},
	{"ta18-15.bin", 0x8000, 0xa5d61d01},
	{ROM_REGION,   0x18000, (int)&adpcmBase},
	{"ta18-09.bin", 0x8000, 0x07ed4705},
	{"ta18-08.bin", 0x8000, 0xc9312613},
	{"ta18-07.bin", 0x8000, 0x02e3f3ed},
};

const ArcadeGame renegadeGames[GAME_COUNT] = {
	AC_GAME("renegade",  "Renegade (US)", renegadeRoms)
	AC_GAME("renegadeb", "Renegade (US bootleg)", renegadebRoms)
	AC_GAME("kuniokun",  "Nekketsu Kouha Kunio-kun (Japan)", kuniokunRoms)
	AC_GAME("kuniokunb", "Nekketsu Kouha Kunio-kun (Japan bootleg)", kuniokunbRoms)
};
