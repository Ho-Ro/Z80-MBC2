/*
SC16IS752 driver for Arduino
*/


//#define SC16IS752_DEBUG_PRINT
#include "sc16is752.h"

extern byte verbosity;

// ------------------------------------------------------------------------------

// SC16IS752 I2C SIO routines

// ------------------------------------------------------------------------------


void SC16IS752_Init(uint32_t baud_A, uint32_t baud_B) {
  SC16IS752_ResetDevice();
  SC16IS752_FIFOEnable(SC16IS752_CHANNEL_A, 1);
  SC16IS752_FIFOEnable(SC16IS752_CHANNEL_B, 1);
  SC16IS752_SetBaudrate(SC16IS752_CHANNEL_A, baud_A);
  SC16IS752_SetBaudrate(SC16IS752_CHANNEL_B, baud_B);
  SC16IS752_SetLine(SC16IS752_CHANNEL_A, 8, 0, 1);
  SC16IS752_SetLine(SC16IS752_CHANNEL_B, 8, 0, 1);
}


void SC16IS752_WriteByte(uint8_t channel, uint8_t val) {
  uint8_t tmp_lsr;
/*
  while ( SC16IS752_FIFOAvailableSpace(channel) == 0 ){
    if ( verbosity ) {
    Serial.println(F("?SIO: No available space"));
    }
  };
*/
  do {
    tmp_lsr = SC16IS752_ReadRegister(channel, SC16IS752_REG_LSR);
  } while ((tmp_lsr&0x20) == 0);  // THR not empty

  SC16IS752_WriteRegister(channel, SC16IS752_REG_THR, val);
}


int SC16IS752_ReadByte(uint8_t channel) {
  volatile uint8_t val;
  if (SC16IS752_FIFOAvailableData(channel) == 0) {
    if ( verbosity ) {
      Serial.println(F("?SIO: No data available"));
    }
    return -1;
  }

  if ( verbosity ) {
    Serial.println(F("?SIO: ***********Data available***********"));
  }
  val = SC16IS752_ReadRegister(channel, SC16IS752_REG_RHR);
  return val;
}


int16_t SC16IS752_SetBaudrate(uint8_t channel, uint16_t baudrate) { // return baudrate
  uint16_t divisor;
  uint8_t prescaler;
  uint16_t actual_baudrate;
  uint8_t temp_lcr;
  if ( (SC16IS752_ReadRegister(channel, SC16IS752_REG_MCR)&0x80) == 0) // prescaler==1
    prescaler = 1;
  else
    prescaler = 4;

  divisor = SC16IS752_CRYSTAL_FREQ / 16 / prescaler / baudrate;
  temp_lcr = SC16IS752_ReadRegister(channel, SC16IS752_REG_LCR);
  temp_lcr |= 0x80;
  SC16IS752_WriteRegister(channel, SC16IS752_REG_LCR, temp_lcr);
  //write to DLL
  SC16IS752_WriteRegister(channel, SC16IS752_REG_DLL, (uint8_t)divisor);
  //write to DLH
  SC16IS752_WriteRegister(channel, SC16IS752_REG_DLH, (uint8_t)(divisor>>8));
  temp_lcr &= 0x7F;
  SC16IS752_WriteRegister(channel, SC16IS752_REG_LCR, temp_lcr);

  actual_baudrate = SC16IS752_CRYSTAL_FREQ / prescaler / 16 / divisor;
  if ( verbosity ) {
    Serial.print(F("?SIO: Desired baudrate: "));
    Serial.println(baudrate,DEC);
    Serial.print(F("?SIO: Calculated divisor: "));
    Serial.println(divisor,DEC);
    Serial.print(F("?SIO: Actual baudrate: "));
    Serial.println(actual_baudrate,DEC);
  }
  return actual_baudrate;
}


void SC16IS752_SetLine(uint8_t channel, uint8_t data_length, uint8_t parity_select, uint8_t stop_length ) {
  uint8_t temp_lcr;
  temp_lcr = SC16IS752_ReadRegister(channel, SC16IS752_REG_LCR);
  temp_lcr &= 0xC0; //Clear the lower six bit of LCR (LCR[0] to LCR[5]

  switch (data_length) {  //data length settings
  case 5:
    break;
  case 6:
    temp_lcr |= 0x01;
    break;
  case 7:
    temp_lcr |= 0x02;
    break;
  case 8:
    temp_lcr |= 0x03;
    break;
  default:
    temp_lcr |= 0x03;
    break;
  }

  if ( stop_length == 2 ) {
    temp_lcr |= 0x04;
  }

  //parity selection length settings
  switch (parity_select) {
  case 0: //no parity
    break;
  case 1: //odd parity
    temp_lcr |= 0x08;
    break;
  case 2: //even parity
    temp_lcr |= 0x18;
    break;
  case 3: //force '1' parity
    temp_lcr |= 0x03;
    break;
  case 4: //force '0' parity
    break;
  default:
    break;
  }

  if ( verbosity ) {
    Serial.print(F("?SIO: LCR Register:0x"));
    Serial.println(temp_lcr,DEC);
  }

  SC16IS752_WriteRegister(channel, SC16IS752_REG_LCR,temp_lcr);
}


void SC16IS752_FIFOEnable(uint8_t channel, uint8_t fifo_enable) {
  uint8_t temp_fcr = SC16IS752_ReadRegister(channel, SC16IS752_REG_FCR);

  if (fifo_enable == 0){
    temp_fcr &= 0xFE;
  } else {
    temp_fcr |= 0x01;
  }
  SC16IS752_WriteRegister(channel, SC16IS752_REG_FCR, temp_fcr);
  return;
}


uint8_t SC16IS752_FIFOAvailableData(uint8_t channel) {
  if ( verbosity ) {
    Serial.print(F("?SIO: =====Available data:"));
    Serial.println(SC16IS752_ReadRegister(channel, SC16IS752_REG_RXLVL), DEC);
  }
  return SC16IS752_ReadRegister(channel, SC16IS752_REG_RXLVL);
//  return SC16IS752_ReadRegister(channel, SC16IS752_REG_LSR) & 0x01;
}


uint8_t SC16IS752_FIFOAvailableSpace(uint8_t channel) {
  return SC16IS752_ReadRegister(channel, SC16IS752_REG_TXLVL);
}


void SC16IS752_ResetDevice() {
  uint8_t reg;

  reg = SC16IS752_ReadRegister(SC16IS752_CHANNEL_BOTH, SC16IS752_REG_IOCONTROL);
  reg |= 0x08;
  SC16IS752_WriteRegister(SC16IS752_CHANNEL_BOTH, SC16IS752_REG_IOCONTROL, reg);

  return;
}


uint8_t SC16IS752_Ping() {
  SC16IS752_WriteRegister(SC16IS752_CHANNEL_A, SC16IS752_REG_SPR,0x55);
  if (SC16IS752_ReadRegister(SC16IS752_CHANNEL_A, SC16IS752_REG_SPR) !=0x55) {
    return 0;
  }

  SC16IS752_WriteRegister(SC16IS752_CHANNEL_A, SC16IS752_REG_SPR,0xAA);
  if (SC16IS752_ReadRegister(SC16IS752_CHANNEL_A, SC16IS752_REG_SPR) !=0xAA) {
    return 0;
  }

  SC16IS752_WriteRegister(SC16IS752_CHANNEL_B, SC16IS752_REG_SPR,0x55);
  if (SC16IS752_ReadRegister(SC16IS752_CHANNEL_B, SC16IS752_REG_SPR) !=0x55) {
    return 0;
  }

  SC16IS752_WriteRegister(SC16IS752_CHANNEL_B, SC16IS752_REG_SPR,0xAA);
  if (SC16IS752_ReadRegister(SC16IS752_CHANNEL_B, SC16IS752_REG_SPR) !=0xAA) {
    return 0;
  }

  return 1;
}


uint8_t SC16IS752_ReadRegister(uint8_t channel, uint8_t reg_addr) {
  uint8_t result;
  Wire.beginTransmission(SC16IS752_ADDRESS);
  Wire.write((reg_addr<<3 | channel<<1));
  Wire.endTransmission(0);
  Wire.requestFrom(SC16IS752_ADDRESS, 1);
  result = Wire.read();

  if ( verbosity ) {
    Serial.print(F("?SIO: ReadRegister channel="));
    Serial.print(channel,HEX);
    Serial.print(F(" reg_addr="));
    Serial.print((reg_addr<<3 | channel<<1),HEX);
    Serial.print(F(" result="));
    Serial.println(result,HEX);
  }
  return result;
}


void SC16IS752_WriteRegister(uint8_t channel, uint8_t reg_addr, uint8_t val) {
  if ( verbosity ) {
    Serial.print(F("?SIO: WriteRegister channel="));
    Serial.print(channel,HEX);
    Serial.print(F(" reg_addr="));
    Serial.print((reg_addr<<3 | channel<<1),HEX);
    Serial.print(F(" val="));
    Serial.println(val,HEX);
  }

  Wire.beginTransmission(SC16IS752_ADDRESS);
  Wire.write((reg_addr<<3 | channel<<1));
  Wire.write(val);
  Wire.endTransmission(1);
  return ;
}
