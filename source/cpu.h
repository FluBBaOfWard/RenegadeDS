#ifndef CPU_HEADER
#define CPU_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "ARM6502/M6502.h"
#include "ARM6809/ARM6809.h"

extern u8 waitMaskIn;
extern u8 waitMaskOut;
extern M6502Core m6502Base;
extern ARM6809Core m6809CPU0;

void run(void);
void stepFrame(void);
void cpuInit(void);
void cpuReset(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CPU_HEADER
