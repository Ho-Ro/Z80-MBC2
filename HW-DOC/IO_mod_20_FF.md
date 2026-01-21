## Old HW mod to free IO address range 0x20..0xFF for own experiments

```
Cut Z80 /IORQ ---/ /--- U1/9 and add the 74HC32 devices in the dotted box
                                                     /S
U2/20                                   CUT           9 +--\  Q
/IORQ ---------------------------+-----/  /-----+-------|   | 8
                                 |              |    10 |   |o--o-->|--/\/\/\--|
.................................|............  |   +---|   |  /   D3    R6   GND
:                                |           :  |    \  +--/  /
:                                | 9 +--\    :  |     \ U1C  /
:                                +---|---| 8 :  |      \    /
:                                 10 |   |---:--+       \  /
:                                +---|---|   :           \/
:  U2/37              13 +--\    |   +--/    :           /\
:  A7 -------------------|---|   | 74HC32C   :          /  \
:                     12 |   |---+           :         /    \
:                    +---|---| 11            :        /      \
:  U2/36   1 +--\    |   +--/                :       /  +--\  \
:  A6 -------|---| 3 | 74HC32D               :      +---|   |  \
:          2 |   |---+                       :       12 |   |o--o--- /WAIT
:  A5 -------|---|                           :      +---|   | 11
:  U2/35     +--/                            :      |13 +--/  /Q
:          74HC32A                           :      |/R  U1D
:                  Add 3/4 74HC32            :      |
:............................................:      +--------------- /WAIT_RES
```

Unfortunately this modification breaks the IOS interrupt handling because the PC and not an I/O address
is put on the address bus during INT ACK. Replaced by the new 0x40..0xFF variant below.


## New HW mod with interrupt support

```
Cut the connection /IORQ ---/ /--- U1/9 and add the devices in the dotted box
                                                       /S
   U2/20                    CUT                         9 +--\  Q
   Z80 /IORQ --------o-----/  /-----o----o---o------------|   | 8
                     |              |    |   |         10 |   |O--o-->|--/\/\--|
.....................|..............|....|...|......  +---|   |  /   D3   R6  GND
:                    |              |    |   |     :   \  +--/  /   LED
:                    |              V    V   \     :    \ U1C  /
:                    | 9 +--\     D ~  D ~   /  R  :     \    /
:  U2/37  13 +--\    o---|---| 8    |    |   \ 1K0 :      \  /
:  Z80 A7 ---|---|   |10 |   |------+    |   /     :       \/
:         12 |   |---|---|---| /IORQ_IOS |   |     :       /\
:  Z80 A6 ---|---| 11|   +--/            |   |     :      /  \
:  U2/36     +--/    | 74HC32C           |   |     :     /    \
:          74HC32D   |                   |   V     :    /      \
:                    | 1 +--\            |  Vcc    :   /  +--\  \
:                    +---|---| 3         |         :  +---|   |  \
:                      2 |   |-----------+         :   12 |   |O--o--- /WAIT
:  U2/27 ----------------|---|  /INT_ACK           :  +---|   | 11
:  Z80 /M1               +--/                      :  |13 +--/  /Q
:                      74HC32A                     :  |/R  U1D
:  Add 3/4 74HC32, 2 Schottky diodes D, and R 1K0  :  +-------------- /WAIT_RES
:...................................................
```
