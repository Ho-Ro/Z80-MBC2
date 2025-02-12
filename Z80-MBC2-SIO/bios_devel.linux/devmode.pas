{$U+} { user break with ^C }
{$R+} { array range check }

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
  20250131:       - source code reformatting w/o functional change
  20250207: v.0.5 - enable/disable auto RTS/CTS handshake (and XON/XOFF, NYI)
  20250212: v.0.6 - allow multiple parameter for phys. devices
}

Type
  Str2 = String[2];
  Str4 = String[4];
  Str6 = String[6];
  Str7 = String[7];

Const
  programVersion : String[20] = 'DEVMODE v.0.6';
  HexChar : Array[0..15] of Char = '0123456789ABCDEF';

  MaxBaud : Byte = 20;
  BaudRates : Array[0..20] of Str6 = (
                'NONE',  '50',    '75',    '110',   { std CP/M baud rates}
                '134',   '150',   '300',   '600',   { std CP/M baud rates}
                '1200',  '1800',  '2400',  '3600',  { std CP/M baud rates}
                '4800',  '7200',  '9600',  '19200', { std CP/M baud rates}
                '14400', '28800', '38400', '57600', { new baud rates }
                '115200'
              );

{ BIOS modebaud bit masks }
  mbInput       : Byte = $01;
  mbOutput      : Byte = $02;
  mbInOut       : Byte = $03;
  mbSoftBaud    : Byte = $04;
  mbSerial      : Byte = $08;
  mbXonXoff     : Byte = $10; { ignore this one }
  mbAutoXonXoff : Byte = $40;
  mbAutoRtsCts  : Byte = $80;

  MaxLogDev  : Byte = 7;
  LogDevices : Array[0..7] of Str7 = (
                'CONIN:', 'CONOUT:', 'AUXIN:', 'AUXOUT:', 'LSTOUT:',
                'CON:', 'AUX:', 'LST:'
              );


Var
  cpmVer : Byte;
  chrTbl : Integer;
  devNum : Integer;
  bdIndex : Integer;
  hex : Str4;
  iii, aaa : Integer;
  MaxPhysDev : Integer;
  PhysDevices : Array[0..15] of Str6;
  devChars : Array[0..15] of Byte;
  devBauds : Array[0..15] of Byte;


{$I UBIOS.PAS -> function UBIOS( FNUM, A, BC, DE, HL ) }


Procedure showHelp;
begin
  WriteLn( 'Usage: DEVMODE [ PD [BAUD] [HDSH] | LD [PD [PD] ... ] | /H[ELP] ]' );
  WriteLn;
  WriteLn( '  - Set the baud rate or handshake mode of a physical device' );
  WriteLn( '    PD:   Physical Device Name, one of:' );
  Write(   '          ' );
  for iii := 0 to MaxPhysDev do
    Write( PhysDevices[ iii ], ' ' );
  WriteLn;
  Write(   '    BAUD: Baud rate, one of:' );
  for iii := 1 to maxBaud do
    begin
      if iii mod 8 = 1 then
        begin
          WriteLn;
          Write( '        ' )
        end;
      Write( BaudRates[ iii ]:7 )
    end;
  WriteLn;
  WriteLn( '    HDSH: Handshake mode, one of:' );
  WriteLn( '          NONE, RTSCTS, XONXOFF' );
  WriteLn;
  WriteLn( '  - Display or set logical to physical device assignment' );
  WriteLn( '    LD:   Logical Device Name, one of:' );
  Write(   '          ' );
  for iii := 0 to MaxLogDev do
    Write( LogDevices[ iii ], ' ' );
  WriteLn;
  WriteLn( '    PD:   Physical Device Name, as above' )
end;


Function btox( b : Byte ) : Str2;
Var
  pos : Byte;
  str : Str2;
begin
  str := '  ';
  pos := 2;
  while pos > 0 do
    begin
      str[pos] := HexChar[ b and $F ];
      b := b shr 4;
      pos := pos - 1
    end;
  btox := str
end;


Function itox( i : Integer ) : Str4;
Var
  pos : Byte;
  str : Str4;
begin
  str := '    ';
  pos := 4;
  while pos > 0 do
    begin
      str[pos] := HexChar[ i and $F ];
      i := i shr 4;
      pos := pos - 1
    end;
  itox := str
end;


Function getChrTbl : Integer;
Var
  ret : Integer;
  dev : Byte;
  adr : Integer;
  name : Array[0..6] of Char;
  iii : Integer;
begin
  { calls BIOS via BDOS function 50
    DEVTBL: Get CHARACTER DEVICE TABLE
    (See cap. 3.2 CP/M 3 System Guide)
  }
  adr := UBIOS( 20, 0, 0, 0, 0 ); { FNUM, A, BC, DE, HL }

  getChrTbl := adr; { function return value }

  MaxPhysDev := -1;

  while Mem[ adr ] <> 0 do
    begin
      MaxPhysDev := MaxPhysDev + 1;
      for iii := 0 to 5 do
        name[ iii ] := Char( Mem[ adr + iii ] );
      name[6] := ' ';
      PhysDevices[MaxPhysDev] := Copy(name,1,Pos(' ',name)-1); { strip spaces }
      devChars[MaxPhysDev] := Mem[ adr + 6 ];
      devBauds[MaxPhysDev] := Mem[ adr + 7 ];
      adr := adr + 8
    end
end;


Function getSCB( offset : Byte ) : Integer;
Var
  scbPB : Array[0..3] of Byte;
begin
  { calls BDOS function 49
    DE : address of the parameter area
    return value in BA, HL
  }
  scbPB[0] := offset;
  scbPB[1] := $00; { get }
  getSCB := BdosHL( 49, Addr( scbPB ) )
end;


Procedure setSCB( offset : Byte; value : Integer );
Var
  scbPB : Array[0..3] of Byte;
begin
  { calls BDOS function 49
    DE : address of the parameter area
  }
  scbPB[0] := offset;
  scbPB[1] := $FE; { set word }
  scbPB[2] := Lo( value );
  scbPB[3] := Hi( value );
  Bdos( 49, Addr( scbPB ) )
end;


Function getLDNum( name : Str7 ) : Integer;
Var
  iii : Integer;
  devNum : Integer;
begin
  devNum := -1;
  for iii := 0 to MaxLogDev do
    if name = logDevices[ iii ] then
      devNum := iii;
  getLDNum := devNum
end;


Function getPDNum( name : Str6 ) : Integer;
Var
  iii : Integer;
begin
  getPDNum := -1;
  for iii := 0 to MaxPhysDev do
    if name = PhysDevices[ iii ] then
      getPDNum := iii
end;


{$A-} { allow recursive procedure call }
Procedure processLogDevice( ldNum : Integer );
Var
  pdNum : Integer;
  ioVector : Integer;
  paraNum : Integer;
begin
  if ldNum < 5 then { IN or OUT devices}
    begin
      Write( LogDevices[ ldNum ]:7, ' ' );
      if ParamCount <= 1  then { show assigned phys. devices }
        begin
          ioVector := $8000; { mask phys dev. #0 }
          for pdNum := 0 to MaxPhysDev do
            begin
              if (getSCB( $22 + 2 * ldNum ) and ioVector ) <> 0 then
                Write( PhysDevices[ pdNum ], ' ' );
              ioVector := ioVector Shr 1  { next phys. device }
            end;
          WriteLn
        end
      else { more parameter - assign phys. devices }
        begin
          ioVector := 0;
          for paraNum := 2 to ParamCount do
            begin
              pdNum := getPdNum( ParamStr( paraNum ) );
              if pdNum >= 0 then
                ioVector := ioVector or ( $8000 Shr pdNum );
            end;
          WriteLn( ' set IOVECTOR $', itox( ioVector ) );
          setSCB( $22 + 2 * ldNum, ioVector )
        end
    end
  else { combined IN and OUT, call the basic functions recursively }
    begin
      if ldNum = 5 then { CON: }
        begin
          processLogDevice( 0 ); { CONIN: }
          processLogDevice( 1 )  { CONOUT: }
        end;
      if ldNum = 6 then { AUX: }
        begin
          processLogDevice( 2 ); { AUXIN: }
          processLogDevice( 3 )  { AUXOUT: }
        end;
      if ldNum = 7 then { LST: }
        begin
          processLogDevice( 4 )  { LSTOUT: }
        end
    end
end;
{$A+} { back to std. - abs. adresses }


Procedure setBaudRate( dev : Integer; nwBdIdx : Byte );
Var
  bdIdx : Byte;
  dvOpt : Byte;
  bdPos : Integer;
begin
  bdPos := chrTbl + 8 * dev + 7;
  bdIdx := Mem[ bdPos ];
  dvOpt := Mem[ bdPos - 1 ];

  { If mb$serial AND mb$soft$baud AND valid index AND index is different }
  if ( dvOpt and (mbSerial or mbSoftBaud) = (mbSerial or mbSoftbaud) )
  and (nwBdIdx <> $FF)
  and (nwBdIdx <> bdIdx) then
    begin { change baud rate }
      Mem[ bdPos ] := nwBdIdx; { set new baudrate value in chrTbl }
      { call BIOS DEVINI to update the baud rate for dev }
      iii := UBIOS( 21, 0, dev, 0, 0 ); { FNUM, A, BC, DE, HL }
      Writeln( PhysDevices[ dev ], ' : ',
              BaudRates[ bdIdx ], ' Bd -> ',
              BaudRates[ nwBdIdx ], ' Bd' )
    end
  else { no change, just show the current value }
    if dvOpt and mbSerial = mbSerial then
      WriteLn( PhysDevices[ dev ], ' : ', BaudRates[ bdIdx ], ' Bd' )
end;


Function setHandshake( devNum, argNum : Integer ) : Boolean;
Var
  devOpt  : Byte;
  optPos : Integer;
begin
  optPos := chrTbl + 8 * devNum + 6;
  devOpt := Mem[ optPos ];

  { If mb$serial }
  if (devOpt and mbSerial) = mbSerial then
    begin
      if ParamStr( argNum ) = 'RTSCTS' then
        begin
          Mem[ optPos ] := devOpt and $3F or mbAutoRtsCts;
          { call BIOS DEVINI to enable HW handshaking for dev }
          iii := UBIOS( 21, 0, devNum, 0, 0 ); { FNUM, A, BC, DE, HL }
          setHandshake := True;  { return ok }
          Exit
        end;
      if ParamStr( argNum ) = 'XONXOFF' then
        begin
          Mem[ optPos ] := devOpt and $3F or mbAutoXonXoff;
          { call BIOS DEVINI to enable SW handshaking for dev }
          iii := UBIOS( 21, 0, devNum, 0, 0 ); { FNUM, A, BC, DE, HL }
          setHandshake := True;  { return ok }
          Exit
        end;
      if ParamStr( argNum ) = 'NONE' then
        begin
          Mem[ optPos ] := devOpt and $3F;
          { call BIOS DEVINI to disable all handshaking for dev }
          iii := UBIOS( 21, 0, devNum, 0, 0 ); { FNUM, A, BC, DE, HL }
          setHandshake := True;  { return ok }
          Exit
        end;
    end
  else
    begin
      WriteLn( PhysDevices[ devNum ], ' does not support handshake' );
      setHandshake := True;  { but return True b/c cmd syntax was ok }
      Exit
    end;
  setHandshake := False;  { return error }
end;


Procedure showDevice( devNum : Integer );
begin
  Write( PhysDevices[ devNum ]:6, '  ' );
  if devChars[ devNum ] and mbInput <> 0 then
    Write( 'I' )
  else
    Write( ' ' );
  if devChars[ devNum ] and mbOutput <> 0 then
    Write( 'O' )
  else
    Write( ' ' );
  Write( ' ' );
  if devChars[ devNum ] and mbSerial <> 0 then
    Write( 'S' )
  else
    Write( ' ' );
  if devChars[ devNum ] and mbSoftbaud <> 0 then
    Write( 'B' )
  else
    Write( ' ' );
  Write( ' ' );
  if devChars[ devNum ] and mbAutoXonXoff <> 0 then
    Write( 'X' )
  else
    Write( ' ' );
  if devChars[ devNum ] and mbAutoRtsCts <> 0 then
    Write( 'H' )
  else
    Write( ' ' );
  bdIndex := devBauds[ devNum ];
  if (bdIndex > 0) and (bdIndex <= maxBaud) then
    Write( baudRates[ bdIndex ]:7 );
  WriteLn
end;


Label nextArg;

begin
  WriteLn( programVersion );
  cpmVer := Bdos( 12 ); { get CP/M version }
  if cpmVer <> $31 then
    begin { $31 = CP/M 3.1 -> CHRTBL available }
      Writeln( 'Wrong CP/M version (', btox( cpmVer ), '), CP/M 3.1 required' );
      Halt
    end;

  chrTbl := getChrTbl; { get names, characteristic and baud of phys dev from BIOS CHRTBL  }

  if ParamCount > 0 then
    begin
    { /H[elp] ? }
      if Pos( '/H', ParamStr( 1 ) ) > 0 then
        begin
          showHelp;
          Halt
        end;

    { device name given? }
      devNum := getPDNum( ParamStr( 1 )  );
      if devNum = -1 then
        begin { no known phys device }
          devNum := getLDNum( ParamStr( 1 ) );
          if devNum <> -1 then  { but a logical device }
            processLogDevice( devNum )
          else { nope }
            WriteLn( 'Unknown device ', ParamStr( 1 ) );
          Halt { ready, exit program }
        end;

    { we have a known physical device }
      if ParamCount < 2 then  { no more cmd line arguments }
        showDevice( devNum )  { show device parameter }
      else
        for aaa := 2 to ParamCount do
          begin
          { new baud rate given? }
            for iii := 1 to MaxBaud do
              if ParamStr( aaa ) = BaudRates[ iii ] then
                begin
                  setBaudRate( devNum, iii ); { change / show baud rate }
                  goto nextArg
                end;
          { handshake mode parameter? }
            if setHandshake( devNum, aaa ) then  { if ok }
              goto nextArg;
          { neither baudrate nor handshake request }
              WriteLn( 'Unknown argument ', ParamStr( aaa ) );
              showHelp;
              Halt;
            nextArg:
          end { for aaa }
    end { ParamCount > 0 }
  else { no valid parameter -> show complete phys./log. dev. status }
    begin
      for devNum := 5 to 7 do  { CON:, AUX:, LST: }
        processLogDevice( devNum );
      for devNum := 0 to MaxPhysDev do  { all phys. devices }
        showDevice( devNum )
    end
end.
