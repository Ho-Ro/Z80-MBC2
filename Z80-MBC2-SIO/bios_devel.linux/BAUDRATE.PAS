Program baudrate;
{
  Enhance DEVICE.COM, allow higher baud rates than the
  standard CP/M values 50 .. 19200, e.g. 38400 and 115200
  for the Z80-MBC2-SIO add-on module.
  Future development shall also handle SW/HW handshake.
}

Type
  Str2 = String[2];
  Str4 = String[4];
  Str6 = String[6];

Const
  programVersion : String[20] = 'BAUDRATE v. 0.1';
  HexChar : Array[0..15] of Char = '0123456789ABCDEF';
  MaxDevice : Byte = 3;
  DeviceNames : Array[0..3] of Str4 = (
    'CON', 'PRN', 'SIOA', 'SIOB'
  );
  MaxBaud : Byte = 20;
  BaudRates : Array[0..20] of Str6 = (
    'NONE',  '50',    '75',    '110',   { std CP/M baud rates}
    '134',   '150',   '300',   '600',   { std CP/M baud rates}
    '1200',  '1800',  '2400',  '3600',  { std CP/M baud rates}
    '4800',  '7200',  '9600',  '19200', { std CP/M baud rates}
    '14400', '28800', '38400', '57600', { possible new baud rates }
    '115200'
  );

Var
  cpmVer : Byte;
  pb : Array[1..8] of Byte;
  chrtbl : Integer;
  devNum : Byte;
  devName : Str4;
  newBdIndex : Byte;
  hex : Str4;
  iii : Byte;


Function btox( b : Byte ) : Str2;
Var
  pos : Byte;
  str : Str2;
Begin
  str := '  ';
  pos := 2;
  While pos > 0 Do
  Begin
    str[pos] := HexChar[ b and $F ];
    b := b shr 4;
    pos := pos - 1;
  End;
  btox := str;
End;


Function itox( i : Integer ) : Str4;
Var
  pos : Byte;
  str : Str4;
Begin
  str := '    ';
  pos := 4;
  While pos > 0 Do
  Begin
    str[pos] := HexChar[ i and $F ];
    i := i shr 4;
    pos := pos - 1;
  End;
  itox := str;
End;


Function getChrTbl : Integer;
Begin
  { calls BIOS via BDOS function 50
    DE : address of the parameter area
    return value in BA, HL
    DEVTBL: Get CHARACTER DEVICE TABLE
    (See cap. 3.2 CP/M 3 System Guide)
  }
  pb[1] := 20; { BIOS function DEVTBL }
  pb[2] := 0;  { Register A }
  pb[3] := 0;  { Register C }
  pb[4] := 0;  { Register B }
  pb[5] := 0;  { Register E }
  pb[6] := 0;  { Register D }
  pb[7] := 0;  { Register L }
  pb[8] := 0;  { Register H }
  getChrTbl := BdosHL( 50, Addr(pb) );
End;


Procedure baudRate( dev, nwBdIdx : Byte );
Var
  bdIdx : Byte;
  dvOpt : Byte;
  bdPos : Integer;
Begin
  bdPos := chrtbl + 8 * dev + 7;
  bdIdx := Mem[ bdPos ];
  dvOpt := Mem[ bdPos - 1 ];

  { If mb$serial AND mb$soft$baud AND valid index AND index is different }
  If (dvOpt And $0C = $0C) And (nwBdIdx <> $FF) And (nwBdIdx <> bdIdx) Then
  Begin { change baud rate }
    Mem[ bdPos ] := nwBdIdx; { set new baudrate }
    pb[1] := 21; { DEVINI }
    pb[3] := dev;
    Bdos( 50, Addr(pb) ); { call BIOS DEVINI to update baud rate }
    Writeln( DeviceNames[ dev ], ' : ',
      BaudRates[ bdIdx ], ' Bd -> ',
      BaudRates[ nwBdIdx ], ' Bd' );
  End
  Else { no change, just show the current value }
    WriteLn( DeviceNames[ dev ], ' : ', BaudRates[ bdIdx ], ' Bd' );
End;


Begin
  WriteLn( programVersion );
  cpmVer := Bdos( 12 ); { get CP/M version }
  If cpmVer = $31 Then  { $31 = CP/M 3.1 -> CHRTBL available }
  Begin
    devNum := $FF;
    newBdIndex := $FF;

    If ParamCount > 0 Then { device name given }
    Begin
      For iii := 0 To MaxDevice Do
        If ParamStr( 1 ) = DeviceNames[ iii ] Then
          devNum := iii;
      If devNum = $FF Then
        WriteLn( 'Unknown device ', ParamStr( 1 ) );
    End
    Else
      devNum := 2; { set SIOA as default }

    If ParamCount > 1 Then { new baud rate given }
    Begin
      For iii := 1 To MaxBaud Do
        If ParamStr( 2 ) = BaudRates[ iii ] Then
          newBdIndex := iii;
      If newBdIndex = $FF Then
        WriteLn( 'Unknown baud rate ', ParamStr( 2 ) );
    End;

    If devNum <> $FF Then
    Begin
      chrtbl := getChrTbl; { get address of BIOS CHRTBL }

      baudRate( devNum, newBdIndex ); { show or change baud rate }
      If ParamCount = 0 Then { no parameter -> show SIOA and SIOB }
        baudRate( 3, $FF );
    End;
  End
  Else Writeln( 'Wrong CP/M version (', btox( cpmVer ), '), CP/M 3.1 required' )
End.
