�v
Some useful CP/M-Plus addresses and register contents
CPM+ADD v.2 15-Dec-85 Jerry Levy

Generic CP/M 3.x 

$�J�2�͖�#���?T�J���* +++~�p��p�! ����#���p�###~����! ��å* 9 #�~�!��#���p* ? #�~�!�#�,�p* N #�~�2�#���p��^#V��>"2���r�p>$2�����p>&2�����p>(2�����p>*2����p>:2����"l�p>X2���(�p>Z2���t́>[2����́>\2����́>]2�����p>b2�����p�1�� �       2�� �        ��J&. "�*�}��R}�A2�2p>	2���"j�*�#"�᯼�+����?��J ��o�J*j �͸���?��J*ld ���?�      ����|́}́������͊��Ɛ'�@'͙ͨ��:�� ¦�����:�� ʶ��2���"n>�2� PY�����!�����>�2��~�z��{��#�*n#"n���������> 2��?��2���> �2�́��:�� �**n�?�p�����_� ����>�2>
�2���	� ���            Misc. addresses
BIOS Base          = cboot jmp = bios jmp table address
COMMON Base        
@MXTPA             = top of TPA = bdos_base
@CTBL        XXXX  = device table, if implemented
@DTBL              = drive tbl (FFFF->none, hashing supported)
                               (FFFE->none, no hashing)
@CBNK              = storage of current_memory_bank
SCB_BASE+0H        = at SCB_BASE+3AH, address of System Control Block

            Selected Register contents
I/O Redirection Flags (16-bit words):
  for CONIN        at SCB_BASE+22H
  for CONOUT       at SCB_BASE+24H
  for AUXIN        at SCB_BASE+26H
  for AUXOUT       at SCB_BASE+28H
  for LSTOUT       at SCB_BASE+2AH

@DATE              at SCB_BASE+58H, 16-bit integer, days since 01-Jan-78
@HOUR              at SCB_BASE+5AH, BCD hours
@MIN               at SCB_BASE+5BH, BCD minutes
@SECOND            at SCB_BASE+5CH, BCD seconds

           CP/M-Plus BIOS addresses
Jump Table Entries and Subroutines
            Jump   Sub-   
             Table  routine
            ------ --------
 0 CBOOT                 
 1 WBOOT                 
 2 CONST                 
 3 CONIN                 
 4 CONOUT                
 5 LIST                  
 6 AUXOUT                
 7 AUXIN                 
 8 HOME                  
 9 SELDSK                
10 SETTRK                
11 SETSEC                
12 SETDMA                
13 READ                  
14 WRITE                 
15 LISTST                
16 SECTRN                
17 CONOST                
18 AUXIST                
19 AUXOST                
20 DEVTBL                
21 DEVINI                
22 DRVTBL                
23 MULTIO                
24 FLUSH                 
25 MOVE                  
26 TIME                  
27 SELMEM                
28 SETBNK                
29 XMOVE                 
30 USERF                 
31 RESERV1               
32 RESERV2               
             $           
             $           
             $           
             $           
             $           
             $           
             $           
$
        DPH's and DPB's for valid drives$  : drive -- Disk Parameter Header
     -xlt- ------72 bit scratch------ mf -dfb- -csv- -alv- -dir- -dta- -hsh- hb$  : drive -- Disk Parameter Block
     -spt- bs bm em -dsm- -drm- a0 a1 -cks- -off- ps pm$ System Control Block$                   �