# Test programs for IOS interrupt modes

## basic47
IOS "ROM" Basic for download with the iload command. Modification:
- Enable IOS RX interrupt

## basic47d
Same as above, but with these modification:
- Enable IOS RX and SYSTICK interrupts
- Set IM0 instead of IM1
- Set IOS INT vector to RST 30 (0xF7)
- Use RST 30 as INT location


