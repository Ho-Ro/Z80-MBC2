/* 
SC16IS752 driver for Arduino
*/


#ifndef _SC16IS752_H_
#define _SC16IS752_H_

#include <Wire.h>

//Device 8 bit Address

//A:VDD
//B:GND
//C:SCL
//D:SDA
#define   SC16IS752_ADDRESS_AA   (0X90)
#define   SC16IS752_ADDRESS_AB   (0X92)
#define   SC16IS752_ADDRESS_AC   (0X94)
#define   SC16IS752_ADDRESS_AD   (0X96)
#define   SC16IS752_ADDRESS_BA   (0X98)
#define   SC16IS752_ADDRESS_BB   (0X9A)
#define   SC16IS752_ADDRESS_BC   (0X9C)
#define   SC16IS752_ADDRESS_BD   (0X9E)
#define   SC16IS752_ADDRESS_CA   (0XA0)
#define   SC16IS752_ADDRESS_CB   (0XA2)
#define   SC16IS752_ADDRESS_CC   (0XA4)
#define   SC16IS752_ADDRESS_CD   (0XA6)
#define   SC16IS752_ADDRESS_DA   (0XA8)
#define   SC16IS752_ADDRESS_DB   (0XAA)
#define   SC16IS752_ADDRESS_DC   (0XAC)
#define   SC16IS752_ADDRESS_DD   (0XAE)

// use 7 bit address
#define   SC16IS752_ADDRESS      (SC16IS752_ADDRESS_AA >> 1)

//General Registers
#define   SC16IS752_REG_RHR       (0x00)
#define   SC16IS752_REG_THR       (0X00)
#define   SC16IS752_REG_IER       (0X01)
#define   SC16IS752_REG_FCR       (0X02)
#define   SC16IS752_REG_IIR       (0X02)
#define   SC16IS752_REG_LCR       (0X03)
#define   SC16IS752_REG_MCR       (0X04)
#define   SC16IS752_REG_LSR       (0X05)
#define   SC16IS752_REG_MSR       (0X06)
#define   SC16IS752_REG_SPR       (0X07)
#define   SC16IS752_REG_TCR       (0X06)
#define   SC16IS752_REG_TLR       (0X07)
#define   SC16IS752_REG_TXLVL     (0X08)
#define   SC16IS752_REG_RXLVL     (0X09)
#define   SC16IS752_REG_IODIR     (0X0A)
#define   SC16IS752_REG_IOSTATE   (0X0B)
#define   SC16IS752_REG_IOINTENA  (0X0C)
#define   SC16IS752_REG_IOCONTROL (0X0E)
#define   SC16IS752_REG_EFCR      (0X0F)

//Special Registers
#define   SC16IS752_REG_DLL       (0x00)
#define   SC16IS752_REG_DLH       (0X01)

//Enhanced Registers
#define   SC16IS752_REG_EFR       (0X02)
#define   SC16IS752_REG_XON1      (0X04)
#define   SC16IS752_REG_XON2      (0X05)
#define   SC16IS752_REG_XOFF1     (0X06)
#define   SC16IS752_REG_XOFF2     (0X07)

//Interrupt Enable Register
#define   SC16IS752_INT_CTS       (0X80)
#define   SC16IS752_INT_RTS       (0X40)
#define   SC16IS752_INT_XOFF      (0X20)
#define   SC16IS752_INT_SLEEP     (0X10)
#define   SC16IS752_INT_MODEM     (0X08)
#define   SC16IS752_INT_LINE      (0X04)
#define   SC16IS752_INT_THR       (0X02)
#define   SC16IS752_INT_RHR       (0X01)

//Application Related

#define   SC16IS752_CRYSTAL_FREQ (1843200UL)

#define   SC16IS752_DEBUG_PRINT  (1)

#define   SC16IS752_CHANNEL_A    0x00
#define   SC16IS752_CHANNEL_B    0x01
#define   SC16IS752_CHANNEL_BOTH 0x00

#define   SC16IS752_DEFAULT_SPEED  1200



// ------------------------------------------------------------------------------

// SC16IS752 I2C SIO routines

// ------------------------------------------------------------------------------


void SC16IS752_Init(uint32_t baud_A, uint32_t baud_B);

void SC16IS752_WriteByte(uint8_t channel, uint8_t val);

int SC16IS752_ReadByte(uint8_t channel);

int16_t SC16IS752_SetBaudrate(uint8_t channel, uint16_t baudrate); // return baudrate

void SC16IS752_SetLine(uint8_t channel, uint8_t data_length, uint8_t parity_select, uint8_t stop_length );

void SC16IS752_FIFOEnable(uint8_t channel, uint8_t fifo_enable);

uint8_t SC16IS752_FIFOAvailableData(uint8_t channel);

uint8_t SC16IS752_FIFOAvailableSpace(uint8_t channel);

void SC16IS752_ResetDevice();

uint8_t SC16IS752_Ping();

uint8_t SC16IS752_ReadRegister(uint8_t channel, uint8_t reg_addr);

void SC16IS752_WriteRegister(uint8_t channel, uint8_t reg_addr, uint8_t val);







#endif
