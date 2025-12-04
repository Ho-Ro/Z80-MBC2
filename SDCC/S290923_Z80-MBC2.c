// ***********************************************************************************************
//
// S290923_Z80-MBC2.c
//
// S290923 - SDCC I/O custom functions for the Z80-MBC2 - HW ref: A040618//
//
// REQUIRED: IOS S220718-R290823 (and following revisions unless stated otherwise)
//
// REQUIRED: S190818-R011023_crt0.rel
//
//
//
// WARNING!: Pay attention on the setting to enable/disable the IRQ support:
//
//           To compile with IRQ support disabled:     sdcc -c -mz80 S290923_Z80-MBC2.c
//
//           To compile with the IRQ support enabled:  sdcc -c -mz80 -DZ80MBC2IRQ S290923_Z80-MBC2.c
//
//
//
// HOW TO USE:
// Put the generated file -S290923_Z80-MBC2.rel into the working directory
// (the directory where your current source files are stored) together
// with the file S190818-R011023_crt0.rel (compiled from S190818-R011023_crt0.s)
//
//
// Tested with SDCC 4.0.2
//
//
// NOTE:
// In SDCC 3.7.0 the prototype for getchar() changed from char getchar(void) to int getchar(void),
// and the prototype for putchar() changed from void putchar(char) to int putchar(int).
//
// ***********************************************************************************************
//
// Z80-MBC2 - IOS S220718-R290823
//
// IOS Ports definitions:
//
// EXECUTE_READ_OPCODE      0x00  (read)            // IOS Execute Opcode read/write port
// SERIALPORT_RX            0x01  (read)            // IOS Serial Rx read only port
// EXECUTE_WRITE_OPCODE     0x00  (write)           // IOS Execute Opcode read/write port
// STORE_OPCODE             0x01  (write)           // IOS Store Opcode write only port
//
//
// Currently defined IOS Opcodes for I/O write operations:
//
//   Opcode     Name            Exchanged bytes
// -------------------------------------------------
// Opcode 0x00  USER LED        1
// Opcode 0x01  SERIAL TX       1
// Opcode 0x03  GPIOA Write     1
// Opcode 0x04  GPIOB Write     1
// Opcode 0x05  IODIRA Write    1
// Opcode 0x06  IODIRB Write    1
// Opcode 0x07  GPPUA Write     1
// Opcode 0x08  GPPUB Write     1
// Opcode 0x09  SELDISK         1
// Opcode 0x0A  SELTRACK        2
// Opcode 0x0B  SELSECT         1  
// Opcode 0x0C  WRITESECT       512
// Opcode 0x0D  SETBANK         1
// Opcode 0x0E  SETIRQ          1
// Opcode 0x0F  SETTICK         1
// Opcode 0x10  SETOPT          1
// Opcode 0x11  SETSPP          1
// Opcode 0x12  WRSPP           1
// Opcode 0xFF  No operation    1
//
//
// Currently defined IOS Opcodes for I/O read operations:
//
//   Opcode     Name            Exchanged bytes
// -------------------------------------------------
// Opcode 0x80  USER KEY        1
// Opcode 0x81  GPIOA Read      1
// Opcode 0x82  GPIOB Read      1
// Opcode 0x83  SYSFLAGS        1
// Opcode 0x84  DATETIME        7
// Opcode 0x85  ERRDISK         1
// Opcode 0x86  READSECT        512
// Opcode 0x87  SDMOUNT         1
// Opcode 0x88  ATXBUFF         1
// Opcode 0x89  SYSIRQ          1
// Opcode 0x8A  GETSPP          1
// Opcode 0xFF  No operation    1
//

#include <stdio.h>

// Z80-MBC2 IOS I/O ports definitions
__sfr __at 0x00 Exec_port;          // IOS Execute Opcode read/write port
__sfr __at 0x01 StorOpc_port;       // IOS Store Opcode write only port
__sfr __at 0x01 SerRx_port;         // IOS Serial Rx read only port

// Z80-MBC2 IOS Opcodes definitions
#define         USRLED      0x00
#define         SERIALTX    0x01
#define         GPIOAW      0x03
#define         GPIOBW      0x04
#define         IODIRAW     0x05
#define         IODIRBW     0x06
#define         GPPUAW      0x07
#define         GPPUBW      0x08
#define         SELDISK     0x09
#define         SELTRACK    0x0A
#define         SELSECT     0x0B
#define         WRITESECT   0x0C
#define         SETBANK     0x0D
#define         SETIRQ      0x0E
#define         SETTICK     0x0F
#define         SETOPT      0x10
#define         SETSPP      0x11
#define         WRSPP       0x12
#define         USRKEY      0x80
#define         GPIOAR      0x81
#define         GPIOBR      0x82
#define         SYSFLAGS    0x83
#define         DATETIME    0x84
#define         ERRDISK     0x85
#define         READSECT    0x86
#define         SDMOUNT     0x87
#define         ATXBUFF     0x88
#define         SYSIRQ      0x89 
#define         GETSPP      0x8A

#if defined(Z80MBC2IRQ)             // IRQ enabled

void IM1_IRQ_ISR(void);
unsigned long sysTick(void);
int putchar(int c);
int getchar(void);

static volatile unsigned long ticks = 0;
static char     inchar, incharRdy = 0;

void IM1_IRQ_ISR(void)
// ISR called when an IRQ is triggered. Here IRQ are disabled.
{
    static char irqStatus;
    
    StorOpc_port = SYSIRQ;
    irqStatus= Exec_port;           // Read triggered IRQ
    if (irqStatus & 0x02)
    // Systick IRQ
    {
        ticks++;
    }
    if (irqStatus & 0x01)
    // Serial Rx IRQ 
    {
        inchar = SerRx_port;        // Read from serial
        incharRdy = 1;              // Set char available flag
    }
}

unsigned long sysTick(void)
{
    static unsigned long ret;
    
    __asm
        di
    __endasm;
    
    // Must be an atomic operation (no IRQ here)
    ret = ticks;
        
    __asm
        ei
    __endasm;
        
    return ret;
}

int putchar(int c)
{
    if (c == 0x0a)
    // Is a LF
    {
        __asm
            di
        __endasm;
        
        // Must be an atomic operation (no IRQ here)
        StorOpc_port = 0x01;
        Exec_port = 0x0d;           // Print a CR before;
        
        __asm
            ei
        __endasm;
    }
        
    __asm
        di
    __endasm;

    // Must be an atomic operation (no IRQ here)
    StorOpc_port = 0x01;
    Exec_port = (char) (c);
    
    __asm
        ei
    __endasm;
    
    return c;
}

int getchar(void)
{
    static char c;
    
    while (!incharRdy);             // Wait for a char
    
    __asm
        di
    __endasm;
    
    // Must be an atomic operation (no IRQ here)
    c = inchar;                     // Read the char
    incharRdy = 0;                  // Clear char available flag
    
    __asm
        ei
    __endasm;
    
    return (int)(c);
}

#else                               // No IRQ (polling mode)

void IM1_IRQ_ISR(void);
int putchar(int c);
int getchar(void);

void IM1_IRQ_ISR(void)
// Nothing to do as IRQ are disabled.
// Here only to avoid linker errors if using the --no-std-crt0 SDCC option
// (not needed here).
{
}

int putchar(int c)
{
    if (c == 0x0a)
    // Is a LF
    {
        StorOpc_port = 0x01;
        Exec_port = 0x0d;           // Print a CR before;
    }
    StorOpc_port = 0x01;
    Exec_port = (char) (c);
    return c;
}

int getchar (void)
{
    static char sysflags;
    do
    {
        StorOpc_port = 0x83;
        sysflags = Exec_port;       // Read IOS SYSFLAGS;
    }
    while (!(sysflags & 0x04));     // Wait a char until ready
    return SerRx_port;
}

#endif
