
Program Diskedit;  { ---- DISK EDITOR FOR CP/M 3.0 ---- }
                   { (c) 1984 by Gerhard Strube, Munich }

{ https://mark-ogden.uk/mirrors/www.cirsovius.de/CPM/Projekte/Artikel/TP/DirDisk/DirDisk.html }

{$U+} { enable user break }

Const
  MaxSize = 1024;   { max physical sector size }
  Version = $0031;  { version number CP/M plus }
  CMDLINE = 3;
  USRLINE = 5;
  INFOLINE = 20;
  BOTLINE = 23;

{   DPB:  SPT BSH BLM EXM DSM DRM AL0 AL1 CKS OFF PSH PHM  }
{         16b  8b  8b  8b 16b 16b  8b  8b 16b 16b  8b  8b  }

{   SPT: (logical 128 byte) Sectors Per Track  }
{   BSH: Block SHift - BLM: BLock Mask - BLS = 128 << BSH  }
{   BLM is one less than the number of 128 byte records    }
{   in an allocation unit, (BLS/128 - 1), or (2**BSH)-l.   }
{   See: CP/M 3 System Guide, Table 3-3 and Table 3-4.     }
{     BLS  BSH  BLM }
{    1024    3    7 }
{    2048    4   15 }
{    4096    5   31 }
{    8192    6   63 }
{   16384    7  127 }
{   EXM: EXtent Mask, (CP/M 3 System Guide, Table 3-5)  }
{   DSM: Number of blocks on the drive minus one. }
{   DRM: Number of 32 byte directory entries minus one  }
{   AL0, AL1: Dir. allocation vector (SysG. Fig. 3-4)   }
{   CKS: Size of the directory check vector, (DRM/4)+l  }
{        CKS = 8000H: perm. mounted, no checksumming    }
{   OFF: Number of reserved tracks, start of directory  }
{   PSH: PHysical record Shift factor.                  }
{   PHM: PHysical record Mask.                          }

Type
  DPB_t = record             { CP/M 3.0 disk parameter block:   }
    SPT:           integer;  { number of log. Sectors Per Track }
    BSH,                     { Block SHift                      }
    BLM,                     { BLock Mask                       }
    EXM:           byte;     { block EXtent Mask                }
    DSM,                     { blocks on disk -1                }
    DRM:           integer;  { directory entries - 1            }
    AL0, AL1:      byte;     { reserved blocks for directory    }
    CKS,                     { directory checksum size          }
    OFF:           integer;  { reserv. tracks, start of dir.    }
    PSH,                     { physical record shift            }
    PSM:           byte      { physical record mask             }
  end;
  CMDtype = set of Char;
  RWtype = ( FormatTracks,
            ReadSector,
            NextSector,
            PreviousSector,
            WriteSector
           );  { type of disk access }


Var
  Drive, LastDrive, Track,
  Sector, Lsector, Psector,
  Part, Psize, LogPerPhy,
  MaxSector,  MaxTrack,
  DefaultDrive,
  DirNum,
  DirTrack, DataTrack,
  FirstTrack, LastTrack,
  DPB_i, i, j, k:            integer;
  DriveChr, Cmd, LastCmd, c: char;
  ptr:                       ^DPB_t absolute DPB_i;
  DPH:                       ^integer absolute DPB_i;
  PhySecBuf:                 array [1..MaxSize] of byte;
  LogSecBuf:                 array [1..128] of byte;
  BufferValid:               boolean;
  Command:                   CMDtype;


{$I UBIOS.PAS }  { external funktion UBIOS for BIOS calls }
{$I HEXIO.PAS }  { ext. funkt. HEXVAL, ext. procedure WRITEHEX }


Procedure ShowHeader;
begin
  GotoXY( 1, 1 );
  LowVideo;
  Write( 'Disk editor for CP/M PLUS ver. 2.0 (c) 1984 by Gerhard Strube');
end;


Procedure Error( no: integer ); { show error message and exit program }
begin
  GotoXY( 10, INFOLINE );
  case no of 
    0: Write( 'Program requires CP/M 3.0 (CP/M PLUS).' );
    1: Write( 'Error: Invalid drive.' );
    2: Write( 'Error during seek / read / write.' )
  end;
  Bdos( 14, DefaultDrive );
  Halt
end;


Procedure ClrFromTo( first, last: integer );
Var
  iii: integer;
begin
  for iii := first to last do
    begin
      GotoXY( 1, iii );
      ClrEol
    end
end;


Function GetCommand( Commands: CMDtype ): Char;
Var
  Xpos: integer;
begin
  ShowHeader;
  Cmd := char( $FF ); { ignore additional returns }
  Xpos := 1;
  GotoXY( Xpos, CMDLINE );
  ClrEol;
  HighVideo;
  Write ( 'Enter command:  Q' );
  LowVideo;
  Write( 'uit, ' );
  Xpos := 23;
  HighVideo;
  Write( 'F' );
  LowVideo;
  Write( 'ormat, ' );
  Xpos := Xpos + 8;
  HighVideo;
  Write( 'R' );
  LowVideo;
  Write( 'ead, ' );
  Xpos := Xpos + 6;
  if 'N' in commands then
    begin
      HighVideo;
      Write( 'N' );
      LowVideo;
      Write( 'ext, ' );
      Xpos := Xpos + 6;
    end;
  if 'P' in commands then
    begin
      HighVideo;
      Write( 'P' );
      LowVideo;
      Write( 'revious, ' );
      Xpos := Xpos + 10;
    end;
  if 'M' in commands then
    begin
      HighVideo;
      Write( 'M' );
      LowVideo;
      Write( 'odify, ' );
      Xpos := Xpos + 8
    end;
  if 'W' in commands then
    begin
      HighVideo;
      Write( 'W' );
      LowVideo;
      Write( 'rite, ' );
      Xpos := Xpos + 7
    end;
  HighVideo;
  repeat
    GotoXY( Xpos-2, CMDLINE );
    if LastCmd in ['N', 'P'] then
      begin
        Write( ': ', LastCmd, chr( 8 ) );
        Cmd := UpCase( chr( Bdos( 1 ) ) ); { ConIn }
        if Cmd = chr( $0d ) then
          Cmd := LastCmd
      end
    else
      begin
        Write( ':  ', chr( 8 ) );
        Cmd := UpCase( chr( Bdos( 1 ) ) ) { ConIn }
      end
  until  Cmd in Commands;
  GotoXY( Xpos, CMDLINE );
  Write( Cmd );
  GetCommand := Cmd
end;


Function UserFrame( Mode: RWtype ): Char; { screen mask and data input }
Var
  Result : Char;
begin
  if Mode = FormatTracks then
    ClrFromTo( USRLINE, BOTLINE );
  LowVideo;
  ShowHeader;
  GotoXY( 1, USRLINE );
  case Mode of 
    ReadSector:   Write( 'READ  ' );
    NextSector:   Write( 'READ  ' );
    WriteSector:  Write( 'WRITE ' );
    FormatTracks: Write( 'FORMAT' )
  end;
  HighVideo;
  DriveChr := chr( Drive + $41 );    { 0..15 -> 'A'..'P' }
  GotoXY( 13, USRLINE );
  Write( 'DRIVE LETTER    (A, B, ..): ', DriveChr, chr( 8 ) );
  if not ( Mode in [ NextSector, PreviousSector ] ) then
    repeat
      DriveChr := UpCase( char( Bdos( 1 ) ) );
      if DriveChr < ' ' then
        DriveChr := chr( Drive + $41 );
      GotoXY( 41, USRLINE );
      Write( DriveChr );
    until ( DriveChr in ['A'..'P']);
  Drive := ord( DriveChr ) - $41;    { ord('A) }
  if Drive <> LastDrive then  { invalidate track and sector }
    begin
      Track := -1;
      Sector := 0;
      Lsector := 0
    end;
  LastDrive := Drive;
  i := UBIOS( 9, 0, Drive, 0, 0 );   { select drive }
  if i = 0 then Error( 1 );
  Bdos( 14, Drive );
  DPB_i := BdosHL( 31 );   { address of DPB; DPB_i and ptr have the same address! }

  { parse Disk Parameter Block and show important disk parameter }
  with ptr^ do
    begin
      MaxSector := SPT;
      DirTrack := OFF;
      DirNum := DRM+1;
      Psize := 128 shl PSH;
      LogPerPhy := 1 shl PSH;
      DataTrack := DirTrack + ( DRM div 4 div SPT ) + 1;
      k := ( DSM + 1 ) * ( ( BLM + 1 ) div 8 );
      GotoXY( 49, USRLINE );
      Write( k:5, ' KB capacity, ', DirNum, ' dir.' );
      MaxTrack := round( ( k / SPT ) * 8 + OFF );
      GotoXY( 49, USRLINE + 1 );
      Write( MaxTrack:5, ' tracks, ', DirTrack, ' reserv.' );
      GotoXY( 49, USRLINE + 2 );
      Write( SPT:5, ' log. sect. per track' );
      GotoXY( 49, USRLINE + 3 );
      Write( Psize:5, ' phys. sector size' );
      if ( Psize = 128 ) then
        begin
          GotoXY( 55,USRLINE + 4 );
          Write( '(BIOS deblocking?)' )
        end;

      if Track < 0 then
        Track := DirTrack;
      if Mode = FormatTracks then
        begin
          FirstTrack := DirTrack;
          LastTrack := DataTrack - 1;
          repeat
            GotoXY( 13, USRLINE + 1 );
            Write( 'FIRST TRACK     (0 ..',(MaxTrack -1): 4, '): ' );
            Write( FirstTrack, chr( 8 ) );
            if FirstTrack > 9  then Write( chr( 8 ) );
            if FirstTrack > 99 then Write( chr( 8 ) );
            readln( FirstTrack )
          until ( FirstTrack >= 0 ) and ( FirstTrack < MaxTrack );
          LastTrack := FirstTrack;
          repeat
            GotoXY( 13, USRLINE + 2 );
            Write( 'LAST TRACK      (', FirstTrack, ' ..',(MaxTrack -1): 4, '): ' );
            Write( LastTrack, chr( 8 ) );
            if LastTrack > 9  then Write( chr( 8 ) );
            if LastTrack > 99 then Write( chr( 8 ) );
            readln( LastTrack )
          until ( LastTrack >= FirstTrack ) and ( LastTrack < MaxTrack );
          Result := 'N';
          GotoXY( 1, USRLINE + 3 );
          Write( 'PROCEED?    (N)o  (F)ormat  (I)nitdir : ', Result, chr(8) );
          readln( Result );
          Result := UpCase( Result );
          if (Result <> 'F') and (Result <> 'I') then
            Result := 'N';
          UserFrame := Result
        end
      else  { Read / Write }
        begin
          repeat
            GotoXY( 13, USRLINE + 1 );
            Write( 'TRACK NUMBER    (0 ..',(MaxTrack -1): 4, '): ' );
            Write( Track, '  ', chr( 8 ), chr( 8 ), chr( 8 ) );
            if Track > 9  then Write( chr( 8 ) );
            if Track > 99 then Write( chr( 8 ) );
            if not ( Mode in [ NextSector, PreviousSector ] ) then
              ReadLn( Track )
          until ( Track >= 0 ) and ( Track < MaxTrack );
          GotoXY( 41, USRLINE + 1 );
          Write( Track, '  ' );
          Sector := Lsector;
          repeat
            GotoXY( 13, USRLINE + 2 );
            Write( 'SECTOR NUMBER   (0 ..', (SPT - 1): 4, '): ' );
            Write( Sector, '  ', chr( 8 ), chr( 8 ), chr( 8 ) );
            if Sector > 9  then Write( chr( 8 ) );
            if Sector > 99 then Write( chr( 8 ) );
            if not ( Mode in [ NextSector, PreviousSector ] ) then
              readln( Sector )
          until ( Sector >= 0 ) and ( Sector < SPT );
          GotoXY( 41, USRLINE + 2 );
          Write( Sector, '  ' );
          Lsector := Sector;
          Part := Sector mod LogPerPhy;     { make logical to physical }
          Sector := Sector div LogPerPhy;   { sector size translation  }
          UserFrame := 'Y'
        end
    end
end;


Procedure DoDisk( Mode: RWtype ); { execute disk operation }
begin
  if UserFrame( Mode ) = 'N' then
    exit;  { user abort }
  DPB_i := UBIOS( 9, 0, Drive, 1, 0 ); { selekt disk }
  { DPB_i = address of translation table log. -> phys. sector }
  Psector := UBIOS( 16, 0, Sector, DPH^, 0 ); { calculate phys. sector }
  GotoXY( 13, USRLINE + 3 );
  if LogPerPhy > 1 then
    Write( 'part ', Part, ' of ' );
  Write( 'phys. sector ', Psector:2 );
  i := UBIOS( 23, 0, 1, 0, 0 );                { execute 1 sector   }
  i := UBIOS( 10, 0, Track, 0, 0 );            { select track       }
  i := UBIOS( 11, 0, Psector, 0, 0 );          { select sector      }
  i := UBIOS( 12, 0, Addr( PhySecBuf ), 0, 0); { select DMA address }
  i := UBIOS( 28, 1, 0, 0, 0 );                { select RAM bank    }
  case Mode of 
    ReadSector,
    NextSector,
    PreviousSector:
                    begin
                      i := UBIOS( 13, 0, 0, 0, 0 );  { read phys. sector     }
                      if i <> 0 then Error( 2 );
                      for i := 1 to 128 do           { "extract" log. sector }
                        LogSecBuf[i] := PhySecBuf[i + Part * 128];
                      BufferValid := true
                    end;
    WriteSector:
                 begin
                   i := UBIOS( 13, 0, 0, 0, 0 );  { read phys. sector    }
                   if i <> 0 then Error( 2 );
                   for i := 1 to 128 do           { "insert" log. sector }
                     PhySecBuf[i + Part * 128] := LogSecBuf [i];
                   i := UBIOS( 14, 0, 0, 0, 0 );  { write phys. sector   }
                   if i <> 0 then Error( 2 )
                 end;
  end
end;


Procedure Format; { format tracks }
Var
  Ftrack : integer;
  FormatType : char;
  InfoString : String[13];

Procedure InitBuffer( INITDIR : Boolean);
begin
  for i := 1 to Psize do           { fill phys. sector }
    if INITDIR and (i mod $80 = $61) then  { INITDIR timestamp }
      PhySecBuf[i] := $21   { '!' for file date }
    else
      PhySecBuf[i] := $E5;  { erased data }
end;

begin
  FormatType := UserFrame( FormatTracks ); { No / Format / Initdir }
  if FormatType = 'N' then
    Exit;  { user abort }
  i := UBIOS( 9, 0, Drive, 1, 0 ); { selekt disk }
  BufferValid := False;            { do not show buffer after formatting }
  for Ftrack := FirstTrack to LastTrack do
    begin
      if (Ftrack < DirTrack) or (Ftrack = DataTrack) then
        begin
          InitBuffer( False );
          InfoString := 'FORMAT track '
        end
      else if Ftrack = DirTrack then
             begin
               InitBuffer( True );
               InfoString := 'INITDIR track'
             end;
      GotoXY( 1, USRLINE + 5 );
      Write( InfoString , Ftrack:3 );
      for Psector := 0 to ( MaxSector div LogPerPhy ) - 1 do
        begin
          i := UBIOS( 23, 0, 1, 0, 0 );                { execute 1 sector   }
          i := UBIOS( 10, 0, Ftrack, 0, 0 );           { select track       }
          i := UBIOS( 11, 0, Psector, 0, 0 );          { select sector      }
          i := UBIOS( 12, 0, Addr( PhySecBuf ), 0, 0); { select DMA address }
          i := UBIOS( 28, 1, 0, 0, 0 );                { select RAM bank    }
          i := UBIOS( 14, 0, 0, 0, 0 );                { write phys. sector }
          if i <> 0 then Error( 2 )
        end
    end;
  ClrFromTo( USRLINE, BOTLINE )
end;


Procedure DisplaySector; { show log. sector content on screen }
begin
  ClrFromTo( INFOLINE, BOTLINE );
  GotoXY( 1, USRLINE + 5 );
  LowVideo;
  Write( '   ' );
  for i := 0 to 15 do
    begin
      Write( ' ' );
      WriteHex( i )
    end;
  HighVideo;
  writeln;
  for i := 1 to 8 do
    begin
      LowVideo;
      WriteHex( (i-1) * 16);
      Write( ':' );
      HighVideo;
      for j := 1 to 16 do
        begin
          k := LogSecBuf [16 *( i - 1) + j];
          Write( ' ' );
          WriteHex( k )                { (1) as HEX number }
        end;
      Write( '   ' );
      for j := 1 to 16 do
        begin
          k := LogSecBuf[16 *( i - 1) + j];
          if k > 128 then LowVideo;
          k := k mod 128;
          if k < 32 then Write( '.' )  { (2) as ASCII character }
          else Write( chr(k) );        { control char. as dot }
          HighVideo
        end;
      writeln
    end;
end;


Procedure ModifySector; { change content of log. sector }
Var
  st:     string[80];
  s:      string[2];
  NewHex: boolean;
begin
  repeat
    GotoXY( 1,INFOLINE );
    ClrEol;
    Write( 'Change content starting at address: 0', chr( 8 ) );
    readln( st );
    i := 0;
    if length( st ) in [1..2] then i := HexVal( st )
  until i in [$00..$7F];
  i := i + 1; { cange to index $01..$80 }
  GotoXY( 1 , INFOLINE + 1 );
  writeln( 'Enter new content (1) as hex( separated by spaces), ');
  writeln( '               or (2) "''" with ASCII-String:');
  readln( st );
  if st[1] = '''' then
    begin
      for j := 2 to length( st ) do
        if i in [$01..$80] then
          begin
            LogSecBuf [i] := ord( st[j] );
            i := i + 1
          end
    end
  else
    begin
      j := 1;
      NewHex := false;
      while j <= length( st ) + 1 do
        begin
          if ( j = length( st) + 1 ) or ( st [j] = ' ' ) then
            begin
              if NewHex then
                begin
                  NewHex := false;
                  if i in [$01..$80] then
                    if HexVal( s) < 256 then
                      begin
                        LogSecBuf [i] := HexVal( s );
                        i := i + 1
                      end
                  else j := length( st ) { terminate }
                end;
              s := ' '
            end
          else
            begin
              NewHex := true;
              case ord( s[0] ) of 
                0: s := st[j];
                1: s := s + st[j];
                2: s := s[2] + st[j]
              end
            end;
          j := j + 1;
        end
    end
end;


begin { MAIN PROGRAMM }
  ClrScr;
  i := BdosHL( 12 ); { funktion 12: version number of operating systems }
  if i <> Version then Error( 0 );

  DefaultDrive := Bdos( 25 );  { funktion 25: get current drive }
  Drive := DefaultDrive;
  LastDrive := -1;             { invalid }
  Track := -1;                 { invalid }
  Lsector := 0;
  BufferValid := false;
  LastCmd := chr($FF);

  repeat
    if BufferValid then
      begin
        DisplaySector;
        Cmd := GetCommand( ['Q', 'F', 'R', 'N', 'P', 'M', 'W'] )
      end
    else
      Cmd := GetCommand( ['Q', 'F', 'R'] );

    case  Cmd of 
      'R':
           DoDisk( ReadSector );
      'N':
           begin { default: read next sector }
             if LastCmd in ['R', 'N', 'P']  then
               begin
                 Lsector := Lsector +  1;
                 if Lsector = MaxSector then
                   begin
                     Lsector := 0;
                     Track := Track + 1;
                     if Track = MaxTrack then Track := 0
                   end
               end;
             DoDisk( NextSector )
           end;
      'P':
           begin { read previous sector }
             if LastCmd in ['R', 'N', 'P']  then
               begin
                 Lsector := Lsector -  1;
                 if Lsector = -1 then
                   begin
                     Lsector := MaxSector - 1;
                     Track := Track - 1;
                     if Track = -1 then Track := MaxTrack - 1
                   end
               end;
             DoDisk( PreviousSector )
           end;
      'M':
           ModifySector;
      'W':
           DoDisk( WriteSector );
      'F':
           Format
    end;
    if Cmd = 'R' then
      LastCmd := 'N'
    else
      LastCmd := Cmd;
  until Cmd = 'Q';

  ClrScr;
  CrtExit;
  Bdos( 14, DefaultDrive )
    { restore status before program call }
end.
