{ https://mark-ogden.uk/mirrors/www.cirsovius.de/CPM/Projekte/Artikel/TP/DirDisk/DirDisk.html }

Function UBIOS (FN, A, BC, DE, HL: integer): integer;
{ BIOS access via CP/M 3.0 BDOS funktion No. 50 }
{ FN = BIOS funktion number, A = Akku, BC = register BC etc.  }

Type
  ParameterBlock = record
    func, Areg: byte;
    BCreg, DEreg, HLreg: integer
  end;

Var
  BiosPB: ParameterBlock;
  Result: integer;

begin
  with BiosPB do
    begin
      func  := FN;
      Areg  := A;
      BCreg := BC;
      DEreg := DE;
      HLreg := HL;
    end;
  Result := 0;
  case FN of 
    2,3,7,13,14,15,17,18,19,24:  Result := Bdos (50, Addr (BiosPB));
    9,16,20,22,25:               Result := BdosHL (50, Addr (BiosPB));
    else                         Bdos (50, Addr (BiosPB))
  end;
  UBIOS := Result
end; { UBIOS }
