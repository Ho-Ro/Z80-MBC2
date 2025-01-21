{$U+}
{$R+}

Program BAUDRATE;
{
  Enhance DEVICE.COM, allow higher baud rates than the
  standard CP/M values 50 .. 19200, e.g. 38400 and 115200
  for the Z80-MBC2-SIO add-on module.
  Future development shall also handle SW/HW handshake.
  20250115: v.0.1 - 1st working version BAUDRATE.COM, use hard coded dev names
  20250117: v.0.2 - get phys device names and capabilities from BIOS chrtbl
                    show logical device vectors

}

Type
  Str2 = String[2];
  Str4 = String[4];
  Str6 = String[6];
  Str7 = String[7];

Const
  programVersion : String[20] = 'BAUDRATE v. 0.2';
  HexChar : Array[0..15] of Char = '0123456789ABCDEF';

  MaxBaud : Byte = 20;
  BaudRates : Array[0..20] of Str6 = (
    'NONE',  '50',    '75',    '110',   { std CP/M baud rates}
    '134',   '150',   '300',   '600',   { std CP/M baud rates}
    '1200',  '1800',  '2400',  '3600',  { std CP/M baud rates}
    '4800',  '7200',  '9600',  '19200', { std CP/M baud rates}
    '14400', '28800', '38400', '57600', { possible new baud rates }
    '115200'
  );

  MaxLogDevice : Byte = 7;
  LogDevices : Array[0..7] of Str7 = (
    'CONIN:', 'CONOUT:', 'AUXIN:', 'AUXOUT:', 'LSTOUT:',
    'CON:', 'AUX:', 'LST:'
  );


Var
  cpmVer : Byte;
  biosPB : Array[0..7] of Byte;
  chrtbl : Integer;
  devNum : Integer;
  devName : Str4;
  bdIndex : Integer;
  newBdIndex : Integer;
  hex : Str4;
  iii : Integer;
  maxDev : Integer;
  devNames : Array[0..15] of Str6;
  devChars : Array[0..15] of Byte;
  devBauds : Array[0..15] of Byte;


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
Var
  ret : Integer;
  dev : Byte;
  adr : Integer;
  name : Array[0..5] Of Char;
  iii : Integer;
Begin
  { calls BIOS via BDOS function 50
    DE : address of the parameter area
    return value in BA, HL
    DEVTBL: Get CHARACTER DEVICE TABLE
    (See cap. 3.2 CP/M 3 System Guide)
  }
  biosPB[0] := 20; { BIOS function DEVTBL }
  { biospb[1] := 0;  { Register A }
  { biospb[2] := 0;  { Register C }
  { biospb[3] := 0;  { Register B }
  { biospb[4] := 0;  { Register E }
  { biospb[5] := 0;  { Register D }
  { biospb[6] := 0;  { Register L }
  { biospb[7] := 0;  { Register H }
  adr := BdosHL( 50, Addr( biosPB ) );
  getChrTbl := adr;

  maxDev := -1;

  While Mem[ adr ] <> 0 Do
  Begin
    maxDev := maxDev + 1;
    For iii := 0 To 5 Do
      name[ iii ] := Char( Mem[ adr + iii ] );
    devNames[maxDev] := name;
    devChars[maxDev] := Mem[ adr + 6 ];
    devBauds[maxDev] := Mem[ adr + 7 ];
    adr := adr + 8;
  End;
End;


Function getSCB( offset : Byte ) : Integer;
Var scbPB : Array[0..3] of Byte;
Begin
  { calls BDOS function 49
    DE : address of the parameter area
    return value in BA, HL
  }
  scbPB[0] := offset;
  scbPB[1] := $00; { get }
  getSCB := BdosHL( 49, Addr( scbPB ) );
End;


Procedure setSCB( offset : Byte; value : Integer );
Var scbPB : Array[0..3] of Byte;
Begin
  { calls BDOS function 49
    DE : address of the parameter area
    return value in BA, HL
  }
  scbPB[0] := offset;
  scbPB[1] := $FE; { set word }
  scbPB[2] := Lo( value );
  scbPB[3] := Hi( value );
  Bdos( 49, Addr( scbPB ) );
End;


Procedure showLogDevice( ldNum : Integer );
Begin
  If ldNum < 5 Then
    Writeln( LogDevices[ ldNum ], '  ', itox( getSCB( $22 + 2 * ldNum ) ) );
  If ldNum = 5 Then
  Begin
    Writeln( LogDevices[ 0 ], '   ', itox( getSCB( $22 ) ) );
    Writeln( LogDevices[ 1 ], '  ', itox( getSCB( $24 ) ) );
  End;
  If ldNum = 6 Then
  Begin
    Writeln( LogDevices[ 2 ], '   ', itox( getSCB( $26 ) ) );
    Writeln( LogDevices[ 3 ], '  ', itox( getSCB( $28 ) ) );
  End;
  If ldNum = 7 Then
  Begin
    Writeln( LogDevices[ 4 ], '  ', itox( getSCB( $2A ) ) );
  End;
  Exit;
End;


Function getLDNum( name : Str7 ) : Integer;
Var
  iii : Integer;
  devNum : Integer;
Begin
  devNum := -1;
  For iii := 0 To MaxLogDevice Do
    If name = logDevices[ iii ] Then
      devNum := iii;
  getLDNum := devNum;
End;


Function getPDNum( name : Str6 ) : Integer;
Var
  iii : Integer;
  devNum : Integer;
Begin
  devNum := -1;
  For iii := 0 To maxDev Do
    If name = Copy( devNames[ iii ], 1, Length( name ) ) Then
      devNum := iii;
  getPDNum := devNum;
End;


Procedure setBaudRate( dev : Integer; nwBdIdx : Byte );
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
    biosPB[1] := 21;  { DEVINI }
    biosPB[3] := dev; { Reg C }
    Bdos( 50, Addr( biosPB ) ); { call BIOS DEVINI to update baud rate }
    Writeln( devNames[ dev ], ' : ',
      BaudRates[ bdIdx ], ' Bd -> ',
      BaudRates[ nwBdIdx ], ' Bd' );
  End
  Else { no change, just show the current value }
    If (dvOpt And $08 = $08) Then
      WriteLn( devNames[ dev ], ' : ', BaudRates[ bdIdx ], ' Bd' );
End;


Procedure showDevice( devNum : Integer );
Begin
  Write( devNames[ devNum ], '  ' );
  If (devChars[ devNum ] And $01) <> 0 Then
    Write( 'I' )
  Else
    Write( ' ' );
  If (devChars[ devNum ] And $02) <> 0 Then
    Write( 'O' )
  Else
    Write( ' ' );
  Write( ' ' );
  If (devChars[ devNum ] And $08) <> 0 Then
    Write( 'S' )
  Else
    Write( ' ' );
  If (devChars[ devNum ] And $04) <> 0 Then
    Write( 'B' )
  Else
    Write( ' ' );
  If (devChars[ devNum ] And $10) <> 0 Then
    Write( 'X' )
  Else
    Write( ' ' );
  bdIndex := devBauds[ devNum ];
  If (bdIndex > 0) And (bdIndex <= maxBaud) Then
    Write( baudRates[ bdIndex ]:7 );
  WriteLn;
End;



Begin
  WriteLn( programVersion );
  cpmVer := Bdos( 12 ); { get CP/M version }
  If cpmVer <> $31 Then  { $31 = CP/M 3.1 -> CHRTBL available }
  Begin
    Writeln( 'Wrong CP/M version (', btox( cpmVer ), '), CP/M 3.1 required' );
    Exit;
  End;

  devNum := -1;
  newBdIndex := -1;

  chrtbl := getChrTbl; { get names, characteristic and baud of phys dev from BIOS CHRTBL  }

  If ParamCount > 0 Then { device name given }
  Begin
    devNum := getPDNum( ParamStr( 1 )  );
    If devNum = -1 Then { no known phys device }
    Begin
      devNum := getLDNum( ParamStr( 1 ) );
      If devNum <> -1 Then  { but a logical device }
        showLogDevice( devNum )
      Else
        WriteLn( 'Unknown device ', ParamStr( 1 ) );
      Exit;
    End;
  End;

  { we have already a physical device }
  If ParamCount > 1 Then { new baud rate given }
  Begin
    For iii := 1 To MaxBaud Do
      If ParamStr( 2 ) = BaudRates[ iii ] Then
        newBdIndex := iii;
    If newBdIndex = -1 Then
    Begin
      WriteLn( 'Unknown baud rate ', ParamStr( 2 ) );
      Exit;
    End;
  End;

  If devNum <> -1 Then { valid device name }
    If newBdIndex <> -1 Then { valid baud rate }
      setBaudRate( devNum, newBdIndex ) { show or change baud rate }
    Else { valid device, but no baudrate }
      showDevice( devNum ) { show device parameter }
  Else
  Begin
  { no valid parameter -> show complete phys dev status }
    For iii := 0 To maxDev Do
      showDevice( iii );
  End;
End.
