1��	=��1 ���[!�"�*�|���+"�*�#"�>ͯ:�ͯ/ͯ �QY*�~ͯ�&�o��O~�W$^�#�F:���izͯKyͯ̀�/2�"�:�<�+�!:"��@	1 �2�>�.��#>2��,W:�_�,/��(�2� �QY*��,w�&�o��O~�W$^�#¾:�����,��7K�,��::�=�"�: ��*�#"��S*�#"�:�<�+ͭÏ<��|�ʓ �,�*�|�,� :�ͯ!�4~�
ړ��|! 	"��*�|��+"��H�\ �H��|� �Y>x�.���� ����j!�4~�
���|\ �H<�ͣFILE CLOSE ERROR! May be corrupt.$:���! 	"���H�\ �H��	� �*�#"�: �����2�*�|��>ͯ̀��XOK
Sent���>2��*�ê+}�̚>�O��8>	�N>�����Y����* o�+}�̚>�O�^��+}�̚� ��n���+}�̚6�|  ������������j!�5*�����*���>�Oê6�|  y���!  +|���� ���y����)�|>��>�Oy�� �����������}�>��T]<	�
��_��W{�0O>�O�j:�<�-!+2��=�2���R��\ !	���� �����[���R�~��~#��\��>�O��>	�O�� �XABORT:��F:��ªÞ�Sͭ�XO�ͤ*�|����@<��ͦ
Empty file deleted$�XReceived�*���ͦ blocks$10 block errors$10 ACK errors$                                                                                                                                                                                                                                                               0@P`p��������2"RBrb��������$4dtDT��������6&vfVF��������HXhx(8��������ZJzj
:*���뛋��l|L\,<���ݭ���~n^N>.���Ͽ����������� 0 P@p`��������"2BRbr��������4$tdTD��������&6fvFV���陉��XHxh8(��������JZjz
*:���ͽ���|l\L<,���߯���n~N^.> !Bc����)Jk����1sR����9{Z����bC �Ǥ�jK(	�Ϭ�Sr0����[z8�����冧@a#�펯Hi
+�Է�qP3�ܿ�yX;����"`A����*hI����2Qp����:Yx����-No����%Fg����=^����5wV�˨�nO,�à�fG$����_~<��Wv4Lm/�銫De'�Ⴃ}\?�ػ�uT7�г�.lM����&dE����>]|����6Ut����^C$Sync fail$Lost blocks$Disk write fail$UART Tx fail$Undefined Port$No init from receiver$Z!g"�:�OE�|�,�2�ʎ�V�g��[ with CRC����[ with checksum���R��F�        �
 	  �C<  \ �H<�.	�XFile open
Sen��[ing via�:�=�$	=�	�	�[external cod���[direct I/���[RDR/PU��2��[CO��ͣFile not found$\ �H<�w	�XFile exists. Overwrite (Y/N)���
�Yª�@�XFile creat��H<��	�[d
Recei���:��³	�h�K�j+}�ª	:����	2�̀̐:�ïͦ fail. Write protect? Directory full?$�>Z�O��
>2�!� P~#�

)�H<��
�2�2�Ͱڿ���G
�/�?
4> � �0
��
!\ >/#�_
��O
6 #�X
p#�_
!�:��_��_ N#F#^#V��
:��ʊ
!d"6�,�#^#V�"��K        :����XSend or receive (S/R)?���
�R�ҩ
2��� >
�H:� =�:� ���Ͱ��
��;ʷ�/����!�#N#����G!	�2��<2����!�
�0�<!�=�<!�=�<!�=�s�͂��G�w#�>��R������Q�m2g͂�� �b�mo�mg�mO�m��m���!��Z�!u�Z��=2��<2�����0��s2�����1��s<2�����·��X=========================
XMODEM 2.7 By M. Eberhard
=========================
Z80-MBC2 (CP/M 3 only)
patched ver. by J4F
=========================
Usage: XMODEM <filename> <option list>
^C aborts

Command line and XMODEM.CFG options:
 /R to receive, /S to send
 /C receive with checksums, otherwise CRC error checking
    (Receiver sets error checking mode when sending)
 /E if CP/M RDR returns with Z set when not ready

--More-��q�X /I<n> patches I/O routines with 8080 code for /X3:
   /I0 h0 h1 ...(up to h7) = initialization
   /I1 h0 h1 ...(up to h7) = Tx data (chr is in reg c)
   /I2 h0 h1 ...(up to h7) = Rx status (Z set if no chr)
   /I3 h0 h1 ...(up to h7) = Rx data (chr in reg a)
 /M console message
 /O pp h0 h1 ... hn sends bytes h1-hn to port pp
 /P ss dd qq rr tt defines direct I/O port:
   ss = status port
   dd = data port
   qq = 00/01 for active low/active high ready bits
   rr = Rx ready bit mask
   tt = Tx ready bit mask

--More-��qͣ /Q for Quiet; else + means good block, - means retry
 /X selects the transfer port:
   /X0 CP/M CON
   /X1 CP/M RDR/PUN (default)
   /X2 Direct I/O, defined by /P option
   /X3 8080 I/O code, patched with /I options
 /Zm for m MHz CPU. 0<m<7, default m=2

CP/M CON and RDR must not strip parity.
Values for /I, /O and /P are 2-digit hex.
$2�X/& unrecognize���XJun�:���7ͦ in XMODEM.CFG$ͦ in command line$:�!  	=�Q"��s##w#y��f6�#####r��͂���XBad valu��Ͱ�͠ڙ����G͜�s��4�����:ڪ�A���0�?����ʰ� ʰ�	ʰ�:����M��H)�H���7�6�!�~�����7�5���
7?ɼ>�;L��$t����C EI	M;OIPXQ}R�S�X�Z�� XMODEM  CFG                                                                           