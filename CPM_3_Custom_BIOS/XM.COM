: =2����S�'!�"�*�|��S+"�*�#"�>ͧ:�ͧ/ͧ �QY*�~ͧ�&�o��O~�W$^�#�@:���czͧKyͧ���)2�"����:��>�ԧ�� ���y�iO����:��ڧ���iReceived�*�͸� block�>xͮ���ʤ��!�4~�
�ͳ10 ACK error�~���>�>
��~�#���  0@P`p��������2"RBrb��������$4dtDT��������6&vfVF��������HXhx(8��������ZJzj
:*���뛋��l|L\,<���ݭ���~n^N>.���Ͽ����������� 0 P@p`��������"2BRbr��������4$tdTD��������&6fvFV���陉��XHxh8(��������JZjz
*:���ͽ���|l\L<,���߯���n~N^.> !Bc����)Jk����1sR����9{Z����bC �Ǥ�jK(	�Ϭ�Sr0����[z8�����冧@a#�펯Hi
+�Է�qP3�ܿ�yX;����"`A����*hI����2Qp����:Yx����-No����%Fg����=^����5wV�˨�nO,�à�fG$����_~<��Wv4Lm/�銫De'�Ⴃ}\?�ػ�uT7�г�.lM����&dE����>]|����6Ut����2�>ͮ�>2�2�ͬW:�_ͬ/�¿�2� �QY*�ͬw�&�o��O~�W$^�#�2:���Xͬ���Kͬ���:�="�T*�#"�*�#"���:���<�ͳLost block�!�45ʿ�±�iSender cancele�>�¿ͥ�2�� ͬ��ͳCan,,t syn�ͬ��>ͧ!�4~�
�ͳ10 bad block�*�|�7�>�2��!  "�&"�(�z��#>�2���T]��� ��:���ͥ���� ����:��! "������ �*�#"�:���a�2�*�|��>ͧ���iOKSent�ó>�O�>2��*��� ��������������KS{�T]<	���Ѻ�S�0O>�6-!+!�~<�5���m�6<H��>�6��>	�6��ͳ^�\ ���� ����Z:�O�sͬ�2��T�V�-�2��m with CRC����m with checksum���m������ͳInit timeou�ͳDisk write fai�G��UART Tx fai�G��by receive�:�G�>¿>ͧ�iABORT:����x��2����Ò�FILE CLOSE FAIL! May be corrup��Empty file erase��m�����+}�̊>�6��>	�5>�����@����* o�+}�̊>�6�E��+}�̊� ��U����!  +|�ʔ� ��jy����>Ä>�6y���!�5*�����Û�& ��No /I� y��+}�̊ ��No /I� ʮ�            �            �C     1
>Z�6>����>2��02�!] >/��9��> w#w+#�r#�� 2��d���Q�G�Y�6�Fw���<2������	���p�2���	            !�:��_��_ N#F#^#V��:��ʕ!K"�Ĭ�#^#V�"�:�!  	=ª"�:�����iSend or receive (S/R)?���	�R�ҹ/2��iFile�:���	!-"����mopenSen�͟	�
��F	�mexists. Overwrite (Y/N)���	�Y���iFile��mcreat����mdRecei�͟	!n	"�Ϳ!�"�:���C�V:��	:�G!�\�+}�		:���ming via�:�=��	=��	��	�mcustom cod���mdirect I/���mRDR/PU��2��mCO��� >
O�=�����Q��	��;��/���4��2�2�!,
�#N#���
�G	�CEIK�M9OEPRQqRtSsXuZ��2��<2���4�0�Ҹ!�O	N	ͅ�h
�w#�a
��m��4����s
ʹ2�
ͅ�� Ã
laOʹ
Gʹ��!q�rx!\�r��=2��<2���4�0�Ҹ2���4�1�Ҹ<2���4�G����O�Y��
��Gx=�@Ҹx���G: �� x=2���0�
�ø�4��4:��7���������J6�!�5�����
��7?�>�2����f��Q��f��/7?�4���4�� ��	7?�s##w#y��~6�#####r���QͧҢ�����G�4ͧҸ����4�7��0�
�������ͅ��i/& bad valu����i/& unknow����iJun��m in�:�����XMODEM.CF��command lin��not foun�� fail. Write protect? Dir full��No filenam��i========================Xmodem 2.9 for Z80-MBC2.========================Usage: XMODEM <file> <option list>^C aborts
Command line and XMODEM.CFG options: /R Receive, /S Send /C Receive with checksums, else CRCs   (Receiver always sets error check mode) /E if CP/M RDR returns with Z set when not ready /Knn sets buffer max k-bytes (default: all free RAM)   nn is decimal, 0<nn<64
--More-��
�i /In 8080 code patches for /X3 I/O routines:  /I0 h0 h1 ...h11: initialize  /I1 h0 h1 ...h11: Tx data, chr in c  /I2 h0 h1 ...h11: Rx status, Z set if no chr  /I3 h0 h1 ...h11: Rx data, chr in a /M Console message /O pp h0 h1...hn sends hex h1-hn to port pp /P ss dd qq rr tt defines direct I/O port:  ss: status port  dd: data port  qq: 00/01 for active low/high ready  rr: Rx ready bit mask  tt: Tx ready bit mask/I, /O and /P values are 2-digit hex
--More-��
� /Q for Quiet; else + means ok block, - means retry /X sets the transfer port:  /X0 CP/M CON *  /X1 CP/M RDR/PUN * (default)  /X2 Direct I/O, defined by /P option  /X3 Custom code from /I patches  * Must not strip parity /Zm for m MHz CPU. 0<m<7, default m=2��%};3��$[f��� XM29    CFG                        