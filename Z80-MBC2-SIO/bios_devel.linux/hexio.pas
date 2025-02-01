{ https://mark-ogden.uk/mirrors/www.cirsovius.de/CPM/Projekte/Artikel/TP/DirDisk/DirDisk.html }
{ INCLUDE-FILE HEXIO.PAS: }


type  string2 = string[2];


function HexVal(s: string2): integer; { convert 1 or 2 char ASCII input into byte value }
var i, j, m, n: integer;
  function NibbleVal (c: char): integer;
  begin
      c := UpCase (c);
      if not (c in ['0'..'9', 'A'..'F']) then NibbleVal := 257
         else if (c > '9') then NibbleVal := ord (c) - $37
                           else NibbleVal := ord (c) - $30
  end; { NibbleVal }
begin { HexVal }
      m := NibbleVal (s[1]);
      if (length (s) = 1) then HexVal := m
      else begin
           n := NibbleVal (s[2]);
           HexVal := 16 * m + n
      end
end; { HexVal }


procedure WriteHex (b: byte); { write byte value as two hex digits }
var b1: byte;
procedure WriteNibble (b: byte);
  begin
    b := b + $30; if (b > $39) then b := b + 7; write (chr(b))
  end;
begin
  b1 := b shr 4;   WriteNibble (b1);
  b1 := b and $0F; WriteNibble (b1)
end;
