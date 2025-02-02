{ https://mark-ogden.uk/mirrors/www.cirsovius.de/CPM/Projekte/Artikel/TP/DirDisk/DirDisk.html }

Program Disk3;  { ---- DISK EDITOR FOR CP/M 3.0 ---- }
                { (c) 1984 by Gerhard Strube, Munich }

Const
  MaxSize = 1024;   { max physical sector size }
  Version = $0031;  { version number CP/M plus }

Type
  DPB = record               { CP/M 3.0 disk parameter block:   }
    SPT:           integer;  { number of log. sectors per track }
    BSH, BLM, EXM: byte;     { block shift & mask / extent mask }
    DSM, DRM:      integer;  { capacity of disk & directory     }
    AL0, AL1:      byte;     { reserved blocks for directory    }
    CKS, OFF:      integer;  { checksum / reserv. tracks        }
    PSH, PHM:      byte      { physical record shift & mask     }
  end;
  RWtype = ( ReadSector, WriteSector );  { type of disk access }

Var
  Drive, Track,
  Sector, Lsector, Psector,
  Part, Psize,
  MaxSector,  MaxTrack,
  DefaultDrive,
  i, j, k:                   integer;
  DriveChr, Cmd:             char;
  ptr:                       ^DPB absolute i;
  DPH:                       ^integer absolute   i;
  PhySecBuf:                 array [1..MaxSize] of byte;
  LogSecBuf:                 array [1..128] of byte;


{$I UBIOS.PAS }  { external funktion UBIOS for BIOS calls }
{$I HEXIO.PAS }  { ext. funkt. HEXVAL, ext. procedure WRITEHEX }


Procedure Header;
begin
  GotoXY( 1, 1 );
  Write( 'Disk editor for CP/M PLUS (c) 1984 by Gerhard Strube');
end;


Procedure Error( no: integer ); { show error message and exit program }
begin
  GotoXY( 10, 18 );
  case no of
    0: Write( 'Program requires CP/M 3.0 (CP/M PLUS).' );
    1: Write( 'Error: Invalid drive.' );
    2: Write( 'Error during seek / read / write.' )
  end;
  Bdos( 14, DefaultDrive );
  Halt
end;


Procedure UserFrame( Mode: RWtype ); { screen mask and data input }
begin
  if Mode = ReadSector then
    ClrScr;
  LowVideo;
  Header;
  GotoXY( 1, 3 );
  case Mode of
    ReadSector:  Write( 'READ ' );
    WriteSector: Write( 'WRITE' )
  end;
  HighVideo;
  DriveChr := chr( Drive + $41 );    { 0..15 -> 'A'..'P' }
  GotoXY( 13, 3 );
  Write( 'DRIVE LETTER    (A, B, ..): ', DriveChr, chr( 8 ) );
  repeat
    DriveChr := UpCase( char( Bdos( 1 ) ) );
    if DriveChr < ' ' then
      DriveChr := chr( Drive + $41 );
    GotoXY( 41, 3 );
    Write( DriveChr );
  until ( DriveChr in ['A'..'P']);
  Drive := ord( DriveChr ) - $41;    { ord('A) }
  i := UBIOS( 9, 0, Drive, 0, 0 );   { select drive }
  if i = 0 then Error( 1 );
  Bdos( 14, Drive );
  i := BdosHL( 31 );   { address of DPB; i and ptr have the same address! }
  with ptr^ do
    begin
      MaxSector := SPT;
      k := ( DSM + 1 ) * ( ( BLM + 1 ) div 8 );
      GotoXY( 49, 3 );
      Write( k:5, ' KB capacity' );
      MaxTrack := round( ( k / SPT ) * 8 + OFF );
      GotoXY( 49, 4 );
      Write( MaxTrack:5, ' tracks, ', OFF, ' reserv.' );
      GotoXY( 49, 5 );
      Write( SPT:5, ' log. sectors/track' );
      Psize := 128 shl PSH;
      GotoXY( 49, 6 );
      Write( Psize:5, ' phys. sector size' );
      if ( Psize = 128 ) then
        begin
          GotoXY( 55,7 );
          Write( '(BIOS deblocking?)' )
        end;
      Psize := 1 shl PSH;
      repeat
        GotoXY( 13, 4 );
        Write( 'TRACK NUMBER    (0 ..',(MaxTrack -1): 4, '): ' );
        Write( Track, chr( 8 ) );
        if Track > 9  then Write( chr( 8 ) );
        if Track > 99 then Write( chr( 8 ) );
        readln( Track )
      until ( Track >= 0 ) and ( Track < MaxTrack );
      Sector := Lsector;
      repeat
        GotoXY( 13, 5 );
        Write( 'SECTOR NUMBER   (0 ..', (SPT - 1): 4, '): ' );
        Write( Sector, chr( 8 ) );
        if Sector > 9  then Write( chr( 8 ) );
        if Sector > 99 then Write( chr( 8 ) );
        readln( Sector )
      until ( Sector >= 0 ) and ( Sector < SPT );
      Lsector := Sector
    end;
  Part := Sector mod Psize;     { make logical to physical }
  Sector := Sector div Psize;   { sector size translation  }
end;


Procedure DoDisk( Mode: RWtype ); { execute disk operation }
begin
  UserFrame( Mode );
  i := UBIOS( 9, 0, Drive, 1, 0 ); { selekt disk }
    { i = address of translation table log. -> phys. sector }
  Psector := UBIOS( 16, 0, Sector, DPH^, 0 ); { calculate phys. sector }
  GotoXY( 13, 6 );
  if Psize > 1 then
    Write( 'part ', Part, ' of ' );
  Write( 'phys. sector ', Psector );
  i := UBIOS( 23, 0, 1, 0, 0 );                { execute 1 sector   }
  i := UBIOS( 10, 0, Track, 0, 0 );            { select track       }
  i := UBIOS( 11, 0, Psector, 0, 0 );          { select sector      }
  i := UBIOS( 12, 0, Addr( PhySecBuf ), 0, 0); { select DMA address }
  i := UBIOS( 28, 1, 0, 0, 0 );                { select RAM bank    }
  case Mode of
    ReadSector:
                begin
                  i := UBIOS( 13, 0, 0, 0, 0 );  { read phys. sector     }
                  if i <> 0 then Error( 2 );
                  for i := 1 to 128 do           { "extract" log. sector }
                    LogSecBuf[i] := PhySecBuf[i + Part * 128]
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


Procedure DisplaySector; { show log. sector content on screen }
begin
  for i := 20 to 23 do
    begin
      GotoXY( 1, i );
      ClrEol
    end;
  GotoXY( 1, 8 );
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


Procedure ChangeSector; { change content of log. sector }
Var
  st:     string[80];
  s:      string[2];
  NewHex: boolean;
begin { ChangeSector }
  repeat
    GotoXY( 1,20 );
    ClrEol;
    Write( 'Change content starting at address: 0', chr( 8 ) );
    readln( st );
    i := 0;
    if length( st ) in [1..2] then i := HexVal( st )
  until i in [$00..$7F];
  i := i + 1; { cange to index $01..$80 }
  GotoXY( 1 , 21 );
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
  i := BdosHL( 12 ); { funktion 12: version number of operating systems }
  if i <> Version then Error( 0 );
  Cmd := char( $FF ); { ignore additional returns }
  ClrScr;
  LowVideo;
  Header;
  GotoXY( 1, 3 );
  HighVideo;
  Write ( 'Enter command:  Q' );
  LowVideo;
  Write( 'uit, ' );
  HighVideo;
  Write( 'R' );
  LowVideo;
  Write( 'ead: ' );
  HighVideo;
  repeat
    GotoXY( 29,3 );
    Write( ' ', char( 8 ) );
    Cmd := UpCase( char( Bdos( 1 ) ) ); { ConIn }
  until  Cmd in ['Q', 'R'];
  GotoXY( 29,3 );
  Write( Cmd );
  if Cmd = 'Q' then
    begin
      CrtExit;
      Halt
    end;

  DefaultDrive := Bdos( 25 );  { funktion 25: get current drive }
  Track := 0;
  Lsector := 0;
  Drive := DefaultDrive;
  DoDisk( ReadSector );
  repeat
    DisplaySector;
    Cmd := char( $FF ); { ignore additional returns }
    GotoXY( 1,18 );
    ClrEol;
    HighVideo;
    Write ( 'Enter command:  Q' );
    LowVideo;
    Write( 'uit, ' );
    HighVideo;
    Write( 'R' );
    LowVideo;
    Write( 'ead, ' );
    HighVideo;
    Write( 'M' );
    LowVideo;
    Write( 'odify, ' );
    HighVideo;
    Write( 'W' );
    LowVideo;
    Write( 'rite: ' );
    HighVideo;
    repeat
      GotoXY( 44,18 );
      Write( ' ', chr( 8 ) );
      Cmd := UpCase( chr( Bdos( 1 ) ) ); { ConIn }
    until  Cmd in ['Q', 'R', 'M', 'W'];
    GotoXY( 44,18 );
    Write( Cmd );
    case  Cmd of
      'R':
           begin { default: read next sector }
             Lsector := Lsector +  1;
             if Lsector = MaxSector then
               begin
                 Lsector := 0;
                 Track := Track + 1;
                 if Track = MaxTrack then Track := 0
               end;
             DoDisk( ReadSector )
           end;
      'M': ChangeSector;
      'W': DoDisk( WriteSector )
    end
  until Cmd = 'Q';
  CrtExit;
  Bdos( 14, DefaultDrive )
    { restore status before program call }
end.
