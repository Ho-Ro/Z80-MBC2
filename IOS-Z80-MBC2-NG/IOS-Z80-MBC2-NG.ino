/* ------------------------------------------------------------------------------

S220718-R290823 - HW ref: A040618

IOS - I/O Subsystem for the  Z80-MBC2 (Z80 Multi Boot Computer version 2)
Z80, 128KB or 256KB or 512KB RAM, 4/8 or 5/10 Mhz @ Fosc = 16 or 20 MHz


Notes:

1:  This SW is ONLY for the Atmega32A used as EEPROM and I/O subsystem
    (16/20MHz external oscillator) for the Z80 CPU.

2:  Tested on Atmega32A/Atmega1284P @ Arduino IDE 1.8.19 and MightyCore v.3.0.3

3:  Embedded FW: S200718 iLoad (Intel-Hex loader)

4:  To run the stand-alone Basic and Forth interpreters the SD optional module must be
    installed with the required binary files on a microSD (FAT16 or FAT32 formatted).
    Without the SD module you can only run the iLoad (intel hex format loader).

5:  Utilities:   S111216 TASM conversion utility


---------------------------------------------------------------------------------

Credits:

SD library from: https://github.com/greiman/PetitFS (based on
PetitFS: http://elm-chan.org/fsw/ff/00index_p.html)

PetitFS licence:
/-----------------------------------------------------------------------------/
/  Petit FatFs - FAT file system module  R0.03                  (C)ChaN, 2014
/-----------------------------------------------------------------------------/
/ Petit FatFs module is a generic FAT file system module for small embedded
/ systems. This is a free software that opened for education, research and
/ commercial developments under license policy of following trems.
/
/  Copyright (C) 2014, ChaN, all right reserved.
/
/ * The Petit FatFs module is a free software and there is NO WARRANTY.
/ * No restriction on use. You can use, modify and redistribute it for
/   personal, non-profit or commercial products UNDER YOUR RESPONSIBILITY.
/ * Redistributions of source code must retain the above copyright notice.
/
/-----------------------------------------------------------------------------/

Credits:

Thanks to Christian Welzel (http://www.welzel-online.ch) for some suggestions
on Fuzix IRQ handling.

---------------------------------------------------------------------------------


CHANGELOG:


S220718           First revision.
S220718-R010918   Added "Disk Set" feature to manage multiple OS on SD (multi-booting).
                  Added support for QP/M 2.71 (with file names timestamping).
                  Added support for Atmega32A @ 20MHz (overclocked) to show the Z80 clock speed
                   accordingly (Note that 20MHz is out of Atmega32A specifications!).
S220718-R190918   Added support for CP/M 3.
                  Fixed a bug in the manual RTC setting.
S220718-R260119   Changed the default serial speed to 115200 bps.
                  Added support for xmodem protocol (extended serial Rx buffer check and
                   two new flags into the SYSFLAG Opcode for full 8 bit serial I/O control.
                  Added support for uTerm (A071218-R250119 and following revisions unless stated otherwise)
                   reset at boot time.
S220718-R280819   Added a new Disk Set for the UCSD Pascal implementation (porting by Michel Bernard).
S220718-R240620   Added support for Collapse OS (https://collapseos.org/).
S220718-R290823   Added Fuzix OS support (www.fuzix.org):
                   changed Serial Rx interrupt generation;
                   added Systick interrupt.
                   added SETIRQ Opcode to enable/disable IRQ generation (see important notes inside the comments);
                   added ATXBUFF Opcode to check the available space of serial Tx buffer;
                   added SYSIRQ Opcode to check the triggered IRQ;
                   added SETTICK Opcode to set/change the Systick time;
                  Changed the behavior of the selection 3 of the boot menu and others minor changes.
                  Added support for the SPP Adapter (A240721-R270921 and following revisions unless stated
                   otherwise) for parallel printers with 3 new Opcodes (SETSPP, WRSPP and GETSPP);
                   please note that now when the GPIO is set to operate as an SPP port all
                   the GPIO write Opcodes (GPIOA Write, GPIOB Write, IODIRA Write, IODIRB Write,
                   GPPUA Write, GPPUB Write) are ignored/disabled.
                  Added serial port speed selection inside the boot menu.
                  Added serial port Baud Recovery procedure. It can be triggered only if the serial port was
                   set at a speed not equal then the default (115200), pressing the RESET + USER keys and
                   releasing the RESET key while holding down the USER key for about 4s until both USER and
                   IOS leds blink quickly. At the next reboot the serial speed will be set at the default
                   value (115200).
                  Added support to run on an Atmega1284/Atmega1284P MCU (leaving more space for customiztions).
                  Added SETOPT Opcode to enable/disable the message "CP/M WARM BOOT" (if CP/M CBIOS support
                   this switch).
                  Now if the GPE expansion is found GPA0 and GPA2 are set with pullup enabled. This way if
                   the SPP adapter is used and a printer is connected, selected online and powered on before
                   the Z80-MBC2, possible "strange" printer behaviors are avoided. This makes the STROBE and
                   INIT lines of the parallel port not active after a power on/reset.
S220718-D260225   Ho-Ro: DEVEL for I2C 2 x SIO module SC16IS752 - auto RTS/CTS - finetuning FIFO level
S220718-D080825   SvenMB: corrected handling for ram extension
S220718-D051225   Ho-Ro: fix SIOB adressing #12 (https://github.com/Ho-Ro/Z80-MBC2/issues/12)
S220718-D261225   Ho-Ro: prepare for ATmega1284 build
S220718-D281225   Ho-Ro: add SETVECTOR opcode, enable Z80 IM0, IM1 and IM2 interrupt modes
S220718-D311225   Ho-Ro: Z80 INT trigger only if outside opcode processing
S220718-D090126   Ho-Ro: Refactor menu - tested with ATmega1284p @ 24 MHz
2.0.260111        Ho-Ro: New versioning 2.0.YYMMDD, support for IOS User context
2.0.260126        Ho-Ro: Add tinybasic to IOS flash ('T')
2.0.260205        Ho-Ro: HEX loader in IOS replaces iLoad, add WozMon to IOS flash ('W')
--------------------------------------------------------------------------------- */
// clang-format off

#if defined( __AVR_ATmega32__ )
#define HW_STRING "\r\n\nZ80-MBC2-NG - A040618 - ATmega32"
#elif defined( __AVR_ATmega1284__ )
#define HW_STRING "\r\n\nZ80-MBC2-NG - A040618 - ATmega1284"
#elif defined( __AVR_ATmega1284P__ )
#define HW_STRING "\r\n\nZ80-MBC2-NG - A040618 - ATmega1284p"
#endif

#define VERSION_STRING "2.0.260205"
#define BUILD_STRING __DATE__ " " __TIME__

// ------------------------------------------------------------------------------
//
// Hardware definitions for A040618 (Z80-MBC2) - Base system
//
// ------------------------------------------------------------------------------

#define   D0            24    // PA0 pin 40   Z80 data bus (D0-D7)
#define   D1            25    // PA1 pin 39
#define   D2            26    // PA2 pin 38
#define   D3            27    // PA3 pin 37
#define   D4            28    // PA4 pin 36
#define   D5            29    // PA5 pin 35
#define   D6            30    // PA6 pin 34
#define   D7            31    // PA7 pin 33

#define   AD0           18    // PC2 pin 24   Z80 A0
#define   WR_           19    // PC3 pin 25   Z80 WR (active low)
#define   RD_           20    // PC4 pin 26   Z80 RD (active low)
#define   MREQ_         21    // PC5 pin 27   Z80 MREQ (active low)
#define   RESET_        22    // PC6 pin 28   Z80 RESET (active low)
#define   MCU_RTS_      23    // PC7 pin 29   Used to reset uTerm (A071218-R250119 and following HW revisions)
#define   BANK3         23    // MCU_RTS_ is used as BANK3 if 512KByte RAM
#define   MCU_CTS_      10    // PD2 pin 16   * RESERVED - NOT USED *
#define   BANK2         10    // MCU_CTS_ is used as BANK2 if 256 or 512KByte RAM
#define   BANK1         11    // PD3 pin 17   RAM Memory bank address (High)
#define   BANK0         12    // PD4 pin 18   RAM Memory bank address (Low)
#define   INT_           1    // PB1 pin 2    Z80 INT (active low)
#define   RAM_CE2        2    // PB2 pin 3    RAM Chip Enable (CE2). Active High for ramCfg <2, active Low for ramCfg=2. Used only during boot
#define   WAIT_          3    // PB3 pin 4    Z80 WAIT (active low)
#define   SS_            4    // PB4 pin 5    SD SPI (active low)
#define   MOSI           5    // PB5 pin 6    SD SPI
#define   MISO           6    // PB6 pin 7    SD SPI
#define   SCK            7    // PB7 pin 8    SD SPI
#define   BUSREQ_       14    // PD6 pin 20   Z80 BUSRQ (active low)
#define   CLK           15    // PD7 pin 21   Z80 CLK
#define   SCL_PC0       16    // PC0 pin 22   IOEXP connector (I2C)
#define   SDA_PC1       17    // PC1 pin 23   IOEXP connector (I2C)
#define   LED_IOS        0    // PB0 pin 1    Led LED_IOS is ON if HIGH
#define   WAIT_RES_      0    // PB0 pin 1    Reset the Wait FF (active low)
#define   USER          13    // PD5 pin 19   Led USER and key (led USER is ON if LOW)

// ------------------------------------------------------------------------------
//
// Hardware definitions for A040618 GPE Option (Optional GPIO Expander)
//
// ------------------------------------------------------------------------------

#define   GPIOEXP_ADDR  0x20  // I2C module 7 bit address (see datasheet)
#define   IODIRA_REG    0x00  // MCP23017 internal register IODIRA  (see datasheet)
#define   IODIRB_REG    0x01  // MCP23017 internal register IODIRB  (see datasheet)
#define   GPPUA_REG     0x0C  // MCP23017 internal register GPPUA  (see datasheet)
#define   GPPUB_REG     0x0D  // MCP23017 internal register GPPUB  (see datasheet)
#define   GPIOA_REG     0x12  // MCP23017 internal register GPIOA  (see datasheet)
#define   GPIOB_REG     0x13  // MCP23017 internal register GPIOB  (see datasheet)

// ------------------------------------------------------------------------------
//
// Hardware definitions for A040618 RTC Module Option (see DS3231 datasheet)
//
// ------------------------------------------------------------------------------

#define   DS3231_RTC    0x68  // DS3231 I2C 7 bit address
#define   DS3231_SECRG  0x00  // DS3231 Seconds Register
#define   DS3231_STATRG 0x0F  // DS3231 Status Register

// ------------------------------------------------------------------------------
//
// File names and starting addresses
//
// ------------------------------------------------------------------------------

#define   BASICFN       "BASIC47.BIN"     // "ROM" Basic
#define   FORTHFN       "FORTH13.BIN"     // "ROM" Forth
#define   CPMFN         "CPM22.BIN"       // CP/M 2.2 loader
#define   QPMFN         "QPMLDR.BIN"      // QP/M 2.71 loader
#define   CPM3FN        "CPMLDR.COM"      // CP/M 3 CPMLDR.COM loader
#define   UCSDFN        "UCSDLDR.BIN"     // UCSD Pascal loader
#define   COSFN         "COS.BIN"         // Collapse OS loader
#define   FUZIXFN       "FUZIX.BIN"       // Fuzix OS loader
#define   AUTOFN        "AUTOBOOT.BIN"    // Autoboot.bin file
#define   Z80DISK       "DSxNyy.DSK"      // Generic Z80 disk name (from DS0N00.DSK to DS9N99.DSK)
#define   DS_OSNAME     "DSxNAM.DAT"      // File with the OS name for Disk Set "x" (from DS0NAM.DAT to DS9NAM.DAT)
#define   BASSTRADDR    0x0000            // Starting address for the stand-alone Basic interptreter
#define   FORSTRADDR    0x0100            // Starting address for the stand-alone Forth interptreter
#define   CPM22CBASE    0xD200            // CBASE value for CP/M 2.2
#define   CPMSTRADDR    (CPM22CBASE - 32) // Starting address for CP/M 2.2
#define   QPMSTRADDR    0x80              // Starting address for the QP/M 2.71 loader
#define   CPM3STRADDR   0x100             // Starting address for the CP/M 3 loader
#define   UCSDSTRADDR   0x0000            // Starting address for the UCSD Pascal loader
#define   COSSTRADDR    0x0000            // Starting address for the Collapse OS loader
#define   FUZSTRADDR    0x0000            // Starting address for the Fuzix OS loader
#define   AUTSTRADDR    0x0000            // Starting address for the AUTOBOOT.BIN file

// ------------------------------------------------------------------------------
//
// Atmega clock speed check
//
// ------------------------------------------------------------------------------

#if not defined F_CPU or F_CPU < 12000000L or F_CPU > 26000000L
  #error Clock frequency F_CPU undefined or invalid
#endif

// ------------------------------------------------------------------------------
//
//  Libraries
//
// ------------------------------------------------------------------------------

#include <avr/pgmspace.h>                 // Needed for PROGMEM
#include <Wire.h>                         // Needed for I2C bus
#include <EEPROM.h>                       // Needed for internal EEPROM R/W
#include "PetitFS.h"                      // Light handler for FAT16 and FAT32 filesystems on SD
#include "sc16is752.h"                    // I2C double SIO interface

// ------------------------------------------------------------------------------
//
//  Constants
//
// ------------------------------------------------------------------------------

const byte    LD_HL        =  0x36;       // Z80 instruction: LD(HL), n
const byte    INC_HL       =  0x23;       // Z80 instruction: INC HL
const byte    LD_HLnn      =  0x21;       // Z80 instruction: LD HL, nn
const byte    JP_nn        =  0xC3;       // Z80 instruction: JP nn
const byte    RST_38H      =  0xFF;       // Z80 instruction: RST 38H
const String  compTimeStr  = __TIME__;    // Compile timestamp string
const String  compDateStr  = __DATE__;    // Compile datestamp string
const byte    daysOfMonth[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
const byte    debug        = 0;           // Debug off = 0, on = 1, on with interrupt trace = 2
const byte    bootModeAddr = 10;          // Internal EEPROM address for boot mode storage
const byte    autoexecFlagAddr = 12;      // Internal EEPROM address for AUTOEXEC flag storage
const byte    clockModeAddr = 13;         // Internal EEPROM address for the Z80 clock high/low speed switch
                                          //  (1 = low speed, 0 = high speed)
const byte    diskSetAddr  = 14;          // Internal EEPROM address for the current Disk Set [0..9]
const byte    serBaudAddr  = 15;          // Internal EEPROM address for the current serial speed index
const byte    ramCfgAddr   = 16;          // Internal EEPROM address fot the current RAM config
const byte    maxBaudIndex = 10;          // Max number of serial speed values
const byte    maxDiskNum   = 99;          // Max number of virtual disks
const byte    maxDiskSet   = 6;           // Number of configured Disk Sets
const byte    maxRamCfg    = 2;           // 2^(value+17)Bytes (0=128KByte,1=256KByte,2=512KByte)
const byte    fCPU         = F_CPU / 1000000L;


// ------------------------------------------------------------------------------
//
// Load Z80 program images into IOS flash
//
// ------------------------------------------------------------------------------

// Z80 TinyBASIC2 (improved Palo Alto Tiny BASIC)
#include "tinybasic2.h"

// Z80 WozMon (Apple 1 ROM monitor adapted for Z80)
#include "wozmon.h"


// ------------------------------------------------------------------------------
//
//  Global variables
//
// ------------------------------------------------------------------------------

// General purpose variables and types
enum          baudRecCheck  {BLK, CHECK}; // Used to set on/off the baud recovery option in the boot menu
byte          ioAddress;                  // Virtual I/O address. Only two possible addresses are valid (0x00 and 0x01)
byte          ioData;                     // Data byte used for the I/O operation
byte          ioOpcode       = 0xFF;      // I/O operation Opcode (0xFF means "No Operation")
byte          ioOpcodeUser   = 0xFF;      // User I/O operation Opcode (0xFF means "No Operation")
word          ioByteCnt      = 0;         // Exchanged bytes counter during an I/O operation
word          ioByteCntUser  = 0;         // Exchanged bytes counter during an user I/O operation
byte          tempByte;                   // Temporary variable (buffer)
byte          moduleGPIO     = 0;         // Set to 1 if the module is found, 0 otherwise
byte          SPPmode        = 0;         // Set to 1 if the GPIO port is used as a standard SPP (SPP Adapter)
byte          SPPautofd      = 0;         // Store the status of the AUTOFD Control Line (active Low) of the SPP
byte          bootMode       = 0;         // Set the program to boot (from flash or SD)
const byte *  BootImage;                  // Pointer to selected flash payload array (image) to boot
word          BootImageSize  = 0;         // Size of the selected flash payload array (image) to boot
word          BootStrAddr;                // Starting address of the selected program to boot (from flash or SD)
byte          Z80IntRx       = 0;         // Z80 serial Rx INT_ enable flag (0 = disabled, 1 = enabled)
byte          Z80IntSysTick  = 0;         // Z80 Systick INT_ enable flag (0 = disabled, 1 = enabled)
unsigned long timeStamp      = 0;         // Timestamp for Z80 Systick interrupt
char          inChar;                     // Input char from serial
byte          iCount;                     // Temporary variable (counter)
byte          clockMode;                  // Z80 clock HI/LO speed selector (0 = 8/10MHz, 1 = 4/5MHz)
byte          LastRxIsEmpty;              // "Last Rx char was empty" flag. Is set when a serial Rx operation was done
                                          //  when the Rx buffer was empty
byte          irqStatus      = 0;         // Store the interrupt status byte (every bit is the status of a different
                                          //  interrupt. See the SYSIRQ Opcode)
byte          intVector      = RST_38H;   // Restart opcode for IM0 interrupt. See the INTVECTOR Opcode)
byte          sysTickTime    = 100;       // Period in milliseconds of the Z80 Systick interrupt (if enabled)
byte          RxDoneFlag     = 1;         // This flag is set (= 1) soon after a Serial Rx operation
                                          //  (used for Rx interrupt control)
word          iSize          = 0;         // Temp variable
byte          serEventSeen   = 0;         // This flag is set (= 1) from serialEvent to trigger the RX INT
byte          cpmWarmBootFlg = 0;         // This flag enable/disable (1/0) the message "CP/M WARM BOOT"
                                          //  the CP/M CBIOS supports this switch (see the SETOPT Opcode)
byte          ramCfg;                     // Size of RAM in 2^(17+value)

// DS3231 RTC variables
byte          foundRTC;                   // Set to 1 if RTC is found, 0 otherwise
byte          seconds, minutes, hours, day, month, year;
byte          tempC;                      // Temperature (Celsius) encoded in two’s complement integer format

// SD disk and CP/M support variables
FATFS         filesysSD;                  // Filesystem object (PetitFS library)
byte          bufferSD[32];               // I/O buffer for SD disk operations (store a "segment" of a SD sector).
                                          //  Each SD sector (512 bytes) is divided into 16 segments (32 bytes each)
const char *  fileNameSD;                 // Pointer to the string with the currently used file name
byte          autobootFlag;               // Set to 1 if "autoboot.bin" must be executed at boot, 0 otherwise
byte          autoexecFlag;               // Set to 1 if AUTOEXEC must be executed at CP/M cold boot, 0 otherwise
byte          errCodeSD;                  // Temporary variable to store error codes from the PetitFS
byte          numReadBytes;               // Number of read bytes after a readSD() call

// Disk emulation on SD
char          diskName[11]    = Z80DISK;  // String used for virtual disk file name
char          OsName[11]      = DS_OSNAME;// String used for file holding the OS name
word          trackSel;                   // Store the current track number [0..511]
byte          sectSel;                    // Store the current sector number [0..31]
byte          diskErr         = 19;       // SELDISK, SELSECT, SELTRACK, WRITESECT, READSECT or SDMOUNT resulting
                                          //  error code
byte          numWriBytes;                // Number of written bytes after a writeSD() call
byte          diskSet;                    // Current "Disk Set"

// I2C SIO module for AUX I/O
byte          moduleSIO       = 0;        // Set to 1 if found

// CP/M3 baud rate values (See cap. 3.2 CP/M 3 System Guide)
                                // the 1st 16 baud rates are CP/M standard
const uint32_t      cpmBaudRate[] = {     0,    50,    75,   110, // div = -, 2304, 1536, 1047
                                        134,   150,   300,   600, // div = 859, 768, 384, 192
                                       1200,  1800,  2400,  3600, // div = 96, 64, 48, 32
                                       4800,  7200,  9600, 19200, // div = 24, 16, 12, 6
                                    // additional useful possible baud rates
                                      14400, 28800, 38400, 57600, // div = 8, 4, 3, 2
                                     115200                       // div = 1
                                    };

// IOS debugging support
// Can be set in boot menu by typing one ore more '?'
// Can be set / read from CP/M by IOS CMDs:
//  Opcode 0x7E  SAVEBYTE
//  Opcode 0xFE  READBYTE
// Also used temporarily for CP/M program Z80TYPE
//  to detect CMOS/NMOS using OUT (C),0 (ED 71)

byte          verbosity       = 0;


// ----------------------------------------------------------------------------------
// clang-format on


void setup() {
    // ------------------------------------------------------------------------------
    //
    //  Local variables
    //
    // ------------------------------------------------------------------------------

    uint8_t bootSelection = 0;     // Flag to enter into the boot mode selection

    // ------------------------------------------------------------------------------

    // ------------------------------------------------------------------------------
    // INITIALIZATION
    // ------------------------------------------------------------------------------

    // Initialize RESET_ and WAIT_RES_
    pinMode( RESET_, OUTPUT ); // Configure RESET_ and set it ACTIVE
    digitalWrite( RESET_, LOW );
    pinMode( WAIT_RES_, OUTPUT ); // Configure WAIT_RES_ and set it ACTIVE to reset the WAIT FF (U1C/D)
    digitalWrite( WAIT_RES_, LOW );

    // Check USER Key for boot mode changes
    pinMode( USER, INPUT_PULLUP ); // Read USER Key to enter into the boot mode selection
    if ( !digitalRead( USER ) )
        bootSelection = 1;

    // Initialize USER,  INT_, RAM_CE2, and BUSREQ_
    pinMode( USER, OUTPUT ); // USER led OFF
    digitalWrite( USER, HIGH );
    pinMode( INT_, INPUT_PULLUP ); // Configure INT_ and set it NOT ACTIVE
    pinMode( INT_, OUTPUT );
    digitalWrite( INT_, HIGH );
    pinMode( RAM_CE2, OUTPUT );       // Configure RAM_CE2 as output
    pinMode( WAIT_, INPUT );          // Configure WAIT_ as input
    pinMode( BUSREQ_, INPUT_PULLUP ); // Set BUSREQ_ HIGH
    pinMode( BUSREQ_, OUTPUT );
    digitalWrite( BUSREQ_, HIGH );

    // Initialize D0-D7, AD0, MREQ_, RD_ and WR_
    DDRA = 0x00; // Configure Z80 data bus D0-D7 (PA0-PA7) as input with pull-up
    PORTA = 0xFF;
    pinMode( MREQ_, INPUT_PULLUP ); // Configure MREQ_ as input with pull-up
    pinMode( RD_, INPUT_PULLUP );   // Configure RD_ as input with pull-up
    pinMode( WR_, INPUT_PULLUP );   // Configure WR_ as input with pull-up
    pinMode( AD0, INPUT_PULLUP );

    // Read the stored RAM-config, if not valid, set it to 0=128KBytes
    ramCfg = EEPROM.read( ramCfgAddr );
    if ( ramCfg > maxRamCfg ) {
        EEPROM.update( ramCfgAddr, 0 );
        ramCfg = 0;
    }

    // Print some system information
    Serial.begin( indexToBaud( EEPROM.read( serBaudAddr ) ) );

#if defined HW_STRING
    Serial.printf( F( HW_STRING " - %d MHz\r\n" ), fCPU ); // defined on top of file
#endif
#if defined VERSION_STRING && defined BUILD_STRING
    Serial.println( F( VERSION_STRING " - " BUILD_STRING ) ); // defined on top of file
#endif
    Serial.println();

    // Print if the input serial buffer is 128 bytes wide (this is needed for xmodem protocol support)
    if ( SERIAL_RX_BUFFER_SIZE >= 128 )
        Serial.printf( F( "IOS: Found extended serial Rx buffer (%d bytes)\r\n" ), SERIAL_RX_BUFFER_SIZE );

    // Initialize the Logical RAM Bank (32KB) to map into the lower half of the Z80 addressing space
    pinMode( BANK0, OUTPUT ); // Set RAM Logical Bank 1 (Os Bank 0)
    digitalWrite( BANK0, HIGH );
    pinMode( BANK1, OUTPUT );
    digitalWrite( BANK1, LOW );

    // Initialize CLK (single clock pulses mode) and reset the Z80 CPU
    pinMode( CLK, OUTPUT ); // Set CLK as output
    singlePulsesResetZ80(); // Reset the Z80 CPU using single clock pulses

    // Initialize MCU_RTS and MCU_CTS and reset uTerm (A071218-R250119) if present
    // only park CTS if standard 128KBytes RAM
    if ( ramCfg == 0 )
        pinMode( MCU_CTS_, INPUT_PULLUP ); // Parked (not used)
    else {
        pinMode( BANK2, OUTPUT );
        digitalWrite( BANK2, LOW );
    }

    if ( ramCfg < 2 ) {
        digitalWrite( RAM_CE2, HIGH ); // Set RAM_CE2 active HIGH
        // Serial.printf("CE2-INIT: %d\r\n",HIGH);
        pinMode( MCU_RTS_, OUTPUT );
        digitalWrite( MCU_RTS_, LOW ); // Reset the uTerm optional add-on board
        delay( 100 );
        digitalWrite( MCU_RTS_, HIGH );
        delay( 500 );
    } else {
        digitalWrite( RAM_CE2, LOW ); // Set RAM_CE2 active LOW
        // Serial.printf("CE2-INIT2: %d\r\n",LOW);
        pinMode( BANK3, OUTPUT );
        digitalWrite( BANK3, LOW );
    }

    // Read the Z80 CPU speed mode
    if ( EEPROM.read( clockModeAddr ) > 1 ) { // Check if it is a valid value, otherwise set it to low speed
                                              // Not a valid value. Set it to low speed
        EEPROM.update( clockModeAddr, 1 );
    }
    clockMode = EEPROM.read( clockModeAddr ); // Read the previous stored value

    // Read the stored Disk Set. If not valid set it to 0
    diskSet = EEPROM.read( diskSetAddr );
    if ( diskSet >= maxDiskSet ) {
        EEPROM.update( diskSetAddr, 0 );
        diskSet = 0;
    }

    // Initialize the EXP_PORT (I2C) and search for "known" optional modules
    Wire.begin(); // Wake up I2C bus
    Wire.setClock( 400000L );

    // Search for GPIO
    Wire.beginTransmission( GPIOEXP_ADDR );
    if ( Wire.endTransmission() == 0 ) {
        // Found GPE expansion
        moduleGPIO = 1; // Set to 1 if GPIO Module is found
        // Set pullup enabled for GPA0 and GPA2:
        //  this just in case the SPP adapter is used and a printer is connected and powered on before the Z80-MBC2,
        //  to avoid a possible "strange" behavior of the printer (GPA0 = STROBE_, GPA2 = INIT_. See SPP Adapter schematic)
        Wire.beginTransmission( GPIOEXP_ADDR );
        Wire.write( GPPUA_REG );  // Select GPPUA
        Wire.write( 0b00000101 ); // Write value (1 = pullup enabled, 0 = pullup disabled)
        Wire.endTransmission();
    }

    // Search for SIO
    Wire.beginTransmission( SC16IS752_ADDRESS );
    if ( Wire.endTransmission() == 0 ) {
        // Found I2C SIO expansion
        if ( SC16IS752_Ping() ) {
            moduleSIO = 1;                                                      // Set to 1 if SIO Module is found
            SC16IS752_Init( SC16IS752_DEFAULT_SPEED, SC16IS752_DEFAULT_SPEED ); // Init SIOA and SIOB
        }
    }

    // Check the serial speed index and set it to the default if needed
    if ( EEPROM.read( serBaudAddr ) >= maxBaudIndex ) {
        // Invalid value. Set it to the default 115200 index
        EEPROM.update( serBaudAddr, 9 );
    }

    // Print the Z80 clock speed mode
    Serial.printf( F( "IOS: Z80 clock set at %d MHz\r\n" ), clockMode ? fCPU / 4 : fCPU / 2 );

    // Print the RAM size
    Serial.printf( F( "IOS: %d KBytes RAM" ), ( 128 << ramCfg ) );
    if ( ramCfg == 1 )
        Serial.print( F( " (CTS used as BANK2 signal)" ) );
    else if ( ramCfg == 2 )
        Serial.print( F( " (CTS, RTS used as BANK2, BANK3 signal, CE2 inverted)" ) );
    Serial.println();

    // Print RTC, GPIO, SIO informations if found
    foundRTC = autoSetRTC(); // Check if RTC is present and initialize it as needed
    if ( moduleGPIO )
        Serial.println( F( "IOS: Found GPE Option" ) );
    if ( moduleSIO )
        Serial.println( F( "IOS: Found SIOA / SIOB Option" ) );

    // Print CP/M Autoexec on cold boot status
    if ( EEPROM.read( autoexecFlagAddr ) > 1 )
        EEPROM.update( autoexecFlagAddr, 0 );       // Reset AUTOEXEC flag to OFF if invalid
    autoexecFlag = EEPROM.read( autoexecFlagAddr ); // Read the previous stored AUTOEXEC flag
    Serial.printf( F( "IOS: CP/M Autoexec is %s\r\n" ), autoexecFlag ? "ON" : "OFF" );

    // ----------------------------------------
    // BOOT SELECTION AND SYS PARAMETERS MENU
    // ----------------------------------------

    // Boot selection and system parameters menu if requested

    const char M_EXIT = 'X';
    //
    const char M_BASIC = 'B';
    const char M_FORTH = 'F';
    const char M_DISKOS = 'O';
    const char M_AUTOBOOT = 'A';
    //
    const char M_TINYBASIC2 = 'T';
    const char M_WOZMON = 'W';
    const char M_HEXLOAD = 'H';
    //
    const char M_CLOCK = 'C';
    const char M_AUTOEXEC = 'E';
    const char M_SERSPEED = 'S';
    const char M_DATETIME = 'D';
    const char M_RAMSIZE = 'R';

    const char CR = '\x0D';
    const char ESC = '\x1B';

    char menuCharSet[] = {
        M_EXIT,
        // SD card boot
        M_BASIC, M_FORTH, M_DISKOS, M_AUTOBOOT,
        // IOS boot
        M_TINYBASIC2, M_WOZMON,
        // Intel HEX loader
        M_HEXLOAD,
        // settings
        M_CLOCK, M_AUTOEXEC, M_SERSPEED, M_DATETIME, M_RAMSIZE
    };

    const uint8_t maxSDMode = 3;   // [0..3] Basic, Forth, CP/M etc, AutoBoot
    const uint8_t maxBootMode = 6; // [0..6] as above and tinybasic2 .. hexload

    mountSD( &filesysSD ); // Try to mount the SD volume
    mountSD( &filesysSD );

    bootMode = EEPROM.read( bootModeAddr ); // Read the previous stored boot mode
    if ( ( bootSelection == 1 ) || ( bootMode > maxBootMode ) ) {
        // Enter in the boot selection menu if USER key was pressed at startup
        //   or an invalid bootMode code was read from internal EEPROM
        while ( Serial.available() > 0 ) { // Flush input serial Rx buffer
            Serial.read();
        }
        Serial.printf( F( "\r\nIOS: Select Boot Mode or System Parameters:\r\n\n" ) );

        if ( bootMode <= maxBootMode ) { // valid boot mode found
            Serial.printf( F( "  %c: Exit without change ('%c')\r\n\n" ), M_EXIT, menuCharSet[ bootMode + 1 ] );
        } else { // disable EXIT option
            byte pos = findChar( M_EXIT, menuCharSet );
            if ( pos )
                menuCharSet[ pos - 1 ] = tolower( M_EXIT );
        }
        //
        // Boot programs from SD
        Serial.printf( F( "  %c: Basic\r\n" ), M_BASIC );     // B
        Serial.printf( F( "  %c: Forth\r\n" ), M_FORTH );     // F
        Serial.printf( F( "  %c: Load/Set OS " ), M_DISKOS ); // O
        printOsName( diskSet );
        Serial.println();
        Serial.printf( F( "  %c: Autoboot\r\n" ), M_AUTOBOOT );     // A
        // Boot programs from flash
        Serial.printf( F( "  %c: TinyBasic2\r\n" ), M_TINYBASIC2 ); // T
        Serial.printf( F( "  %c: WozMon\r\n" ), M_WOZMON );         // W
        // Hex loader from IOS
        Serial.printf( F( "  %c: HexLoad\r\n" ), M_HEXLOAD );       // H
        Serial.println();
        //
        // Option settings
        Serial.printf( F( "  %c: Change Z80 Clock Speed (-> %d MHz)\r\n" ), M_CLOCK, clockMode ? fCPU / 2 : fCPU / 4 );       // C
        Serial.printf( F( "  %c: Toggle CP/M Autoexec (-> %s)\r\n" ), M_AUTOEXEC, autoexecFlag ? "OFF" : "ON" );              // E
        Serial.printf( F( "  %c: Set Serial Port Speed (%ld)\r\n" ), M_SERSPEED, indexToBaud( EEPROM.read( serBaudAddr ) ) ); // S

        if ( foundRTC ) {                                                    // If RTC module is present add a menu choice
            Serial.printf( F( "  %c: Set RTC Date/Time\r\n" ), M_DATETIME ); // D
        } else {                                                             // else disable RTC menu
            byte pos = findChar( M_DATETIME, menuCharSet );
            if ( pos )                                          // found
                menuCharSet[ pos - 1 ] = tolower( M_DATETIME ); // set inactive
        }
        Serial.printf( F( "  %c: RAM size (%d KBytes)\r\n" ), M_RAMSIZE, 128 << EEPROM.read( ramCfgAddr ) );

        // Ask a choice
        Serial.printf( F( "\r\nEnter your choice > " ) );
        do {
            WaitAndBlink( CHECK );
            inChar = toupper( Serial.read() );
            // debugging support
            if ( inChar == '?' )
                ++verbosity;
            else if ( inChar == ' ' )
                verbosity = 0;
        } while ( !findChar( inChar, menuCharSet ) );
        Serial.println( inChar );
        if ( verbosity )
            Serial.printf( F( "?Verbosity level %d\r\n" ), verbosity );

        // Make the selected action for the system parameters choice
        switch ( inChar ) {
        case M_DISKOS: // Load/change current Disk Set
            printMsg1();
            iCount = (byte)( diskSet - 1 ); // Set the previous Disk Set
            do {                            // Print the OS name of the next Disk Set
                iCount = (byte)( iCount + 1 ) % maxDiskSet;
                Serial.print( F( "\r ->" ) );
                printOsName( iCount );
                Serial.print( F( "                 \r" ) );
                while ( Serial.available() > 0 )
                    Serial.read(); // Flush serial Rx buffer
                while ( Serial.available() < 1 )
                    WaitAndBlink( BLK ); // Wait a key
                inChar = Serial.read();
            } while ( ( inChar != CR ) && ( inChar != ESC ) ); // Continue until CR or ESC
            Serial.printf( F( "\r\n\n" ) );
            if ( inChar == CR ) { // Set and store the new Disk Set if required
                diskSet = iCount;
                EEPROM.update( diskSetAddr, iCount );
                inChar = M_DISKOS; // Set to boot the current selected OS
            }
            break;

        case M_CLOCK:
            clockMode = !clockMode;                    // Toggle Z80 clock speed mode (High/Low)
            EEPROM.update( clockModeAddr, clockMode ); // Save it to the internal EEPROM
            break;

        case M_AUTOEXEC:
            autoexecFlag = !autoexecFlag;                    // Toggle AUTOEXEC executiont status
            EEPROM.update( autoexecFlagAddr, autoexecFlag ); // Save it to the internal EEPROM
            break;

        case M_SERSPEED: // Change serial port speed
            printMsg1();
            iCount = EEPROM.read( serBaudAddr ); // Read the serial speed index
            iCount = (byte)( iCount - 1 );       // Set the previous speed index
            do {                                 // Print the current serial speed
                iCount = (byte)( iCount + 1 ) % maxBaudIndex;
                Serial.printf( F( "\r ->%ld   \r" ), indexToBaud( iCount ) );
                while ( Serial.available() > 0 )
                    Serial.read(); // Flush serial Rx buffer
                while ( Serial.available() < 1 )
                    WaitAndBlink( BLK ); // Wait a key
                inChar = Serial.read();
            } while ( ( inChar != CR ) && ( inChar != ESC ) ); // Continue until CR or ESC
            Serial.printf( F( "\r\n\n" ) );
            if ( ( inChar == CR ) && ( iCount != EEPROM.read( serBaudAddr ) ) ) {
                // Store new serial speed index
                EEPROM.update( serBaudAddr, iCount );
                Serial.printf( F( "Changed speed will be effective after next reboot!\r\n\n" ) );
            }
            break;

        case M_DATETIME:
            ChangeRTC(); // Change RTC Date/Time if requested
            break;

        case M_RAMSIZE:
            printMsg1();
            iCount = (byte)( ramCfg - 1 ); // Set the previous RAM size
            do {
                // Print the RAM-size
                iCount = (byte)( iCount + 1 ) % ( maxRamCfg + 1 );
                Serial.print( F( "\r ->" ) );
                Serial.printf( F( "%d KBytes\r" ), ( 128 << iCount ) );
                while ( Serial.available() > 0 )
                    Serial.read(); // Flush serial Rx buffer
                while ( Serial.available() < 1 )
                    WaitAndBlink( BLK ); // Wait a key
                inChar = Serial.read();
            } while ( ( inChar != CR ) && ( inChar != ESC ) ); // Continue until a CR or ESC is pressed
            Serial.println();
            Serial.println();
            if ( inChar == CR ) { // Set and store the new ram size if required
                ramCfg = iCount;
                EEPROM.update( ramCfgAddr, iCount );
                inChar = M_EXIT; // Set to boot the current selected OS
            }
            break;
        };

        // Save selectd boot program if changed
        bootMode = findChar( inChar, menuCharSet ) - 2; // Calculate bootMode from inChar
        if ( verbosity )
            Serial.printf( F( "DEBUG: bootMode: %d\r\n" ), bootMode );
        if ( bootMode <= maxBootMode )
            EEPROM.update( bootModeAddr, bootMode ); // Save to the internal EEPROM if required
        else
            bootMode = EEPROM.read( bootModeAddr ); // Reload boot mode if '0' or > '5' choice selected
    }

    // Print current Disk Set and OS name (if OS boot is enabled)
    if ( bootMode == 2 ) {
        Serial.print( F( "IOS: Current " ) );
        printOsName( diskSet );
        Serial.println();
    }

    // ----------------------------------------
    // Z80 PROGRAM LOAD
    // ----------------------------------------

    // Get the starting address of the program to load and boot, and its size if stored in the flash
    switch ( bootMode ) {
    case 0: // Load Basic from SD
        fileNameSD = BASICFN;
        BootStrAddr = BASSTRADDR;
        Z80IntRx = 1; // Enable Z80 Rx INT_ interrupt signal generation (Z80 M1 INT I/O)
        break;

    case 1: // Load Forth from SD
        fileNameSD = FORTHFN;
        BootStrAddr = FORSTRADDR;
        break;

    case 2: // Load an OS from current Disk Set on SD
        switch ( diskSet ) {
        case 0: // CP/M 2.2
            fileNameSD = CPMFN;
            BootStrAddr = CPMSTRADDR;
            break;

        case 1: // QP/M 2.71
            fileNameSD = QPMFN;
            BootStrAddr = QPMSTRADDR;
            break;

        case 2: // CP/M 3.0
            fileNameSD = CPM3FN;
            BootStrAddr = CPM3STRADDR;
            break;

        case 3: // UCSD Pascal
            fileNameSD = UCSDFN;
            BootStrAddr = UCSDSTRADDR;
            break;

        case 4: // Collapse OS
            fileNameSD = COSFN;
            BootStrAddr = COSSTRADDR;
            break;

        case 5: // Fuzix OS
            fileNameSD = FUZIXFN;
            BootStrAddr = FUZSTRADDR;
            Z80IntRx = 1;      // Enable Z80 Rx INT_ interrupt signal generation (Z80 M1 INT I/O)
            Z80IntSysTick = 1; // Enable Z80 Systick INT_ interrupt signal generation (Z80 M1 INT I/O)
            break;
        }
        break;

    case 3: // Load AUTOBOOT.BIN from SD (load an user executable binary file)
        fileNameSD = AUTOFN;
        BootStrAddr = AUTSTRADDR;
        break;

    case 4: // Load tinyBasic from IOS FLASH
        BootImage = tinybasic2;
        BootImageSize = tinybasic2Size;
        BootStrAddr = tinybasic2Addr;
        break;

    case 5: // Load WozMon from IOS FLASH
        BootImage = WozMon;
        BootImageSize = WozMonSize;
        BootStrAddr = WozMonAddr;
        break;

    case 6: // IOS HexLoad
        Serial.printf( F( "Intel-Hex Loader\r\n" ) );
        loadIntelHex();
        break;
    }

    digitalWrite( WAIT_RES_, HIGH ); // Set WAIT_RES_ HIGH (Led LED_0 ON)

    // Load a JP instruction if the boot program starting addr is > 0x0000
    if ( BootStrAddr > 0x0000 ) {                 // Check if the boot program starting addr > 0x0000
                                                  // Inject a "JP <BootStrAddr>" instruction to jump at boot starting address
        loadHL( 0x0000 );                         // HL = 0x0000 (used as pointer to RAM)
        loadByteToRAM( JP_nn );                   // Write the JP instruction @ 0x0000;
        loadByteToRAM( lowByte( BootStrAddr ) );  // Write LSB to jump @ 0x0001
        loadByteToRAM( highByte( BootStrAddr ) ); // Write MSB to jump @ 0x0002

        //
        // DEBUG ----------------------------------
        if ( verbosity )
            Serial.printf( F( "DEBUG: Injected JP 0x%04X\r\n" ), BootStrAddr );
        // DEBUG END ------------------------------
        //
    }

    // Execute the load of the selected file on SD or image on flash
    loadHL( BootStrAddr ); // Set Z80 HL = boot starting address (used as pointer to RAM);

    //
    // DEBUG ----------------------------------
    if ( verbosity ) {
        Serial.print( F( "DEBUG: Flash BootImageSize = " ) );
        Serial.println( BootImageSize );
        Serial.print( F( "DEBUG: BootStrAddr = " ) );
        Serial.println( BootStrAddr, HEX );
    }
    // DEBUG END ------------------------------
    //

    if ( bootMode <= maxSDMode ) {
        // Load from SD
        // Mount a volume on SD
        if ( mountSD( &filesysSD ) ) {
            // Error mounting. Try again
            errCodeSD = mountSD( &filesysSD );
            if ( errCodeSD )
                // Error again. Repeat until error disappears (or the user forces a reset)
                do {
                    printErrSD( 0, errCodeSD, NULL );
                    waitKey();             // Wait a key to repeat
                    mountSD( &filesysSD ); // New double try
                    errCodeSD = mountSD( &filesysSD );
                } while ( errCodeSD );
        }

        // Open the selected file to load
        if ( 0 == strcmp( fileNameSD, "CPMLDR.COM" ) // Ho-Ro - HACK for my CP/M3 BIOS development:
             && ( 0 == openSD( "CPMXLDR.COM" ) ) ) { // "CPMLDR.COM" requested and "CPMXLDR.COM" found on SD
            fileNameSD = "CPMXLDR.COM";              // Announce the correct name
            digitalWrite( USER, LOW );               // Switch USER LED as optical hint that the user can now
        } // press the USER KEY to fall back to the old "CPM3.SYS",
          // otherwise load the new system "CPMX.SYS"
        else // Normal boot
            errCodeSD = openSD( fileNameSD );
        if ( errCodeSD )
            // Error opening the required file. Repeat until error disappears (or the user forces a reset)
            do {
                printErrSD( 1, errCodeSD, fileNameSD );
                waitKey(); // Wait a key to repeat
                errCodeSD = openSD( fileNameSD );
                if ( errCodeSD != 3 ) {
                    // Try to do a two mount operations followed by an open
                    mountSD( &filesysSD );
                    mountSD( &filesysSD );
                    errCodeSD = openSD( fileNameSD );
                }
            } while ( errCodeSD );

        // Read the selected file from SD and load it into RAM until an EOF is reached
        Serial.printf( F( "IOS: Loading boot program (%s)..." ), fileNameSD );
        do {
            // If an error occurs repeat until error disappears (or the user forces a reset)
            do {
                // Read a "segment" of a SD sector and load it into RAM
                errCodeSD = readSD( bufferSD, &numReadBytes ); // Read current "segment" (32 bytes) of the current SD serctor
                for ( iCount = 0; iCount < numReadBytes; iCount++ ) {
                    // Load the read "segment" into RAM
                    loadByteToRAM( bufferSD[ iCount ] ); // Write current data byte into RAM
                }
            } while ( ( numReadBytes == 32 ) && ( !errCodeSD ) ); // If numReadBytes < 32 -> EOF reached
            if ( errCodeSD ) {
                printErrSD( 2, errCodeSD, fileNameSD );
                waitKey();   // Wait a key to repeat
                seekSD( 0 ); // Reset the sector pointer
            }
        } while ( errCodeSD );
    } else if ( bootMode < maxBootMode ) { // skip HEXLOAD
        // Load from flash
        Serial.print( F( "IOS: Loading boot program..." ) );
        for ( word i = 0; i < BootImageSize; i++ ) {
            // Write boot program into external RAM
            loadByteToRAM( pgm_read_byte( BootImage + i ) ); // Write current data byte into RAM
        }
    } else // HEX load already done, just be verbose
        Serial.print( F( "Hex Load" ) );

    Serial.println( F( " Done" ) );

    // ----------------------------------------
    // Z80 BOOT
    // ----------------------------------------

    digitalWrite( RESET_, LOW ); // Activate the RESET_ signal

#if defined( __AVR_ATmega32__ )
    // Atmega32 MCU
    // Initialize CLK @ 4/8MHz (@ Fosc = 16MHz). Z80 clock_freq = (Atmega_clock) / ((OCR2 + 1) * 2)
    ASSR &= ~( 1 << AS2 );  // Set Timer2 clock from system clock
    TCCR2 |= ( 1 << CS20 ); // Set Timer2 clock to "no prescaling"
    TCCR2 &= ~( ( 1 << CS21 ) | ( 1 << CS22 ) );
    TCCR2 |= ( 1 << WGM21 ); // Set Timer2 CTC mode
    TCCR2 &= ~( 1 << WGM20 );
    TCCR2 |= ( 1 << COM20 ); // Set "toggle OC2 on compare match"
    TCCR2 &= ~( 1 << COM21 );
    OCR2 = clockMode; // Set the compare value to toggle OC2 (0 = low or 1 = high)

#elif defined( __AVR_ATmega1284__ ) || defined( __AVR_ATmega1284P__ )
    // Atmega1284 MCU
    // Initialize CLK @ 4/8MHz (@ Fosc = 16MHz). Z80 clock_freq = (Atmega_clock) / ((OCR2 + 1) * 2)
    ASSR &= ~( 1 << AS2 );   // Set Timer2 clock from system clock
    TCCR2B |= ( 1 << CS20 ); // Set Timer2 clock to "no prescaling"
    TCCR2B &= ~( ( 1 << CS21 ) | ( 1 << CS22 ) );
    TCCR2A |= ( 1 << WGM21 ); // Set Timer2 CTC mode
    TCCR2A &= ~( 1 << WGM20 );
    TCCR2A |= ( 1 << COM2A0 ); // Set "toggle OC2 on compare match"
    TCCR2A &= ~( 1 << COM2A1 );
    OCR2A = clockMode; // Set the compare value to toggle OC2 (0 = low or 1 = high)

#else
    Serial.print( F( "IOS: Current MCU is not supported. Aborted!" ) );
    while ( 1 )
        ; // idle
#endif

    pinMode( CLK, OUTPUT ); // Set OC2 as output and start to output the clock
    Serial.println( F( "IOS: Z80 is running from now" ) );

    // Flush serial Rx buffer
    while ( Serial.available() > 0 ) {
        Serial.read();
    }

    // Leave the Z80 CPU running
    delay( 1 );                   // Just to be sure...
    digitalWrite( RESET_, HIGH ); // Release Z80 from reset and let it run

} // void setup()

// ------------------------------------------------------------------------------

// Currently defined Opcodes for I/O read operations:
//          Name         OPCODE   Exchanged bytes
// -------------------------------------------------
//
#define OPC_USER_LED 0x00      //   1
#define OPC_SERIAL_TX 0x01     //   1
#define OPC_GPIOA_WRITE 0x03   //   1
#define OPC_GPIOB_WRITE 0x04   //   1
#define OPC_IODIRA_WRITE 0x05  //   1
#define OPC_IODIRB_WRITE 0x06  //   1
#define OPC_GPPUA_WRITE 0x07   //   1
#define OPC_GPPUB_WRITE 0x08   //   1
#define OPC_SELDISK 0x09       //   1
#define OPC_SELTRACK 0x0A      //   2
#define OPC_SELSECT 0x0B       //   1
#define OPC_WRITESECT 0x0C     // 512
#define OPC_SETBANK 0x0D       //   1
#define OPC_SETIRQ 0x0E        //   1
#define OPC_SETTICK 0x0F       //   1
#define OPC_SETOPT 0x10        //   1
#define OPC_SETSPP 0x11        //   1
#define OPC_WRSPP 0x12         //   1
#define OPC_SETVECTOR 0x13     //   1
#define OPC_SIOA_TXD 0x20      //   1
#define OPC_SIOB_TXD 0x21      //   1
#define OPC_SIOA_CTRL 0x22     //   1
#define OPC_SIOB_CTRL 0x23     //   1
#define OPC_SET_VERBOSITY 0x7E //   1

// Currently defined Opcodes for I/O read operations:
//          Name         OPCODE   Exchanged bytes
// -------------------------------------------------
#define OPC_USER_KEY 0x80      //   1
#define OPC_GPIOA_READ 0x81    //   1
#define OPC_GPIOB_READ 0x82    //   1
#define OPC_SYSFLAGS 0x83      //   1
#define OPC_DATETIME 0x84      //   7
#define OPC_ERRDISK 0x85       //   1
#define OPC_READSECT 0x86      // 512
#define OPC_SDMOUNT 0x87       //   1
#define OPC_ATXBUFF 0x88       //   1
#define OPC_SYSIRQ 0x89        //   1
#define OPC_GETSPP 0x8A        //   1
#define OPC_ARXBUFF 0x8B       //   1
#define OPC_SIOA_RXD 0xA0      //   1
#define OPC_SIOB_RXD 0xA1      //   1
#define OPC_SIOA_RXSTAT 0xA2   //   1
#define OPC_SIOB_RXSTAT 0xA3   //   1
#define OPC_SIOA_TXSTAT 0xA4   //   1
#define OPC_SIOB_TXSTAT 0xA5   //   1
#define OPC_GET_VERBOSITY 0xFE //   1

#define OPC_NO_OP 0xFF //   -

// .........................................................................................................
//
// AD0 = 1 (I/O write address = 0x01). STORE Opcode.
//
// Store (write) an "I/O operation code" (Opcode) and reset the exchanged bytes counter.
//
// NOTE 1: An Opcode can be a write or read Opcode, if the I/O operation is read or write.
// NOTE 2: the STORE Opcode operation must always precede an EXECUTE WRITE Opcode or EXECUTE READ Opcode
//         operation.
// NOTE 3: For multi-byte read Opcode (as DATETIME) read sequentially all the data bytes without to send
//         a STORE Opcode operation before each data byte after the first one.
// .........................................................................................................


void loop() {
    if ( !digitalRead( WAIT_ ) ) {
        // I/O operaton requested

        if ( !digitalRead( WR_ ) ) {
            // I/O WRITE operation requested

            // ----------------------------------------
            // VIRTUAL I/O WRITE OPERATIONS ENGINE
            // ----------------------------------------

            ioAddress = digitalRead( AD0 ); // Read Z80 address bus line AD0 (PC2)
            ioData = PINA;                  // Read Z80 data bus D0-D7 (PA0-PA7)
            if ( ioAddress ) {              // Check the I/O address (only AD0 is checked!)
                // .........................................................................................................
                if ( ioOpcode != OPC_NO_OP ) { // Non-atomic user action was interrupted
                    ioOpcodeUser = ioOpcode;   // Save user context
                    ioByteCntUser = ioByteCnt;
                }
                ioOpcode = ioData; // Store the I/O Opcode
                ioByteCnt = 0;     // Reset the exchanged bytes counter
            } else {
                // .........................................................................................................
                //
                // AD0 = 0 (I/O write address = 0x00). EXECUTE WRITE Opcode.
                //
                // Execute the previously stored I/O write Opcode with the current data.
                // The code of the I/O write operation (Opcode) must be previously stored with a STORE Opcode operation.
                // .........................................................................................................
                //
                switch ( ioOpcode ) {
                    // Execute the requested I/O WRITE Opcode. The 0xFF value is reserved as "No operation".
                case OPC_USER_LED:
                    // USER LED:
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                              x  x  x  x  x  x  x  0    USER Led off
                    //                              x  x  x  x  x  x  x  1    USER Led on

                    if ( ioData & 0x01 )
                        digitalWrite( USER, LOW );
                    else
                        digitalWrite( USER, HIGH );
                    break;

                case OPC_SERIAL_TX:
                    // SERIAL TX:
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    ASCII char to be sent to serial

                    Serial.write( ioData );
                    break;

                case OPC_GPIOA_WRITE:
                    // GPIOA Write (GPE Option):
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    GPIOA value (see MCP23017 datasheet)

                    if ( moduleGPIO ) {
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOA_REG ); // Select GPIOA
                        Wire.write( ioData );    // Write value
                        Wire.endTransmission();
                    }
                    break;

                case OPC_GPIOB_WRITE:
                    // GPIOB Write (GPE Option):
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    GPIOB value (see MCP23017 datasheet)

                    if ( moduleGPIO ) {
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOB_REG ); // Select GPIOB
                        Wire.write( ioData );    // Write value
                        Wire.endTransmission();
                    }
                    break;

                case OPC_IODIRA_WRITE:
                    // IODIRA Write (GPE Option):
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    IODIRA value (see MCP23017 datasheet)

                    if ( moduleGPIO ) {
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( IODIRA_REG ); // Select IODIRA
                        Wire.write( ioData );     // Write value
                        Wire.endTransmission();
                    }
                    break;

                case OPC_IODIRB_WRITE:
                    // IODIRB Write (GPE Option):
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    IODIRB value (see MCP23017 datasheet)

                    if ( moduleGPIO ) {
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( IODIRB_REG ); // Select IODIRB
                        Wire.write( ioData );     // Write value
                        Wire.endTransmission();
                    }
                    break;

                case OPC_GPPUA_WRITE:
                    // GPPUA Write (GPE Option):
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    GPPUA value (see MCP23017 datasheet)

                    if ( moduleGPIO ) {
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPPUA_REG ); // Select GPPUA
                        Wire.write( ioData );    // Write value
                        Wire.endTransmission();
                    }
                    break;

                case OPC_GPPUB_WRITE:
                    // GPPUB Write (GPIO Exp. Mod. ):
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    GPPUB value (see MCP23017 datasheet)

                    if ( moduleGPIO ) {
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPPUB_REG ); // Select GPPUB
                        Wire.write( ioData );    // Write value
                        Wire.endTransmission();
                    }
                    break;

                case OPC_SELDISK:
                    // DISK EMULATION
                    // SELDISK - select the emulated disk number (binary). 100 disks are supported [0..99]:
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    DISK number (binary) [0..99]
                    //
                    //
                    // Opens the "disk file" correspondig to the selected disk number, doing some checks.
                    // A "disk file" is a binary file that emulates a disk using a LBA-like logical sector number.
                    // Every "disk file" must have a dimension of 8388608 bytes, corresponding to 16384 LBA-like logical sectors
                    //  (each sector is 512 bytes long), correspinding to 512 tracks of 32 sectors each (see SELTRACK and
                    //  SELSECT Opcodes).
                    // Errors are stored into "errDisk" (see ERRDISK Opcode).
                    //
                    //
                    // ...........................................................................................
                    //
                    // "Disk file" filename convention:
                    //
                    // Every "disk file" must follow the sintax "DSsNnn.DSK" where
                    //
                    //    "s" is the "disk set" and must be in the [0..9] range (always one numeric ASCII character)
                    //    "nn" is the "disk number" and must be in the [00..99] range (always two numeric ASCII characters)
                    //
                    // ...........................................................................................
                    //
                    //
                    // NOTE 1: The maximum disks number may be lower due the limitations of the used OS (e.g. CP/M 2.2 supports
                    //         a maximum of 16 disks)
                    // NOTE 2: Because SELDISK opens the "disk file" used for disk emulation, before using WRITESECT or READSECT
                    //         a SELDISK must be performed at first.

                    if ( ioData <= maxDiskNum ) {             // Valid disk number
                                                              // Set the name of the file to open as virtual disk, and open it
                        diskName[ 2 ] = diskSet + 48;         // Set the current Disk Set
                        diskName[ 4 ] = ( ioData / 10 ) + 48; // Set the disk number
                        diskName[ 5 ] = ioData - ( ( ioData / 10 ) * 10 ) + 48;
                        diskErr = openSD( diskName ); // Open the "disk file" corresponding to the given disk number
                    } else
                        diskErr = 16; // Illegal disk number
                    break;

                case OPC_SELTRACK:
                    // DISK EMULATION
                    // SELTRACK - select the emulated track number (word splitted in 2 bytes in sequence: DATA 0 and DATA 1):
                    //
                    //                I/O DATA 0:  D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    Track number (binary) LSB [0..255]
                    //
                    //                I/O DATA 1:  D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    Track number (binary) MSB [0..1]
                    //
                    //
                    // Stores the selected track number into "trackSel" for "disk file" access.
                    // A "disk file" is a binary file that emulates a disk using a LBA-like logical sector number.
                    // The SELTRACK and SELSECT operations convert the legacy track/sector address into a LBA-like logical
                    //  sector number used to set the logical sector address inside the "disk file".
                    // A control is performed on both current sector and track number for valid values.
                    // Errors are stored into "diskErr" (see ERRDISK Opcode).
                    //
                    //
                    // NOTE 1: Allowed track numbers are in the range [0..511] (512 tracks)
                    // NOTE 2: Before a WRITESECT or READSECT operation at least a SELSECT or a SELTRAK operation
                    //         must be performed

                    if ( !ioByteCnt ) {
                        // LSB
                        trackSel = ioData;
                    } else {
                        // MSB
                        trackSel = ( ( (word)ioData ) << 8 ) | lowByte( trackSel );
                        if ( ( trackSel < 512 ) && ( sectSel < 32 ) ) {
                            // Sector and track numbers valid
                            diskErr = 0; // No errors
                        } else {
                            // Sector or track invalid number
                            if ( sectSel < 32 )
                                diskErr = 17; // Illegal track number
                            else
                                diskErr = 18; // Illegal sector number
                        }
                        ioOpcode = ioOpcodeUser;   // All done
                        ioByteCnt = ioByteCntUser; // Restore user context
                    }
                    ioByteCnt++;
                    break;

                case OPC_SELSECT:
                    // DISK EMULATION
                    // SELSECT - select the emulated sector number (binary):
                    //
                    //                  I/O DATA:  D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    Sector number (binary) [0..31]
                    //
                    //
                    // Stores the selected sector number into "sectSel" for "disk file" access.
                    // A "disk file" is a binary file that emulates a disk using a LBA-like logical sector number.
                    // The SELTRACK and SELSECT operations convert the legacy track/sector address into a LBA-like logical
                    //  sector number used to set the logical sector address inside the "disk file".
                    // A control is performed on both current sector and track number for valid values.
                    // Errors are stored into "diskErr" (see ERRDISK Opcode).
                    //
                    //
                    // NOTE 1: Allowed sector numbers are in the range [0..31] (32 sectors)
                    // NOTE 2: Before a WRITESECT or READSECT operation at least a SELSECT or a SELTRAK operation
                    //         must be performed

                    sectSel = ioData;
                    if ( ( trackSel < 512 ) && ( sectSel < 32 ) ) {
                        // Sector and track numbers valid
                        diskErr = 0; // No errors
                    } else {
                        // Sector or track invalid number
                        if ( sectSel < 32 )
                            diskErr = 17; // Illegal track number
                        else
                            diskErr = 18; // Illegal sector number
                    }
                    break;

                case OPC_WRITESECT:
                    // DISK EMULATION
                    // WRITESECT - write 512 data bytes sequentially into the current emulated disk/track/sector:
                    //
                    //                 I/O DATA 0: D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    First Data byte
                    //
                    //                      |               |
                    //                      |               |
                    //                      |               |                 <510 Data Bytes>
                    //                      |               |
                    //
                    //
                    //               I/O DATA 511: D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    512th Data byte (Last byte)
                    //
                    //
                    // Writes the current sector (512 bytes) of the current track/sector, one data byte each call.
                    // All the 512 calls must be always performed sequentially to have a WRITESECT operation correctly done.
                    // If an error occurs during the WRITESECT operation, all subsequent write data will be ignored and
                    //  the write finalization will not be done.
                    // If an error occurs calling any DISK EMULATION Opcode (SDMOUNT excluded) immediately before the WRITESECT
                    //  Opcode call, all the write data will be ignored and the WRITESECT operation will not be performed.
                    // Errors are stored into "diskErr" (see ERRDISK Opcode).
                    //
                    // NOTE 1: Before a WRITESECT operation at least a SELTRACK or a SELSECT must be always performed
                    // NOTE 2: Remember to open the right "disk file" at first using the SELDISK Opcode
                    // NOTE 3: The write finalization on SD "disk file" is executed only on the 512th data byte exchange, so be
                    //         sure that exactly 512 data bytes are exchanged.

                    if ( !ioByteCnt ) {
                        // First byte of 512, so set the right file pointer to the current emulated track/sector first
                        if ( ( trackSel < 512 ) && ( sectSel < 32 ) && ( !diskErr ) ) {
                            // Sector and track numbers valid and no previous error; set the LBA-like logical sector
                            diskErr = seekSD( ( trackSel << 5 ) | sectSel ); // Set the starting point inside the "disk file"
                                                                             //  generating a 14 bit "disk file" LBA-like
                                                                             //  logical sector address created as TTTTTTTTTSSSSS
                        }
                    }


                    if ( !diskErr ) {
                        // No previous error (e.g. selecting disk, track or sector)
                        tempByte = ioByteCnt % 32;     // [0..31]
                        bufferSD[ tempByte ] = ioData; // Store current exchanged data byte in the buffer array
                        if ( tempByte == 31 ) {
                            // Buffer full. Write all the buffer content (32 bytes) into the "disk file"
                            diskErr = writeSD( bufferSD, &numWriBytes );
                            if ( numWriBytes < 32 )
                                diskErr = 19; // Reached an unexpected EOF
                            if ( ioByteCnt >= 511 ) {
                                // Finalize write operation and check result (if no previous error occurred)
                                if ( !diskErr )
                                    diskErr = writeSD( NULL, &numWriBytes );
                                ioOpcode = ioOpcodeUser;   // All done
                                ioByteCnt = ioByteCntUser; // Restore user context
                            }
                        }
                    }
                    ioByteCnt++; // Increment the counter of the exchanged data bytes
                    break;

                case OPC_SETBANK:
                    // BANKEDD RAM - NEED DOCUMENTATION OF EXTENDED RAM!
                    // SETBANK - select the Os RAM Bank (binary):
                    //
                    //                  I/O DATA:  D7 D6 D5 D4 D3 D2 D1 D0
                    //                            -----------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    Os Bank number (binary) [0..14]
                    //
                    //
                    // Set a 32kB RAM bank for the lower half of the Z80 address space (from 0x0000 to 0x7FFF).
                    // The upper half (from 0x8000 to 0xFFFF) is the common fixed bank.
                    // Allowed Os Bank numbers are from 0 to 14.
                    //
                    // Please note that there are three kinds of Bank numbers (see the A040618 schematic):
                    //
                    // * the "Os Bank" number is the bank number managed (known) by the Os;
                    // * the "Log Bank" number is the bank seen by the Atmega32a (through BK3..BK0 address lines);
                    // * the "Phy Bank" number is the real bank addressed inside the RAM chip (through A18..A15);
                    //
                    // Log and Phy Bank differ b/c A15 is inverted BK0 line (U1A)
                    // The following tables shows the relations:
                    //
                    //  Os Bank |  Logical Bank   | Z80 | Phys. RAM Addr. |            Notes
                    //  number  | BK3 BK2 BK1 BK0 | A15 | A18 A17 A16 A15 |
                    // ------------------------------------------------------------------------------------------------
                    //     X    |  X   X   X   X  |  1  |  0   0   0   1  |  Phy Bank  1 (common fixed)
                    //     -    |  0   0   0   0  |  0  |  0   0   0   1  |  Phy Bank  1 (common fixed)
                    //     0    |  0   0   0   1  |  0  |  0   0   0   0  |  Phy Bank  0 (Logical Bank  1)
                    //     1    |  0   0   1   1  |  0  |  0   0   1   0  |  Phy Bank  2 (Logical Bank  3)
                    //     2    |  0   0   1   0  |  0  |  0   0   1   1  |  Phy Bank  3 (Logical Bank  2)
                    //     3    |  0   1   0   1  |  0  |  0   1   0   0  |  Phy Bank  4 (Logical Bank  5)
                    //     4    |  0   1   0   0  |  0  |  0   1   0   1  |  Phy Bank  5 (Logical Bank  4)
                    //     5    |  0   1   1   1  |  0  |  0   1   1   0  |  Phy Bank  6 (Logical Bank  7)
                    //     6    |  0   1   1   0  |  0  |  0   1   1   1  |  Phy Bank  7 (Logical Bank  6)
                    //     7    |  1   0   0   1  |  0  |  1   0   0   0  |  Phy Bank  8 (Logical Bank  9)
                    //     8    |  1   0   0   0  |  0  |  1   0   0   1  |  Phy Bank  9 (Logical Bank  8)
                    //     9    |  1   0   1   1  |  0  |  1   0   1   0  |  Phy Bank 10 (Logical Bank 11)
                    //    10    |  1   0   1   0  |  0  |  1   0   1   1  |  Phy Bank 11 (Logical Bank 10)
                    //    11    |  1   1   0   1  |  0  |  1   1   0   0  |  Phy Bank 12 (Logical Bank 13
                    //    12    |  1   1   0   0  |  0  |  1   1   0   1  |  Phy Bank 13 (Logical Bank 12)
                    //    13    |  1   1   1   1  |  0  |  1   1   1   0  |  Phy Bank 14 (Logical Bank 15)
                    //    14    |  1   1   1   0  |  0  |  1   1   1   1  |  Phy Bank 15 (Logical Bank 14)
                    //
                    //
                    // Note that the Logical Bank 0 can't be used as switchable Os Bank because it is the common
                    //  fixed bank mapped in the upper half of the Z80 address space (from 0x8000 to 0xFFFF).
                    //
                    //
                    if ( ioData <= 14 ) { // no selection for Os Bank number greater than 14
                        uint8_t bank = ioData ? ioData + 1 : 0;
                        digitalWrite( BANK0, !( bank & 0x01 ) ); // BANK0 is inverted by U1A
                        digitalWrite( BANK1, bank & 0x02 );
                        if ( ramCfg > 0 )
                            digitalWrite( BANK2, bank & 0x04 );
                        if ( ramCfg > 1 )
                            digitalWrite( BANK3, bank & 0x08 );
                    }

                    break;


                case OPC_SETIRQ:
                    // SETIRQ - enable/disable the IRQ generation
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                              X  X  X  X  X  X  X  0    Serial Rx IRQ not enabled
                    //                              X  X  X  X  X  X  X  1    Serial Rx IRQ enabled
                    //                              X  X  X  X  X  X  0  X    Systick IRQ not enabled
                    //                              X  X  X  X  X  X  1  X    Systick IRQ enabled
                    //
                    //
                    // The INT_ signal is shared among various interrupt requests. This allows to use the simplified
                    //  Mode 1 scheme of the Z80 CPU (fixed jump to 0x0038 on INT_ signal active) with multiple interrupt causes.
                    //
                    // The SETIRQ purpose is to enable/disable the generation of an IRQ (using the INT_ signal)
                    //  selecting wich event you want enable.
                    //
                    // When a IRQ is enabled you have to serve it on the Z80 side with a ISR (Interrupt Service Routine).
                    //
                    // Inside the ISR code, you have to read the SYSIRQ Opcode to know the exact causes of the interrupt (see the
                    //  SYSIRQ Opcode) because multiple causes/bits could be active, so your ISR must be written to check and
                    //  serve them all.
                    //
                    // NOTE 1: Only D0 and D1 are currently used.
                    // NOTE 2: At reset time all the IRQ "triggers" (D7-D0) are normally disabled (unless they are enabled
                    //         for special boot cases).
                    //
                    // ...................................................................................
                    //
                    // Note about the Z80 CPU interrupt signal generation (INT_ signal):
                    //
                    // The current version of IOS is designed to use the Interrupt Mode 0, 1, 2 of the Z80 CPU (when enabled).
                    // Using this mode an occuring interrupt will cause:
                    // - IM0: Execution of the one-byte opcode (typical RSTnn) set with OPC_SETVECTOR (default RST 38).
                    // - IM1: A jump to the fixed address 0x0038.
                    // - IM2: A jump to the address retrieved from memory that is addressed by
                    //   256*REG_I + value set with OPC_SETVECTOR.
                    // Therefore to know wich kind of interrupt was triggered you need to use the SYSIRQ Opcode inside the
                    //  ISR and store the result (the SYSIRQ Opcode resets this IRQ flags after every call) to jump to the
                    //  needed serving sub-routines.
                    //
                    //
                    // Note about the Serial Rx interrupt signal generation (Z80 CPU):
                    //
                    // When enabled an interrupt is generated (INT_ signal LOW) when there is at least one character inside
                    //  the the serial RX buffer. When the Z80 CPU acknoledges the interrupt request an interrupt acknoledge bus
                    //  cycle is executed on the Z80 bus, and during this cycle the interrupt request signal is
                    //  reset (INT_ signal HIGH) by IOS.
                    // At this point no further serial RX interrupt will be activated until a following serial Rx read I/O
                    //  operation is executed by the Z80 CPU.
                    //
                    //
                    // Note about the Systick interrupt signal generation (Z80 CPU):
                    //
                    // When enabled an interrupt is generated (INT_ signal LOW) every a given amount of time (default is 100ms).
                    // To set/change the Systick time the SETTICK Opcode must be used.
                    // When the Systick interrupt is acknoledged by the Z80 CPU with an interrupt acknoledge bus cycle, the
                    //  interrupt request signal is reset (INT_ signal HIGH) by IOS.
                    //
                    //
                    // Note about the IOS Opcode calling sequence when interrupt signal generation is enabled:
                    //
                    // When interrupt is enabled care must be taken when calling IOS Opcodes as they must be considered as an
                    //  atomic action (calling an Opcode requires at least two I/O operations, where the first one is used to
                    //  set the operation code).
                    // To ensure safe Opcode calls inside the Z80 user code, no interrupt will be generated by IOS
                    //  between opcode setting (ioOpcode != 0xFF) and execution is finished (ioOpcode == 0xFF).
                    //
                    // ...................................................................................

                    Z80IntRx = ioData & 1;                        // Enable/disable the Systick IRQ generation
                    Z80IntSysTick = ( ioData & ( 1 << 1 ) ) >> 1; // Enable/disable the Serial Rx IRQ generation
                    break;

                case OPC_SETTICK:
                    // SETTICK - set the Systick timer time (milliseconds)
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    Systick time (binary) [1..255]
                    //
                    // Set/change the time (millisecond) used for the Systick timer.
                    // At reset time the default value is 100ms.
                    // See SETIRQ and SYSIRQ Opcodes for more info.
                    //
                    // NOTE: If the time is 0 milliseconds the set operation is ignored.

                    if ( ioData > 0 )
                        sysTickTime = ioData;
                    break;

                case OPC_SETOPT:
                    // SETOPT - set system options
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                              x  x  x  x  x  x  x  0    CP/M warm boot message disabled
                    //                              x  x  x  x  x  x  x  1    CP/M warm boot message enabled
                    //
                    // Set/change some system options (currently only D0 is defined).
                    // At reset time the default value for D0 is 0 (message disabled).
                    // The value of D0 can be read using the SYSFLAGS Opcode (bit D4).
                    //
                    // NOTE: The CP/M custom BIOS (CBIOS) must implement a read of the SYSFLAGS (bit D4) Opcode to switch on/off
                    //       the CP/M warm boot message display

                    cpmWarmBootFlg = ioData & 0x01;
                    break;

                case OPC_SETSPP:
                    // SPP EMULATION
                    // SETSPP - set the GPIO port into SPP mode:
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                              x  x  x  x  x  x  x  0    AUTOFD disabled
                    //                              x  x  x  x  x  x  x  1    AUTOFD enabled
                    //
                    // The SETSPP Opcode is used when an SPP Adapter board is connected to the GPIO port to work as
                    //  a Standard Parallel Port.
                    //
                    // The following actions are performed:
                    // - The SPP mode flag is set;
                    // - The GPIO port is set (direction and pullup) to operate as a SPP port;
                    // - The STROBE (active low) Control Line of the SPP port is set to High;
                    // - D0 is used to set the status of AUTOFD (active Low) Contro Line of the SPP port (AUTOFD = !D0);
                    // - The printer is initialized with a pulse on the INIT (active Low) Control line of the SPP port.
                    //
                    // GPIO port / SPP port signals table:
                    //
                    //                       GPIO Port |  SPP Port              | Dir
                    //                      -------------------------------------------
                    //                         GPA0    |  STROBE (active Low)   | Out
                    //                         GPA1    |  AUTOFD (active Low)   | Out
                    //                         GPA2    |  INIT (active Low)     | Out
                    //                         GPA3    |  ACK (active Low)      | In
                    //                         GPA4    |  BUSY (active High)    | In
                    //                         GPA5    |  PAPEREND (active High)| In
                    //                         GPA6    |  SELECT (active High)  | In
                    //                         GPA7    |  ERROR (active Low)    | In
                    //                         GPB0    |  D0                    | Out
                    //                         GPB1    |  D1                    | Out
                    //                         GPB2    |  D2                    | Out
                    //                         GPB3    |  D3                    | Out
                    //                         GPB4    |  D4                    | Out
                    //                         GPB5    |  D5                    | Out
                    //                         GPB6    |  D6                    | Out
                    //                         GPB7    |  D7                    | Out
                    //
                    // NOTE 1: When the GPIO is set to operate as an SPP port all the GPIO write Opcodes (GPIOA Write, GPIOB Write,
                    // IODIRA Write,
                    //         IODIRB Write, GPPUA Write, GPPUB Write) are ignored/disabled.
                    // NOTE 2: If the GPIO expansion module (GPE) is not found this Opcode is ignored.
                    // NOTE 3: When the SPP mode is activated cannot be disabled anymore (the only way is reset the board).

                    if ( moduleGPIO ) {                 // Only if GPE was found
                        SPPmode = 1;                    // Set the SPP mode flag
                        SPPautofd = ( !ioData ) & 0x01; // Store the value of the AUTOFD Control Line (active Low))

                        // Set STROBE and INIT at 1, and AUTOFD = !D0
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOA_REG );                             // Select GPIOA
                        Wire.write( 0b00000101 | (byte)( SPPautofd << 1 ) ); // Write value
                        Wire.endTransmission();

                        // Set the GPIO port to work as an SPP port (direction and pullup)
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( IODIRA_REG ); // Select IODIRA
                        Wire.write( 0b11111000 ); // Write value (1 = input, 0 = ouput)
                        Wire.endTransmission();
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( IODIRB_REG ); // Select IODIRB
                        Wire.write( 0b00000000 ); // Write value (1 = input, 0 = ouput)
                        Wire.endTransmission();
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPPUA_REG );  // Select GPPUA
                        Wire.write( 0b11111111 ); // Write value (1 = pullup enabled, 0 = pullup disabled)
                        Wire.endTransmission();

                        // Initialize the printer using a pulse on INIT
                        // NOTE: The I2C protocol introduces delays greater than needed by the SPP, so no further delay is used here
                        // to generate the pulse
                        tempByte = 0b00000001 | (byte)( SPPautofd << 1 ); // Change INIT bit to active (Low)
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOA_REG ); // Select GPIOA
                        Wire.write( tempByte );  // Set INIT bit to active (Low)
                        Wire.endTransmission();
                        tempByte = tempByte | 0b00000100; // Change INIT bit to not active (High)
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOA_REG ); // Select GPIOA
                        Wire.write( tempByte );  // Set INIT bit to not active (High)
                        Wire.endTransmission();
                    }
                    break;

                case OPC_WRSPP:
                    // SPP EMULATION
                    // WRSPP - send a byte to the printer attached to the SPP port:
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    byte to be sent to SPP
                    //
                    // If the SPP mode is enabled send a byte to the SPP. No check is done here to know if the printer is
                    //  ready or not, so you have to use the GETSPP Opcode before for that.
                    // If the SPP mode is disabled (or the GPE is not installed) this Opcode is ignored.
                    //
                    // NOTE: to use WRSPP the SETSPP Opcode should be called first to activate the SPP mode of the GPIO port.

                    if ( SPPmode ) { // Only if SPP mode is active
                        // NOTE: The I2C protocol introduces delays greater than needed by the SPP, so no further delay is used here
                        // to generate the pulse
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOB_REG ); // Select GPIOB
                        Wire.write( ioData );    // Data on GPIOB
                        Wire.endTransmission();
                        tempByte = 0b11111100 | (byte)( SPPautofd << 1 ); // Change STROBE bit to active (Low)
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOA_REG ); // Select GPIOA
                        Wire.write( tempByte );  // Set STROBE bit to active (Low)
                        Wire.endTransmission();
                        tempByte = tempByte | 0b00000001; // Change STROBE bit to not active (High)
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOA_REG ); // Select GPIOA
                        Wire.write( tempByte );  // Set STROBE bit to not active (High)
                        Wire.endTransmission();
                    }
                    break;

                case OPC_SETVECTOR:
                    // SETVECTOR - set the Interrupt Vector
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    IRQ vector
                    //
                    // Set the IRQ opcode (for IM0) or the IRQ vector (for IM2).
                    // At reset time the default value is RST_38H (0xFF).
                    //

                    intVector = ioData;
                    break;

                    // ------------------------------------------------------------------------------

                case OPC_SIOA_TXD:
                case OPC_SIOB_TXD:
                    // SIO TXD Write:
                    if ( moduleSIO )
                        SC16IS752_WriteByte( ioOpcode == OPC_SIOA_TXD ? 0 : 1, ioData );
                    break;

                case OPC_SIOA_CTRL:
                case OPC_SIOB_CTRL:
                    // SIO CTRL Write:
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            -------------------------
                    //                            |--HS-| 0 |--BaudIndex--|
                    //             no handshake:    0  0
                    //                 XON/XOFF:    0  1
                    //                  RTS/CTS:    1  0
                    //                 reserved:    1  1
                    //
                    if ( moduleSIO ) {
                        static uint8_t lastCTRL[ 2 ] = { 0xFF, 0xFF };
                        uint8_t channel = ioOpcode == OPC_SIOA_CTRL ? 0 : 1;
                        uint8_t handShake = ioData >> 6;
                        uint8_t baudIndex = ioData & 0x1F;
                        if ( verbosity > 1 ) {
                            Serial.printf( ioOpcode == OPC_SIOA_CTRL ? F( "??SIOA:" ) : F( "??SIOB:" ) );
                            Serial.printf( F( " set control: 0x%02X" ), ioData );
                        }
                        if ( baudIndex != ( lastCTRL[ channel ] & 0x1F ) ) { // baudrate has changed
                            if ( ( ioData & 0x1F ) < sizeof( cpmBaudRate ) / sizeof( uint16_t ) ) {
                                int32_t baudRate = cpmBaudRate[ ioData & 0x1F ]; // index to value
                                if ( verbosity > 1 )
                                    Serial.printf( F( " - baudrate: %ld\r\n" ), baudRate );
                                baudRate = SC16IS752_SetBaudrate( channel, baudRate );
                            }
                        }
                        if ( handShake != ( lastCTRL[ channel ] >> 6 ) ) { // HS has changed
                            // change handshake
                            if ( verbosity > 1 )
                                Serial.printf( F( " - handshake: %d " ), handShake );
                            switch ( handShake ) {
                            case 0:
                                if ( verbosity > 1 )
                                    Serial.printf( F( "disable\r\n" ) );
                                SC16IS752_SetAutoHandshake( channel, 0, 0 );
                                break;
                            case 1:
                                if ( verbosity > 1 )
                                    Serial.printf( F( "auto Xon/Xoff (NYI)\r\n" ) );
                                SC16IS752_SetAutoHandshake( channel, 0, 0 );
                                break;
                            case 2:
                                if ( verbosity > 1 )
                                    Serial.printf( F( "auto RTS/CTS\r\n" ) );
                                SC16IS752_SetAutoHandshake( channel, 1, 1 );
                                break;
                            case 3:
                                if ( verbosity > 1 )
                                    Serial.printf( F( "reserved\r\n" ) );
                                break;
                            }
                        }
                        lastCTRL[ channel ] = ioData;
                    }
                    break;

                case OPC_SET_VERBOSITY:
                    // set verbosity byte, also used for NMOS/CMOS CPU test
                    verbosity = ioData;
                    break;
                } // switch ( ioOpcode )
                if ( ( ioOpcode != OPC_SELTRACK ) && ( ioOpcode != OPC_WRITESECT ) ) {
                    ioOpcode = ioOpcodeUser;   // All done for the single byte Opcodes
                    ioByteCnt = ioByteCntUser; // Restore user context
                }
            }

            // Control bus sequence to exit from a wait state (M I/O write cycle)
            digitalWrite( BUSREQ_, LOW );    // Request for a DMA
            digitalWrite( WAIT_RES_, LOW );  // Reset WAIT FF exiting from WAIT state
            digitalWrite( WAIT_RES_, HIGH ); // Now Z80 is in DMA, so it's safe set WAIT_RES_ HIGH again
            digitalWrite( BUSREQ_, HIGH );   // Resume Z80 from DMA

        } else if ( !digitalRead( RD_ ) ) {
            // I/O READ operation requested

            // ----------------------------------------
            // VIRTUAL I/O READ OPERATIONS ENGINE
            // ----------------------------------------

            ioAddress = digitalRead( AD0 ); // Read Z80 address bus line AD0 (PC2)
            ioData = 0;                     // Clear input data buffer
            if ( ioAddress ) {              // Check the I/O address (only AD0 is checked!)
                // .........................................................................................................
                //
                // AD0 = 1 (I/O read address = 0x01). SERIAL RX.
                //
                // Execute a Serial I/O Read operation.
                // .........................................................................................................
                //
                //
                // SERIAL RX:
                //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                //                            ---------------------------------------------------------
                //                             D7 D6 D5 D4 D3 D2 D1 D0    ASCII char read from serial
                //
                // NOTE 1: If there is no input char, a value 0xFF is forced as input char.
                // NOTE 2: The INT_ signal is always reset (set to HIGH) after this I/O operation.
                // NOTE 3: This is the only I/O that do not require any previous STORE Opcode operation (for fast polling).
                // NOTE 4: A "RX buffer empty" flag and a "Last Rx char was empty" flag are available in the SYSFLAG Opcode
                //         to allow 8 bit I/O.

                //
                // DEBUG ----------------------------------
                if ( verbosity > 1 ) {
                    Serial.println();
                    Serial.print( F( "DEBUG: SER RX" ) );
                    Serial.print( F( " - irqStatus = " ) );
                    Serial.println( irqStatus );
                }
                // DEBUG END ------------------------------
                //

                ioData = 0xFF;
                if ( Serial.available() > 0 ) {
                    ioData = Serial.read();
                    LastRxIsEmpty = 0; // Reset the "Last Rx char was empty" flag
                } else
                    LastRxIsEmpty = 1;             // Set the "Last Rx char was empty" flag
                digitalWrite( INT_, HIGH );        // Reset the INT_ signal (if used)
                irqStatus = irqStatus & B11111110; // Reset the serial Rx IRQ status bit (see SYSIRQ Opcode)
                RxDoneFlag = 1;
            } else {
                // .........................................................................................................
                //
                // AD0 = 0 (I/O read address = 0x00). EXECUTE READ Opcode.
                //
                // Execute the previously stored I/O read operation with the current data.
                // The code of the I/O operation (Opcode) must be previously stored with a STORE Opcode operation.
                //
                // NOTE: For multi-byte read Opcode (as DATETIME) read sequentially all the data bytes without to send
                //       a STORE Opcode operation before each data byte after the first one.
                // .........................................................................................................
                //
                switch ( ioOpcode ) {
                    // Execute the requested I/O READ Opcode. The 0xFF value is reserved as "No operation".
                case OPC_USER_KEY:
                    // USER KEY:
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                              0  0  0  0  0  0  0  0    USER Key not pressed
                    //                              0  0  0  0  0  0  0  1    USER Key pressed

                    tempByte = digitalRead( USER ); // Save USER led status
                    pinMode( USER, INPUT_PULLUP );  // Read USER Key
                    ioData = !digitalRead( USER );
                    pinMode( USER, OUTPUT );
                    digitalWrite( USER, tempByte ); // Restore USER led status
                    break;

                case OPC_GPIOA_READ:
                    // GPIOA Read (GPE Option):
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    GPIOA value (see MCP23017 datasheet)
                    //
                    // NOTE: a value 0x00 is forced if the GPE Option is not present

                    if ( moduleGPIO ) {
                        // Set MCP23017 pointer to GPIOA
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOA_REG );
                        Wire.endTransmission();
                        // Read GPIOA
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.requestFrom( GPIOEXP_ADDR, 1 );
                        ioData = Wire.read();
                    }
                    break;

                case OPC_GPIOB_READ:
                    // GPIOB Read (GPE Option):
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    GPIOB value (see MCP23017 datasheet)
                    //
                    // NOTE: a value 0x00 is forced if the GPE Option is not present

                    if ( moduleGPIO ) {
                        // Set MCP23017 pointer to GPIOB
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOB_REG );
                        Wire.endTransmission();
                        // Read GPIOB
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.requestFrom( GPIOEXP_ADDR, 1 );
                        ioData = Wire.read();
                    }
                    break;

                case OPC_SYSFLAGS:
                    // SYSFLAGS (Various system flags for the OS):
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                              X  X  X  X  X  X  X  0    AUTOEXEC not enabled
                    //                              X  X  X  X  X  X  X  1    AUTOEXEC enabled
                    //                              X  X  X  X  X  X  0  X    DS3231 RTC not found
                    //                              X  X  X  X  X  X  1  X    DS3231 RTC found
                    //                              X  X  X  X  X  0  X  X    Serial RX buffer empty
                    //                              X  X  X  X  X  1  X  X    Serial RX char available
                    //                              X  X  X  X  0  X  X  X    Previous RX char valid
                    //                              X  X  X  X  1  X  X  X    Previous RX char was a "buffer empty" flag
                    //                              X  X  X  0  X  X  X  X    CP/M warm boot message disabled
                    //                              X  X  X  1  X  X  X  X    CP/M warm boot message enabled
                    //
                    // NOTE 1: Currently only D0-D4,D6,D7 are used
                    // NOTE 2: The D4 flag is set/reset using the D0 bit of the SETOPT Opcode (see SETOPT for more info)
                    //                              0  0  X  X  X  X  X  X    RAM: 128kBytes
                    //                              0  1  X  X  X  X  X  X    RAM: 256kBytes
                    //                              1  0  X  X  X  X  X  X    RAM: 512kBytes
                    // Note 3: D6-D7 assigned to represent RAM-size

                    ioData = autoexecFlag | ( foundRTC << 1 ) | ( ( Serial.available() > 0 ) << 2 ) |
                             ( ( LastRxIsEmpty > 0 ) << 3 ) | ( cpmWarmBootFlg << 4 | ( ramCfg << 6 ) );
                    break;

                case OPC_DATETIME:
                    // DATETIME (Read date/time and temperature from the RTC. Binary values):
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                I/O DATA 0   D7 D6 D5 D4 D3 D2 D1 D0    seconds [0..59]     (1st data byte)
                    //                I/O DATA 1   D7 D6 D5 D4 D3 D2 D1 D0    minutes [0..59]
                    //                I/O DATA 2   D7 D6 D5 D4 D3 D2 D1 D0    hours   [0..23]
                    //                I/O DATA 3   D7 D6 D5 D4 D3 D2 D1 D0    day     [1..31]
                    //                I/O DATA 4   D7 D6 D5 D4 D3 D2 D1 D0    month   [1..12]
                    //                I/O DATA 5   D7 D6 D5 D4 D3 D2 D1 D0    year    [0..99]
                    //                I/O DATA 6   D7 D6 D5 D4 D3 D2 D1 D0    tempC   [-128..127] (7th data byte)
                    //
                    // NOTE 1: If RTC is not found all read values wil be = 0
                    // NOTE 2: Overread data (more then 7 bytes read) will be = 0
                    // NOTE 3: The temperature (Celsius) is a byte with two complement binary format [-128..127]

                    if ( foundRTC ) {
                        if ( ioByteCnt == 0 )
                            readRTC( &seconds, &minutes, &hours, &day, &month, &year, &tempC ); // Read from RTC
                        if ( ioByteCnt < 7 ) {
                            // Send date/time (binary values) to Z80 bus
                            switch ( ioByteCnt ) {
                            case 0:
                                ioData = seconds;
                                break;
                            case 1:
                                ioData = minutes;
                                break;
                            case 2:
                                ioData = hours;
                                break;
                            case 3:
                                ioData = day;
                                break;
                            case 4:
                                ioData = month;
                                break;
                            case 5:
                                ioData = year;
                                break;
                            case 6:
                                ioData = tempC;
                                break;
                            }
                            ioByteCnt++;
                        } else {
                            ioOpcode = ioOpcodeUser;   // All done
                            ioByteCnt = ioByteCntUser; // Restore user context
                        }
                    } else {
                        ioOpcode = ioOpcodeUser;   // Nothing to do
                        ioByteCnt = ioByteCntUser; // Restore user context
                    }
                    break;

                case OPC_ERRDISK:
                    // DISK EMULATION
                    // ERRDISK - read the error code after a SELDISK, SELSECT, SELTRACK, WRITESECT, READSECT
                    //           or SDMOUNT operation
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    DISK error code (binary)
                    //
                    //
                    // Error codes table:
                    //
                    //    error code    | description
                    // ---------------------------------------------------------------------------------------------------
                    //        0         |  No error
                    //        1         |  DISK_ERR: the function failed due to a hard error in the disk function,
                    //                  |   a wrong FAT structure or an internal error
                    //        2         |  NOT_READY: the storage device could not be initialized due to a hard error or
                    //                  |   no medium
                    //        3         |  NO_FILE: could not find the file
                    //        4         |  NOT_OPENED: the file has not been opened
                    //        5         |  NOT_ENABLED: the volume has not been mounted
                    //        6         |  NO_FILESYSTEM: there is no valid FAT partition on the drive
                    //       16         |  Illegal disk number
                    //       17         |  Illegal track number
                    //       18         |  Illegal sector number
                    //       19         |  Reached an unexpected EOF
                    //
                    //
                    //
                    //
                    // NOTE 1: ERRDISK code is referred to the previous SELDISK, SELSECT, SELTRACK, WRITESECT or READSECT
                    //         operation
                    // NOTE 2: Error codes from 0 to 6 come from the PetitFS library implementation
                    // NOTE 3: ERRDISK must not be used to read the resulting error code after a SDMOUNT operation
                    //         (see the SDMOUNT Opcode)

                    ioData = diskErr;
                    break;

                case OPC_READSECT:
                    // DISK EMULATION
                    // READSECT - read 512 data bytes sequentially from the current emulated disk/track/sector:
                    //
                    //                 I/O DATA:   D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                 I/O DATA 0  D7 D6 D5 D4 D3 D2 D1 D0    First Data byte
                    //
                    //                      |               |
                    //                      |               |
                    //                      |               |                 <510 Data Bytes>
                    //                      |               |
                    //
                    //               I/O DATA 127  D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    512th Data byte (Last byte)
                    //
                    //
                    // Reads the current sector (512 bytes) of the current track/sector, one data byte each call.
                    // All the 512 calls must be always performed sequentially to have a READSECT operation correctly done.
                    // If an error occurs during the READSECT operation, all subsequent read data will be = 0.
                    // If an error occurs calling any DISK EMULATION Opcode (SDMOUNT excluded) immediately before the READSECT
                    //  Opcode call, all the read data will be will be = 0 and the READSECT operation will not be performed.
                    // Errors are stored into "diskErr" (see ERRDISK Opcode).
                    //
                    // NOTE 1: Before a READSECT operation at least a SELTRACK or a SELSECT must be always performed
                    // NOTE 2: Remember to open the right "disk file" at first using the SELDISK Opcode

                    if ( !ioByteCnt ) {
                        // First byte of 512, so set the right file pointer to the current emulated track/sector first
                        if ( ( trackSel < 512 ) && ( sectSel < 32 ) && ( !diskErr ) ) {
                            // Sector and track numbers valid and no previous error; set the LBA-like logical sector
                            diskErr = seekSD( ( trackSel << 5 ) | sectSel ); // Set the starting point inside the "disk file"
                                                                             //  generating a 14 bit "disk file" LBA-like
                                                                             //  logical sector address created as TTTTTTTTTSSSSS
                        }
                    }
                    if ( !diskErr ) {
                        // No previous error (e.g. selecting disk, track or sector)
                        tempByte = ioByteCnt % 32; // [0..31]
                        if ( !tempByte ) {
                            // Read 32 bytes of the current sector on SD in the buffer (every 32 calls, starting with the first)
                            diskErr = readSD( bufferSD, &numReadBytes );
                            if ( numReadBytes < 32 )
                                diskErr = 19; // Reached an unexpected EOF
                        }
                        if ( !diskErr )
                            ioData = bufferSD[ tempByte ]; // If no errors, exchange current data byte with the CPU
                    }
                    if ( ioByteCnt >= 511 ) {
                        ioOpcode = ioOpcodeUser;   // All done
                        ioByteCnt = ioByteCntUser; // Restore user context
                    }
                    ioByteCnt++; // Increment the counter of the exchanged data bytes
                    break;

                case OPC_SDMOUNT:
                    // DISK EMULATION
                    // SDMOUNT - mount a volume on SD, returning an error code (binary):
                    //
                    //                 I/O DATA 0: D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    error code (binary)
                    //
                    //
                    //
                    // NOTE 1: This Opcode is "normally" not used. Only needed if using a virtual disk from a custom program
                    //         loaded with iLoad or with the Autoboot mode (e.g. ViDiT). Can be used to handle SD hot-swapping
                    // NOTE 2: For error codes explanation see ERRDISK Opcode
                    // NOTE 3: Only for this disk Opcode, the resulting error is read as a data byte without using the
                    //         ERRDISK Opcode

                    ioData = mountSD( &filesysSD );
                    break;

                case OPC_ATXBUFF:
                    // ATXBUFF - return the current available free space (in bytes) in the TX buffer:
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    free space in bytes (binary)
                    //
                    // NOTE: This Opcode is intended to avoid delays in serial Tx operations, as the IOS holds the Z80
                    //       in a wait status if the TX buffer is full. This is no good in multitasking enviroments.

                    iSize = Serial.availableForWrite();
                    ioData = iSize > 255 ? 255 : iSize;
                    break;

                case OPC_SYSIRQ:
                    // SYSIRQ - return the "interrupt status byte":
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                              X  X  X  X  X  X  X  0    Serial Rx IRQ not set
                    //                              X  X  X  X  X  X  X  1    Serial Rx IRQ set
                    //                              X  X  X  X  X  X  0  X    Systick IRQ not set
                    //                              X  X  X  X  X  X  1  X    Systick IRQ set
                    //
                    //
                    // The INT_ signal is shared among various interrupt requests. This allows to use the simplified
                    //  Mode 1 scheme of the Z80 CPU (fixed jump to 0x0038 on INT_ signal active) with multiple interrupt
                    //  causes.
                    // The SYSIRQ purpose is to allow the Z80 CPU to know the exact causes of the occurred interrupts
                    //  reading the "interrupt status byte" that contains up to eight "interrupt status bits".
                    // So the ISR (Interrupt Service Routine) should be structured to read at first the
                    //  "interrupt status byte" using the SYSIRQ Opcode, and than execute the needed actions before
                    //  return to the normal execution.
                    // Note that multiple causes/bits could be active.
                    //
                    //
                    //
                    // NOTE 1: Only D0 and D1 "interrupt status bit" are currently used.
                    // NOTE 2: After the SYSIRQ call all the "interrupt status bits" are cleared.
                    // NOTE 3: If more than one IRQ trigger is enabled, you have to call SYSIRQ always from inside the
                    //         ISR (on the Z80 side) to know the triggered IRQs.

                    ioData = irqStatus;
                    irqStatus = 0; // Reset all the "interrupt status bits"

                    //
                    // DEBUG ----------------------------------
                    if ( verbosity > 1 ) {
                        Serial.println();
                        Serial.print( F( "DEBUG: SYSIRQ" ) );
                        Serial.print( F( " - ioData = " ) );
                        Serial.println( ioData );
                    }
                    // DEBUG END ------------------------------
                    //

                    break;

                case OPC_GETSPP:
                    // SPP EMULATION
                    // GETSPP - read the Status Lines of the SPP Port and the SPP emulation status:
                    //
                    //                  I/O DATA:  D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                              0  0  0  0  0  0  0  0    SPP emulation disabled
                    //                             D7 D6 D5 D4 D3  0  0  1    SPP emulation enabled
                    //
                    //                  bit  | SPP Status line
                    //                  ----------------------------------
                    //                   D0  | 1 (SPP emulation enabled)
                    //                   D1  | 0 (not used)
                    //                   D2  | 0 (not used)
                    //                   D3  | ACK (active Low)
                    //                   D4  | BUSY (active High)
                    //                   D5  | PAPEREND (active High)
                    //                   D6  | SELECT (active High)
                    //                   D7  | ERROR (active Low)
                    //
                    // If the SPP mode is enabled read the SPP Status Lines.
                    // If the SPP mode is disabled (or the GPE is not installed) a byte of all 0s will be retrivied.
                    //
                    // NOTE: to use GETSPP the SETSPP Opcode should be called first to activate the SPP mode of the GPIO port.

                    if ( SPPmode ) {
                        // Set MCP23017 pointer to GPIOA
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.write( GPIOA_REG );
                        Wire.endTransmission();

                        // Read GPIOA (SPP Status Lines)
                        Wire.beginTransmission( GPIOEXP_ADDR );
                        Wire.requestFrom( GPIOEXP_ADDR, 1 );
                        ioData = Wire.read();
                        ioData = ( ioData & 0b11111000 ) | 0b00000001; // Set D0 = 1, D1 = D2 = 0
                    }
                    break;

                case OPC_ARXBUFF:
                    // ARXBUFF - return the current available char (in bytes) in the RX buffer:
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            ---------------------------------------------------------
                    //                             D7 D6 D5 D4 D3 D2 D1 D0    available char in bytes (binary)
                    //
                    // NOTE: This Opcode is intended to speed up serial Rx operations.
                    //       No need to query the status for every read.

                    iSize = Serial.available();
                    ioData = iSize > 255 ? 255 : iSize;
                    break;

                case OPC_SIOA_RXD:
                case OPC_SIOB_RXD:
                    // SIOA RXD Read:
                    // NOTE: a value 0x1A is forced if the SIO Option is not present
                    if ( moduleSIO )
                        ioData = SC16IS752_ReadByte( ioOpcode == OPC_SIOA_RXD ? 0 : 1 );
                    else
                        ioData = 0x1A; // ^Z (EOF)
                    break;

                case OPC_SIOA_RXSTAT:
                case OPC_SIOB_RXSTAT:
                    // SIO Rx Status Read:
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            -------------------------
                    //                              0 | FIFO DATA AVAIL  |
                    //
                    // NOTE: a value 0x40 is forced if the SIO Option is not present
                    if ( moduleSIO ) {
                        ioData = SC16IS752_RxDataAvailable( ioOpcode == OPC_SIOA_RXSTAT ? 0 : 1 );
                    } else
                        ioData = 0x40; // RxFIFO full - USED BY CP/M CHARIO.MAC
                    break;

                case OPC_SIOA_TXSTAT:
                case OPC_SIOB_TXSTAT:
                    // SIO Tx Status Read:
                    //
                    //                I/O DATA:    D7 D6 D5 D4 D3 D2 D1 D0
                    //                            -------------------------
                    //                              0 | FIFO SPACE AVAIL |
                    //
                    // NOTE: a value 0x40 is forced if the SIO Option is not present
                    if ( moduleSIO ) {
                        ioData = SC16IS752_TxSpaceAvailable( ioOpcode == OPC_SIOA_TXSTAT ? 0 : 1 );
                    } else
                        ioData = 0x40; // Tx FIFO empty - USED BY CP/M CHARIO.MAC
                    break;

                case OPC_GET_VERBOSITY:
                    // read back verbosity byte, also used for NMOS/CMOS CPU test
                    ioData = verbosity;
                    break;
                } // switch ( ioOpcode )
                if ( ( ioOpcode != OPC_DATETIME ) && ( ioOpcode != OPC_READSECT ) ) {
                    ioOpcode = ioOpcodeUser;   // All done for the single byte Opcodes
                    ioByteCnt = ioByteCntUser; // Restore user context
                }
            } // EXECUTE READ Opcode

            DDRA = 0xFF;    // Configure Z80 data bus D0-D7 (PA0-PA7) as output
            PORTA = ioData; // Current output on data bus

            // Control bus sequence to exit from a wait state (M I/O read cycle)
            digitalWrite( BUSREQ_, LOW );   // Request for a DMA
            digitalWrite( WAIT_RES_, LOW ); // Now is safe reset WAIT FF (exiting from WAIT state)
            delayMicroseconds( 2 );         // Wait 2us just to be sure that Z80 read the data and go HiZ
            DDRA = 0x00;                    // Configure Z80 data bus D0-D7 (PA0-PA7) as input with pull-up
            PORTA = 0xFF;
            digitalWrite( WAIT_RES_, HIGH ); // Now Z80 is in DMA (HiZ), so it's safe set WAIT_RES_ HIGH again
            digitalWrite( BUSREQ_, HIGH );   // Resume Z80 from DMA

        } else { // neither /WR nor /RD -> /IORQ & /M1
            // INTERRUPT operation setting IORQ_ LOW

            // ----------------------------------------
            // VIRTUAL INTERRUPT
            // ----------------------------------------

            digitalWrite( INT_, HIGH ); // Reset the INT_ signal

            //
            // DEBUG ----------------------------------
            if ( verbosity > 1 ) {
                Serial.println();
                Serial.print( F( "DEBUG: INT ACK cycle" ) );
                Serial.print( F( " - irqStatus = " ) );
                Serial.println( irqStatus );
            }
            // DEBUG END ------------------------------
            //

            DDRA = 0xFF;       // Configure Z80 data bus D0-D7 (PA0-PA7) as output
            PORTA = intVector; // Output RSTx or low part of int vector
                               // Set intVector with IOS function 0x13

            // Control bus sequence to exit from a wait state (M interrupt cycle)
            digitalWrite( BUSREQ_, LOW );   // Request for a DMA
            digitalWrite( WAIT_RES_, LOW ); // Reset WAIT FF exiting from WAIT state
            delayMicroseconds( 2 );         // Wait 2us just to be sure that Z80 read the data and go HiZ
            DDRA = 0x00;                    // Configure Z80 data bus D0-D7 (PA0-PA7) as input with pull-up
            PORTA = 0xFF;
            digitalWrite( WAIT_RES_, HIGH ); // Now Z80 is in DMA, so it's safe set WAIT_RES_ HIGH again
            digitalWrite( BUSREQ_, HIGH );   // Resume Z80 from DMA
        } // neither /WR nor /RD -> /IORQ & /M1
    } // if ( !digitalRead( WAIT_ ) )

    if ( ioOpcode == OPC_NO_OP ) { // Z80 INT trigger only if outside opcode processing
        if ( Z80IntRx ) {
            // Set INT_ to ACTIVE if there are received chars from serial to read
            // and if the interrupt generation is enabled and a previous serial Rx was done by the Z80 CPU
            if ( serEventSeen && RxDoneFlag && ( Serial.available() > 0 ) ) {
                digitalWrite( INT_, LOW );
                irqStatus = irqStatus | B00000001; // Set the serial Rx IRQ status bit (see SYSIRQ Opcode)
                RxDoneFlag = 0;
                serEventSeen = 0;
            }
        }
        if ( Z80IntSysTick ) {
            // Systick interrupt generation is enabled. Check if the INT_ signal must be activated
            if ( ( micros() - timeStamp ) > ( (long unsigned)( sysTickTime ) * 1000 ) ) {
                // <sysTickTime> milliseconds are elapsed, so a Systick interrupt is required
                digitalWrite( INT_, LOW );
                irqStatus = irqStatus | B00000010; // Set the Systick IRQ status bit (see SYSIRQ Opcode)
                timeStamp = micros();
            }
        }
    }
} // void loop()


// ------------------------------------------------------------------------------

// Generic routines

// ------------------------------------------------------------------------------


byte findChar( char c, const char *a ) {
    // check if the char c is found in array a
    // return position + 1 if found, else 0
    byte pos = 1;
    while ( *a ) {
        if ( *a == c )
            return pos;
        ++a;
        ++pos;
    }
    return 0;
}

// ------------------------------------------------------------------------------

void printBinaryByte( byte value ) {
    for ( byte mask = 0x80; mask; mask >>= 1 ) {
        Serial.print( ( mask & value ) ? '1' : '0' );
    }
}

// ------------------------------------------------------------------------------

void printMsg1() { Serial.println( F( "\r\nPress CR to accept, ESC to exit or any other key to change" ) ); }

// ------------------------------------------------------------------------------

void serialEvent() {
    // set marker to trigger a RX INT in main loop
    serEventSeen = 1;
}

// ------------------------------------------------------------------------------

void WaitAndBlink( baudRecCheck baudRecSwitch ) {
    // Wait for a char from the serial port while IOS led blinks and do the Baud Recovery if requested.
    // If <baudRecSwitch> = CHECK the User key is checked if it remains pressed at least 3 seconds ("long User key pressed"
    // event).
    // In this happens the Baud Recovery procedure is done if the current serial speed is different from the default
    // value (115200).
    // When the Baud Recovery procedure is executed the serial port speed is set at the default value (115200) and both
    // the USER and IOS leds blink quickly. The default serial port speed will be effective after the next reset.

    byte UserKeyLongPressed = 1;     // Flag for the "User key long pressed" event
    static unsigned long timeStamp1; // Timestamps
    unsigned long timeStamp2;

    timeStamp2 = millis();
    while ( !Serial.available() ) {
        if ( ( millis() - timeStamp2 ) < 3000 ) {
            // Check is User key remains pressed for 3s more
            pinMode( USER, INPUT_PULLUP ); // Set read mode for USER key
            if ( digitalRead( USER ) )
                UserKeyLongPressed = 0; // Clear the flag if USER key was released at least once before 3s
            pinMode( USER, OUTPUT );    // Set write mode for USER led
            delay( 10 );                // Just to dimm USER led up to fade off
        }
        if ( ( millis() - timeStamp1 ) > 300 ) {
            // Blink IOS led
            digitalWrite( LED_IOS, !digitalRead( LED_IOS ) );
            timeStamp1 = millis();
        }
        if ( ( ( millis() - timeStamp2 ) > 3000 ) && ( UserKeyLongPressed ) && ( baudRecSwitch = CHECK ) &&
             ( EEPROM.read( serBaudAddr ) != 9 ) ) {
            // Do the Baud Recovery procedure.
            // The User key was pressed for at least 3s and the serial port speed is different from default value (115200),
            // so set the default baud rate (115200) for the serial port and wait for a reboot while both IOS and USER leds
            // blink quickly.
            digitalWrite( LED_IOS, LOW );
            EEPROM.update( serBaudAddr, 9 ); // Set the default baud rate (115200)
            Serial.println( F( "\r\n\nIOS: Baud recovery done - Please reboot now!" ) );
            while ( 1 ) {
                if ( ( millis() - timeStamp1 ) > 100 ) {
                    digitalWrite( LED_IOS, !digitalRead( LED_IOS ) );
                    digitalWrite( USER, !digitalRead( USER ) );
                    timeStamp1 = millis();
                }
            }
        }
    }
}

// ------------------------------------------------------------------------------

unsigned long indexToBaud( byte speedIndex ) {
    // Convert the serial port index speed value to the real baud value.
    // If the index value is not valid, it will be assumed the default speed of 115200 baud.
    unsigned long baud;
    switch ( speedIndex ) {
    case 0:
        baud = 600;
        break;
    case 1:
        baud = 1200;
        break;
    case 2:
        baud = 2400;
        break;
    case 3:
        baud = 4800;
        break;
    case 4:
        baud = 9600;
        break;
    case 5:
        baud = 19200;
        break;
    case 6:
        baud = 28800;
        break;
    case 7:
        baud = 38400;
        break;
    case 8:
        baud = 57600;
        break;
    default:
        baud = 115200;
        break;
    }
    return baud;
}


// ------------------------------------------------------------------------------

// RTC Module routines

// ------------------------------------------------------------------------------


byte decToBcd( byte val ) {
    // Convert a binary byte to a two digits BCD byte
    return ( ( val / 10 * 16 ) + ( val % 10 ) );
}

// ------------------------------------------------------------------------------

byte bcdToDec( byte val ) {
    // Convert binary coded decimal to normal decimal numbers
    return ( ( val / 16 * 10 ) + ( val % 16 ) );
}

// ------------------------------------------------------------------------------

void readRTC( byte *second, byte *minute, byte *hour, byte *day, byte *month, byte *year, byte *tempC ) {
    // Read current date/time binary values and the temprerature (2 complement) from the DS3231 RTC
    byte i;
    Wire.beginTransmission( DS3231_RTC );
    Wire.write( DS3231_SECRG ); // Set the DS3231 Seconds Register
    Wire.endTransmission();
    // Read from RTC and convert to binary
    Wire.requestFrom( DS3231_RTC, 18 );
    *second = bcdToDec( Wire.read() & 0x7f );
    *minute = bcdToDec( Wire.read() );
    *hour = bcdToDec( Wire.read() & 0x3f );
    Wire.read(); // Jump over the DoW
    *day = bcdToDec( Wire.read() );
    *month = bcdToDec( Wire.read() );
    *year = bcdToDec( Wire.read() );
    for ( i = 0; i < 10; i++ )
        Wire.read(); // Jump over 10 registers
    *tempC = Wire.read();
}

// ------------------------------------------------------------------------------

void writeRTC( byte second, byte minute, byte hour, byte day, byte month, byte year ) {
    // Write given date/time binary values to the DS3231 RTC
    (void)second;
    (void)minute;
    (void)hour;
    Wire.beginTransmission( DS3231_RTC );
    Wire.write( DS3231_SECRG ); // Set the DS3231 Seconds Register
    Wire.write( decToBcd( seconds ) );
    Wire.write( decToBcd( minutes ) );
    Wire.write( decToBcd( hours ) );
    Wire.write( 1 ); // Day of week not used (always set to 1 = Sunday)
    Wire.write( decToBcd( day ) );
    Wire.write( decToBcd( month ) );
    Wire.write( decToBcd( year ) );
    Wire.endTransmission();
}

// ------------------------------------------------------------------------------

byte autoSetRTC() {
    // Check if the DS3231 RTC is present and set the date/time at compile date/time if
    // the RTC "Oscillator Stop Flag" is set (= date/time failure).
    // Return value: 0 if RTC not present, 1 if found.
    byte OscStopFlag;

    Wire.beginTransmission( DS3231_RTC );
    if ( Wire.endTransmission() != 0 )
        return 0; // RTC not found
    Serial.print( F( "IOS: Found RTC DS3231 Module (" ) );
    printDateTime( 1 );
    Serial.println( ")" );

    // Print the temperaturefrom the RTC sensor
    Serial.printf( F( "IOS: RTC DS3231 temperature sensor: %d°C\r\n" ), (int8_t)tempC );

    // Read the "Oscillator Stop Flag"
    Wire.beginTransmission( DS3231_RTC );
    Wire.write( DS3231_STATRG ); // Set the DS3231 Status Register
    Wire.endTransmission();
    Wire.requestFrom( DS3231_RTC, 1 );
    OscStopFlag = Wire.read() & 0x80; // Read the "Oscillator Stop Flag"

    if ( OscStopFlag ) {
        // RTC oscillator stopped. RTC must be set at compile date/time
        // Convert compile time strings to numeric values
        seconds = compTimeStr.substring( 6, 8 ).toInt();
        minutes = compTimeStr.substring( 3, 5 ).toInt();
        hours = compTimeStr.substring( 0, 2 ).toInt();
        day = compDateStr.substring( 4, 6 ).toInt();
        switch ( compDateStr[ 0 ] ) {
        case 'J':
            month = compDateStr[ 1 ] == 'a' ? 1 : compDateStr[ 2 ] == 'n' ? 6 : 7;
            break;
        case 'F':
            month = 2;
            break;
        case 'A':
            month = compDateStr[ 2 ] == 'r' ? 4 : 8;
            break;
        case 'M':
            month = compDateStr[ 2 ] == 'r' ? 3 : 5;
            break;
        case 'S':
            month = 9;
            break;
        case 'O':
            month = 10;
            break;
        case 'N':
            month = 11;
            break;
        case 'D':
            month = 12;
            break;
        };
        year = compDateStr.substring( 9, 11 ).toInt();

        // Ask for RTC setting al compile date/time
        Serial.println( F( "IOS: RTC clock failure!" ) );
        Serial.print( F( "\nDo you want set RTC at IOS compile time (" ) );
        printDateTime( 0 );
        Serial.print( F( ")? [Y/N] >" ) );
        do {
            WaitAndBlink( BLK );
            inChar = Serial.read();
        } while ( ( inChar != 'y' ) && ( inChar != 'Y' ) && ( inChar != 'n' ) && ( inChar != 'N' ) );
        Serial.println( inChar );

        // Set the RTC at the compile date/time and print a message
        if ( ( inChar == 'y' ) || ( inChar == 'Y' ) ) {
            writeRTC( seconds, minutes, hours, day, month, year );
            Serial.print( F( "IOS: RTC set at compile time - Now: " ) );
            printDateTime( 1 );
            Serial.println();
        }

        // Reset the "Oscillator Stop Flag"
        Wire.beginTransmission( DS3231_RTC );
        Wire.write( DS3231_STATRG ); // Set the DS3231 Status Register
        Wire.write( 0x08 );          // Reset the "Oscillator Stop Flag" (32KHz output left enabled)
        Wire.endTransmission();
    }
    return 1;
}

// ------------------------------------------------------------------------------

void printDateTime( byte readSourceFlag ) {
    // Print to serial the current date/time from the global variables.
    //
    // Flag readSourceFlag [0..1] usage:
    //    If readSourceFlag = 0 the RTC read is not done
    //    If readSourceFlag = 1 the RTC read is done (global variables are updated)
    if ( readSourceFlag )
        readRTC( &seconds, &minutes, &hours, &day, &month, &year, &tempC );
    Serial.print( "20" );
    print2digit( year );
    Serial.print( "-" );
    print2digit( month );
    Serial.print( "-" );
    print2digit( day );
    Serial.print( " " );
    print2digit( hours );
    Serial.print( ":" );
    print2digit( minutes );
    Serial.print( ":" );
    print2digit( seconds );
}

// ------------------------------------------------------------------------------

void print2digit( byte data ) {
    // Print a byte [0..99] using 2 digit with leading zeros if needed
    if ( data < 10 )
        Serial.print( "0" );
    Serial.print( data );
}

// ------------------------------------------------------------------------------

byte isLeapYear( byte yearXX ) {
    // Check if the year 2000+XX (where XX is the argument yearXX [00..99]) is a leap year.
    // Returns 1 if it is leap, 0 otherwise.
    // This function works in the [2000..2099] years range. It should be enough...
    if ( ( ( 2000 + yearXX ) % 4 ) == 0 )
        return 1;
    else
        return 0;
}

// ------------------------------------------------------------------------------

void ChangeRTC() {
    // Change manually the RTC Date/Time from keyboard
    // byte    leapYear;   //  Set to 1 if the selected year is bissextile, 0 otherwise [0..1]

    // Read RTC
    readRTC( &seconds, &minutes, &hours, &day, &month, &year, &tempC );

    // Change RTC date/time from keyboard
    tempByte = 0;
    Serial.println( F( "\nIOS: RTC manual setting:" ) );
    Serial.println( F( "\nPress T/U to increment +10/+1 or CR to accept" ) );
    do {
        do {
            Serial.print( F( " " ) );
            switch ( tempByte ) {
            case 0:
                Serial.print( F( "Year -> " ) );
                print2digit( year );
                break;

            case 1:
                Serial.print( F( "Month -> " ) );
                print2digit( month );
                break;

            case 2:
                Serial.print( F( "             " ) );
                Serial.write( 13 );
                Serial.print( F( " Day -> " ) );
                print2digit( day );
                break;

            case 3:
                Serial.print( F( "Hours -> " ) );
                print2digit( hours );
                break;

            case 4:
                Serial.print( F( "Minutes -> " ) );
                print2digit( minutes );
                break;

            case 5:
                Serial.print( F( "Seconds -> " ) );
                print2digit( seconds );
                break;
            }

            do {
                WaitAndBlink( BLK );
                inChar = Serial.read();
            } while ( ( inChar != 'u' ) && ( inChar != 'U' ) && ( inChar != 't' ) && ( inChar != 'T' ) && ( inChar != 13 ) );

            if ( ( inChar == 'u' ) || ( inChar == 'U' ) )
                // Change units
                switch ( tempByte ) {
                case 0:
                    year++;
                    if ( year > 99 )
                        year = 0;
                    break;

                case 1:
                    month++;
                    if ( month > 12 )
                        month = 1;
                    break;

                case 2:
                    day++;
                    if ( month == 2 ) {
                        if ( day > ( daysOfMonth[ month - 1 ] + isLeapYear( year ) ) )
                            day = 1;
                    } else {
                        if ( day > ( daysOfMonth[ month - 1 ] ) )
                            day = 1;
                    }
                    break;

                case 3:
                    hours++;
                    if ( hours > 23 )
                        hours = 0;
                    break;

                case 4:
                    minutes++;
                    if ( minutes > 59 )
                        minutes = 0;
                    break;

                case 5:
                    seconds++;
                    if ( seconds > 59 )
                        seconds = 0;
                    break;
                }
            if ( ( inChar == 't' ) || ( inChar == 'T' ) )
                // Change tens
                switch ( tempByte ) {
                case 0:
                    year = year + 10;
                    if ( year > 99 )
                        year = year - ( year / 10 ) * 10;
                    break;

                case 1:
                    if ( month > 10 )
                        month = month - 10;
                    else if ( month < 3 )
                        month = month + 10;
                    break;

                case 2:
                    day = day + 10;
                    if ( day > ( daysOfMonth[ month - 1 ] + isLeapYear( year ) ) )
                        day = day - ( day / 10 ) * 10;
                    if ( day == 0 )
                        day = 1;
                    break;

                case 3:
                    hours = hours + 10;
                    if ( hours > 23 )
                        hours = hours - ( hours / 10 ) * 10;
                    break;

                case 4:
                    minutes = minutes + 10;
                    if ( minutes > 59 )
                        minutes = minutes - ( minutes / 10 ) * 10;
                    break;

                case 5:
                    seconds = seconds + 10;
                    if ( seconds > 59 )
                        seconds = seconds - ( seconds / 10 ) * 10;
                    break;
                }
            Serial.write( 13 );
        } while ( inChar != 13 );
        tempByte++;
    } while ( tempByte < 6 );

    // Write new date/time into the RTC
    writeRTC( seconds, minutes, hours, day, month, year );
    Serial.println( F( " ...done      \n" ) );
    Serial.print( F( "IOS: RTC date/time updated (" ) );
    printDateTime( 1 );
    Serial.println( ")" );
}


// ------------------------------------------------------------------------------

// Z80 bootstrap routines

// ------------------------------------------------------------------------------


void pulseClock( byte numPulse ) {
    // Generate <numPulse> clock pulses on the Z80 clock pin.
    // The steady clock level is LOW, e.g. one clock pulse is a 0-1-0 transition
    byte i;
    for ( i = 0; i < numPulse; i++ ) {
        // Generate one clock pulse
        // Send one impulse (0-1-0) on the CLK output
        digitalWrite( CLK, HIGH );
        digitalWrite( CLK, LOW );
    }
}

// ------------------------------------------------------------------------------

void loadByteToRAM( byte value ) {
    // Load a given byte to RAM using a sequence of two Z80 instructions forced on the data bus.
    // The RAM_CE2 signal is used to force the RAM in HiZ, so the Atmega can write the needed instruction/data
    //  on the data bus. Controlling the clock signal and knowing exactly how many clocks pulse are required it
    //  is possible control the whole loading process.
    // In the following "T" are the T-cycles of the Z80 (See the Z80 datashet).
    // The two instruction are "LD (HL), n" and "INC (HL)".


    // Execute the LD(HL),n instruction (T = 4+3+3). See the Z80 datasheet and manual.
    // After the execution of this instruction the <value> byte is loaded in the memory address pointed by HL.
    pulseClock( 1 );                                       // Execute the T1 cycle of M1 (Instruction Fetch machine cycle)
    digitalWrite( RAM_CE2, ( ramCfg == 2 ? HIGH : LOW ) ); // Force the RAM in HiZ (CE2 = LOW for ram <512K)
    DDRA = 0xFF;                                           // Configure Z80 data bus D0-D7 (PA0-PA7) as output
    PORTA = LD_HL;                                         // Write "LD (HL), n" instruction on data bus
    pulseClock( 2 );                                       // Execute T2 and T3 cycles of M1
    DDRA = 0x00;                                           // Configure Z80 data bus D0-D7 (PA0-PA7) as input...
    PORTA = 0xFF;                                          // ...with pull-up
    pulseClock( 2 );                                       // Complete the execution of M1 and execute the T1 cycle of the following
                                                           // Memory Read machine cycle
    DDRA = 0xFF;                                           // Configure Z80 data bus D0-D7 (PA0-PA7) as output
    PORTA = value;                                         // Write the byte to load in RAM on data bus
    pulseClock( 2 );                                       // Execute the T2 and T3 cycles of the Memory Read machine cycle
    DDRA = 0x00;                                           // Configure Z80 data bus D0-D7 (PA0-PA7) as input...
    PORTA = 0xFF;                                          // ...with pull-up
    digitalWrite( RAM_CE2, ( ramCfg == 2 ? LOW : HIGH ) ); // Enable the RAM again (CE2 = HIGH for ram <512K)
    pulseClock( 3 );                                       // Execute all the following Memory Write machine cycle

    // Execute the INC(HL) instruction (T = 6). See the Z80 datasheet and manual.
    // After the execution of this instruction HL points to the next memory address.
    pulseClock( 1 );                                       // Execute the T1 cycle of M1 (Instruction Fetch machine cycle)
    digitalWrite( RAM_CE2, ( ramCfg == 2 ? HIGH : LOW ) ); // Force the RAM in HiZ (CE2 = LOW for ram <512K)
    DDRA = 0xFF;                                           // Configure Z80 data bus D0-D7 (PA0-PA7) as output
    PORTA = INC_HL;                                        // Write "INC(HL)" instruction on data bus
    pulseClock( 2 );                                       // Execute T2 and T3 cycles of M1
    DDRA = 0x00;                                           // Configure Z80 data bus D0-D7 (PA0-PA7) as input...
    PORTA = 0xFF;                                          // ...with pull-up
    digitalWrite( RAM_CE2, ( ramCfg == 2 ? LOW : HIGH ) ); // Enable the RAM again (CE2 = HIGH for ram <512K)
    pulseClock( 3 );                                       // Execute all the remaining T cycles
}

// ------------------------------------------------------------------------------

void loadHL( word value ) {
    // Load "value" word into the HL registers inside the Z80 CPU, using the "LD HL,nn" instruction.
    // In the following "T" are the T-cycles of the Z80 (See the Z80 datashet).
    // Execute the LD dd,nn instruction (T = 4+3+3), with dd = HL and nn = value. See the Z80 datasheet and manual.
    // After the execution of this instruction the word "value" (16bit) is loaded into HL.
    pulseClock( 1 );                                   // Execute the T1 cycle of M1 (Instruction Fetch machine cycle)
    digitalWrite( RAM_CE2, ramCfg == 2 ? HIGH : LOW ); // Force the RAM in HiZ (CE2 = LOW for ram <512K)
    DDRA = 0xFF;                                       // Configure Z80 data bus D0-D7 (PA0-PA7) as output
    PORTA = LD_HLnn;                                   // Write "LD HL, n" instruction on data bus
    pulseClock( 2 );                                   // Execute T2 and T3 cycles of M1
    DDRA = 0x00;                                       // Configure Z80 data bus D0-D7 (PA0-PA7) as input...
    PORTA = 0xFF;                                      // ...with pull-up
    pulseClock( 2 );                                   // Complete the execution of M1 and execute the T1 cycle of the following
                                                       // Memory Read machine cycle
    DDRA = 0xFF;                                       // Configure Z80 data bus D0-D7 (PA0-PA7) as output
    PORTA = lowByte( value );                          // Write first byte of "value" to load in HL
    pulseClock( 3 );                                   // Execute the T2 and T3 cycles of the first Memory Read machine cycle
                                                       // and T1, of the second Memory Read machine cycle
    PORTA = highByte( value );                         // Write second byte of "value" to load in HL
    pulseClock( 2 );                                   // Execute the T2 and T3 cycles of the second Memory Read machine cycle
    DDRA = 0x00;                                       // Configure Z80 data bus D0-D7 (PA0-PA7) as input...
    PORTA = 0xFF;                                      // ...with pull-up
    digitalWrite( RAM_CE2, ramCfg == 2 ? LOW : HIGH ); // Enable the RAM again (CE2 = HIGH for ram <512K)
}

// ------------------------------------------------------------------------------

void singlePulsesResetZ80() {
    // Reset the Z80 CPU using single pulses clock
    digitalWrite( RESET_, LOW );  // Set RESET_ active
    pulseClock( 6 );              // Generate twice the needed clock pulses to reset the Z80
    digitalWrite( RESET_, HIGH ); // Set RESET_ not active
    pulseClock( 2 );              // Needed two more clock pulses after RESET_ goes HIGH
}


// ------------------------------------------------------------------------------

// SD Disk routines (FAT16 and FAT32 filesystems supported) using the PetitFS library.
// For more info about PetitFS see here: http://elm-chan.org/fsw/ff/00index_p.html

// ------------------------------------------------------------------------------


byte mountSD( FATFS *fatFs ) {
    // Mount a volume on SD:
    // *  "fatFs" is a pointer to a FATFS object (PetitFS library)
    // The returned value is the resulting status (0 = ok, otherwise see printErrSD())
    return pf_mount( fatFs );
}

// ------------------------------------------------------------------------------

byte openSD( const char *fileName ) {
    // Open an existing file on SD:
    // *  "fileName" is the pointer to the string holding the file name (8.3 format)
    // The returned value is the resulting status (0 = ok, otherwise see printErrSD())
    return pf_open( fileName );
}

// ------------------------------------------------------------------------------

byte readSD( void *buffSD, byte *numReadBytes ) {
    // Read one "segment" (32 bytes) starting from the current sector (512 bytes) of the opened file on SD:
    // *  "BuffSD" is the pointer to the segment buffer;
    // *  "numReadBytes" is the pointer to the variables that store the number of read bytes;
    //     if < 32 (including = 0) an EOF was reached).
    // The returned value is the resulting status (0 = ok, otherwise see printErrSD())
    //
    // NOTE1: Each SD sector (512 bytes) is divided into 16 segments (32 bytes each); to read a sector you need to
    //        to call readSD() 16 times consecutively
    //
    // NOTE2: Past current sector boundary, the next sector will be pointed. So to read a whole file it is sufficient
    //        call readSD() consecutively until EOF is reached

    UINT numBytes;
    byte errcode;
    errcode = pf_read( buffSD, 32, &numBytes );
    *numReadBytes = (byte)numBytes;
    return errcode;
}

// ------------------------------------------------------------------------------

byte writeSD( void *buffSD, byte *numWrittenBytes ) {
    // Write one "segment" (32 bytes) starting from the current sector (512 bytes) of the opened file on SD:
    // *  "BuffSD" is the pointer to the segment buffer;
    // *  "numWrittenBytes" is the pointer to the variables that store the number of written bytes;
    //     if < 32 (including = 0) an EOF was reached.
    // The returned value is the resulting status (0 = ok, otherwise see printErrSD())
    //
    // NOTE1: Each SD sector (512 bytes) is divided into 16 segments (32 bytes each); to write a sector you need to
    //        to call writeSD() 16 times consecutively
    //
    // NOTE2: Past current sector boundary, the next sector will be pointed. So to write a whole file it is sufficient
    //        call writeSD() consecutively until EOF is reached
    //
    // NOTE3: To finalize the current write operation a writeSD(NULL, &numWrittenBytes) must be called as last action

    UINT numBytes;
    byte errcode;
    if ( buffSD != NULL ) {
        errcode = pf_write( buffSD, 32, &numBytes );
    } else {
        errcode = pf_write( 0, 0, &numBytes );
    }
    *numWrittenBytes = (byte)numBytes;
    return errcode;
}

// ------------------------------------------------------------------------------

byte seekSD( word sectNum ) {
    // Set the pointer of the current sector for the current opened file on SD:
    // *  "sectNum" is the sector number to set. First sector is 0.
    // The returned value is the resulting status (0 = ok, otherwise see printErrSD())
    //
    // NOTE: "secNum" is in the range [0..16383], and the sector addressing is continuos inside a "disk file";
    //       16383 = (512 * 32) - 1, where 512 is the number of emulated tracks, 32 is the number of emulated sectors
    //

    // byte i;
    return pf_lseek( ( (unsigned long)sectNum ) << 9 );
}

// ------------------------------------------------------------------------------

void printErrSD( byte opType, byte errCode, const char *fileName ) {
    // Print the error occurred during a SD I/O operation:
    //  * "OpType" is the operation that generated the error (0 = mount, 1= open, 2 = read,
    //     3 = write, 4 = seek);
    //  * "errCode" is the error code from the PetitFS library (0 = no error);
    //  * "fileName" is the pointer to the file name or NULL (no file name)
    //
    // ........................................................................
    //
    // Errors legend (from PetitFS library) for the implemented operations:
    //
    // ------------------
    // mountSD():
    // ------------------
    // NOT_READY
    //     The storage device could not be initialized due to a hard error or no medium.
    // DISK_ERR
    //     An error occured in the disk read function.
    // NO_FILESYSTEM
    //     There is no valid FAT partition on the drive.
    //
    // ------------------
    // openSD():
    // ------------------
    // NO_FILE
    //     Could not find the file.
    // DISK_ERR
    //     The function failed due to a hard error in the disk function, a wrong FAT structure or an internal error.
    // NOT_ENABLED
    //     The volume has not been mounted.
    //
    // ------------------
    // readSD() and writeSD():
    // ------------------
    // DISK_ERR
    //     The function failed due to a hard error in the disk function, a wrong FAT structure or an internal error.
    // NOT_OPENED
    //     The file has not been opened.
    // NOT_ENABLED
    //     The volume has not been mounted.
    //
    // ------------------
    // seekSD():
    // ------------------
    // DISK_ERR
    //     The function failed due to an error in the disk function, a wrong FAT structure or an internal error.
    // NOT_OPENED
    //     The file has not been opened.
    //
    // ........................................................................

    if ( errCode ) {
        Serial.print( F( "\r\nIOS: SD error " ) );
        Serial.print( errCode );
        Serial.print( " (" );
        switch ( errCode ) {
            // See PetitFS implementation for the codes

        case 1:
            Serial.print( F( "DISK_ERR" ) );
            break;
        case 2:
            Serial.print( F( "NOT_READY" ) );
            break;
        case 3:
            Serial.print( F( "NO_FILE" ) );
            break;
        case 4:
            Serial.print( F( "NOT_OPENED" ) );
            break;
        case 5:
            Serial.print( F( "NOT_ENABLED" ) );
            break;
        case 6:
            Serial.print( F( "NO_FILESYSTEM" ) );
            break;
        default:
            Serial.print( F( "UNKNOWN" ) );
        }
        Serial.print( F( " on " ) );
        switch ( opType ) {
        case 0:
            Serial.print( F( "MOUNT" ) );
            break;
        case 1:
            Serial.print( F( "OPEN" ) );
            break;
        case 2:
            Serial.print( F( "READ" ) );
            break;
        case 3:
            Serial.print( F( "WRITE" ) );
            break;
        case 4:
            Serial.print( F( "SEEK" ) );
            break;
        default:
            Serial.print( F( "UNKNOWN" ) );
        }
        Serial.print( F( " operation" ) );
        if ( fileName ) {
            // Not a NULL pointer, so print file name too
            Serial.print( F( " - File: " ) );
            Serial.print( fileName );
        }
        Serial.println( ")" );
    }
}

// ------------------------------------------------------------------------------

void waitKey() {
    // Wait a key to continue
    while ( Serial.available() > 0 )
        Serial.read(); // Flush serial Rx buffer
    Serial.println( F( "IOS: Check SD and press a key to repeat\r\n" ) );
    while ( Serial.available() < 1 )
        ;
}

// ------------------------------------------------------------------------------

void printOsName( byte currentDiskSet ) {
    // Print the current Disk Set number and the OS name, if it is defined.
    // The OS name is inside the file defined in DS_OSNAME

    Serial.print( "Disk Set " );
    Serial.print( currentDiskSet );
    OsName[ 2 ] = currentDiskSet + 48; // Set the Disk Set
    openSD( OsName );                  // Open file with the OS name
    readSD( bufferSD, &numReadBytes ); // Read the OS name
    if ( numReadBytes > 0 ) {
        // Print the OS name
        Serial.print( " (" );
        Serial.print( (const char *)bufferSD );
        Serial.print( ")" );
    }
}


// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------


// Helper function to convert hex char to 4-bit value
static uint8_t hexCharToVal(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return 0; // Invalid character
}

// Helper function to convert two hex chars to byte
static uint8_t hexToByte(const char* hex) {
    return (hexCharToVal(hex[0]) << 4) | hexCharToVal(hex[1]);
}

// Main function to process Intel Hex from Serial
void loadIntelHex() {

    char lineBuffer[100];
    uint8_t lineIndex = 0;
    bool inLine = false;

    Serial.printf( F( "Waiting HEX input stream...\r\n" ) );

    while (true) {
        // Wait for serial data
        while (!Serial.available()) {
            delay(1);
        }

        char c = Serial.read();

        // Start of ihex line
        if (c == ':') {
            inLine = true;
            lineIndex = 0;
            continue;
        }

        // End of line
        if (c == '\n' || c == '\r') {
            if ( inLine && lineIndex > 0 ) {
                lineBuffer[ lineIndex ] = '\0';
                Serial.println( lineBuffer );
                if ( processHexLine( lineBuffer ) ) {
                    return; // EOF reached
                }
            }
            inLine = false;
            lineIndex = 0;
            continue;
        }

        // Accumulate line characters
        if (inLine && lineIndex < sizeof(lineBuffer) - 1) {
            lineBuffer[lineIndex++] = c;
        }
        // Ignore characters outside ihex lines
    }
}


// Validate checksum and process data bytes
static bool processHexLine( const char* hexLine ) {
    static uint16_t startAddress = 0xFFFF;

    uint8_t len = hexToByte( hexLine ); // Byte count
    uint16_t addr = ( (uint16_t)hexToByte( hexLine + 2 ) << 8) | hexToByte( hexLine + 4 );
    uint8_t type = hexToByte( hexLine + 6 );
    // Calculate checksum
    uint8_t calcChecksum = len + ( addr >> 8 ) + ( addr & 0xFF ) + type;
    uint8_t dataChecksum = 0;

    // Process data bytes if type is 00 (data record)
    if (type == 0x00) {
        if ( addr < startAddress )
            startAddress = addr;
        loadHL( addr );
        // Process each data byte
        for ( uint8_t i = 0; i < len; i++ ) {
            uint8_t dataByte = hexToByte( hexLine + 8 + i * 2 );
            loadByteToRAM( dataByte );
            calcChecksum += dataByte;
        }
    }
    else if (type == 0x01) {
        // End of file record
        Serial.printf( F( "Start address: 0x%04X\r\n" ), startAddress );
        BootStrAddr = startAddress;
        return true; // ready
    }
    else {
        // Other record types (extended address, etc.)
        // Handle if needed
        Serial.printf( F( "Record type: 0x%02X\r\n" ), type );
        dataChecksum = hexToByte( hexLine + 8 + len * 2 );
    }

    // Complete checksum calculation (two's complement)
    calcChecksum = (~calcChecksum + 1) & 0xFF;
    dataChecksum = hexToByte(hexLine + 8 + len * 2);
    if (calcChecksum != dataChecksum)
        Serial.printf( F( "Checksum error: calc=0x%02X, got=0x%02X\r\n" ),
            calcChecksum, dataChecksum );

    return false; // not yet done
}



// End of known world for this code - Hic Sunt Leones!
