{$U+}
{$R+}

Program devmode;
{
  Enhance DEVICE.COM, allow higher baud rates than the
  standard CP/M values 50 .. 19200, e.g. 38400 and 115200
  for the Z80-MBC2-SIO add-on module.
  Future development shall also handle SW/HW handshake.
  20250115: v.0.1 - 1st working version BAUDRATE.COM, use hard coded dev names
  20250117: v.0.2 - get phys device names and capabilities from BIOS chrtbl
                    show logical device vectors
  20250127: v.0.3 - show logical to physical device assignment
  20250128: v.0.4 - new name DEVMODE, add logical to physical device assignment
}

Type
  Str2 = String[2];
  Str4 = String[4];
  Str6 = String[6];
  Str7 = String[7];

Const
  programVersion : String[20] = 'DEVMODE v.0.4';
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
  bdIndex : Integer;
  newBdIndex : Integer;
  hex : Str4;
  iii : Integer;
  maxDev : Integer;
  devNames : Array[0..15] of Str6;
  devChars : Array[0..15] of Byte;
  devBauds : Array[0..15] of Byte;


Procedure showHelp;
Begin
  WriteLn( 'Usage: DEVMODE [ PDname [baudrate] | LDname [PDname [PDname] ... ] | /H[ELP] ]' );
  WriteLn;
  WriteLn( '  - Display or set the baud rate of a physical device' );
  WriteLn( '    PDname : Physical Device Name, one of:' );
  Write( '      ' );
    For iii := 0 To maxDev Do
        Write( devNames[ iii ], ' ' );
  WriteLn;
  WriteLn;
  WriteLn( '  - Display or set logical to physical device assignment' );
  WriteLn( '    LDname : Logical Device Name, one of:' );
  Write( '      ' );
    For iii := 0 To MaxLogDevice Do
        Write( LogDevices[ iii ], ' ' );
  WriteLn;
  WriteLn( '    PDname : Physical Device Name, as above' );
End;


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
  name : Array[0..6] Of Char;
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
    name[6] := ' ';
    devNames[maxDev] := Copy(name,1,Pos(' ',name)-1); { strip spaces }
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
Begin
  getPDNum := -1;
  For iii := 0 To maxDev Do
    If name = devNames[ iii ] Then
      getPDNum := iii;
End;


Procedure processLogDevice( ldNum : Integer );
Var
  pdnum : Integer;
  ioVector : Integer;
  paranum : Integer;
Begin
  If ldNum < 5 Then { IN or OUT devices}
  Begin
    Write( LogDevices[ ldNum ], ' ' );
    If ParamCount = 1 Then
    Begin
      ioVector := $8000;
      For pdnum := 0 to maxDev Do
      Begin
        If (getSCB( $22 + 2 * ldNum ) And ioVector ) <> 0 Then
          Write( devNames[ pdnum ], ' ' );
        ioVector := ioVector Shr 1;
      End;
      WriteLn;
    End
    Else { more parameter }
    Begin
      ioVector := 0;
      For paranum := 2 To ParamCount Do
      Begin
        pdnum := getPdNum( ParamStr( paranum ) );
        If pdnum >= 0 Then
          ioVector := ioVector Or ( $8000 Shr pdnum );
      End;
      WriteLn( ' set IOVECTOR $', itox( ioVector ) );
      setSCB( $22 + 2 * ldNum, ioVector );
    End;
  End
  Else { combined IN and OUT, call the basic functions recursively }
  Begin
    If ldNum = 5 Then { CON: }
    Begin
      processLogDevice( 0 ); { CONIN: }
      processLogDevice( 1 ); { CONOUT: }
    End;
    If ldNum = 6 Then { AUX: }
    Begin
      processLogDevice( 2 ); { AUXIN: }
      processLogDevice( 3 ); { AUXOUT: }
    End;
    If ldNum = 7 Then { LST: }
    Begin
      processLogDevice( 4 ); { LSTOUT: }
    End;
  End;
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

  If ParamCount > 0 Then
  Begin
    { /H[elp] ? }
    If Pos( '/H', ParamStr( 1 ) ) > 0 Then
    Begin
      showHelp;
      Exit
    End;

    { device name given? }
    devNum := getPDNum( ParamStr( 1 )  );
    If devNum = -1 Then { no known phys device }
    Begin
      devNum := getLDNum( ParamStr( 1 ) );
      If devNum <> -1 Then  { but a logical device }
        processLogDevice( devNum )
      Else { nope }
        WriteLn( 'Unknown device ', ParamStr( 1 ) );
      Exit
    End;

    { we have a known physical device }
    If ParamCount > 1 Then { new baud rate given? }
    Begin
      For iii := 1 To MaxBaud Do
        If ParamStr( 2 ) = BaudRates[ iii ] Then
          newBdIndex := iii;
      If newBdIndex <> -1 Then
        setBaudRate( devNum, newBdIndex ) { show or change baud rate }
      Else
      Begin
        WriteLn( 'Unknown baud rate ', ParamStr( 2 ) );
        Exit;
      End;
    End
    Else { only 1 parameter }
      showDevice( devNum ); { show device parameter }
  End
  Else { no valid parameter -> show complete phys dev status }
    For iii := 0 To maxDev Do
      showDevice( iii );
End.
