Program termsize;

{
program calls BDOS to get the terminal size values out of the system control block SCB
BDOS call 49,
DE is the address of a SCB parameter block:
pb   DB offset
     DB set ; $00: get a byte, $FE set a word, $FF set a byte
     DW value ; byte/word to set, unused for get
return value: get byte
}

Const
  HexChar : Array[0..15] of Char = '0123456789ABCDEF';

Type
  Str2 = String[2];
  Str4 = String[4];

Var
  ver : Integer;
  pb : Array[1..4] of Byte;
  scb : Integer;
  cols : BYte;
  rows : Byte;
  bios : Integer absolute $0001;
  hex : Str4;

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


Begin
  hex := itox( bios - 3 );
  Writeln( 'Bios: ', hex ); { Address of BIOS warm start jump }
  ver := Bdos( 12 ); { get CP/M version }
  If ver = $31 Then  { $31 = CP/M 3.1 -> SCB available }
  Begin
    { Get screen size directly from SCB }
    { SCB: https://www.seasip.info/Cpm/scb.html }
    pb[1] := $3A; { get SCB address }
    pb[2] := 0;
    pb[3] := 0;
    pb[4] := 0;
    scb := BdosHL( 49, Addr(pb) );
    hex := itox( scb );
    Writeln( 'SCB:  ', hex );
    { $xx9C: start of SCB }
    { $XXB6: Console width [eg 79 for 80-column screen] }
    { $XXB8: Console length [eg 23 for 24-line screen] }
    cols := Mem[ scb - $9C + $B6 ] + 1;
    rows := Mem[ scb - $9C + $B8 ] + 1;
    Writeln( 'Screen size (SCB):  ', cols, 'x', rows );

    { get screen size from SCB via BDOS calls }
    pb[1] := $1A; { get console width - 1 }
    cols := Bdos( 49, Addr(pb) ) + 1;
    pb[1] := $1C; { get console height - 1 }
    rows := Bdos( 49, Addr(pb) ) + 1;
    Writeln( 'Screen size (BDOS): ', cols, 'x', rows );
  End
  Else Writeln( 'Wrong CP/M version (', ver, ')' )
End.
