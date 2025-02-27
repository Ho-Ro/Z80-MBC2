
Program AUXTERM;

{ simple serial communication program for AUX: }
{ read AUXIN: and write to CONOUT: (echo also to AUXOUT:) }
{ read CONIN: and write to AUXOUT: }
{ convert $0D -> $0D $0A for both directions }
{ exit with $1A$18 (^Z^X) }


Const
  { BDOS FUNCTIONS }
  CONIN  : Byte = 1;
  CONOUT : Byte = 2;
  AUXIN  : Byte = 3;
  AUXOUT : Byte = 4;
  AUXIST : Byte = 7;
  AUXOST : Byte = 8;
  CONIST : Byte = 11;
  LF     : Byte = $0A;
  CR     : Byte = $0D;


Var
  ver : Integer;
  iStat : Byte;
  oStat : Byte;
  inp   : Byte;
  loop : Boolean;
  cmdMode : Boolean;


begin
  Writeln( '*** AUX: terminal test program  -  exit with ^Z^X ***' );
  loop := True;
  cmdMode := False;
  while loop do
    begin

      if Bdos( CONIST ) = 1 then
        begin
          inp := Bdos( CONIN );
          if not cmdMode then  { terminal cmd mode }
            begin
              if inp = $1A then { ^Z }
                cmdMode := True   { enter cmd mode }
              else
                begin  { normal terminal mode }
                  cmdMode := False;
                  Bdos( AUXOUT, inp );
                  if inp = CR then
                    begin
                      Bdos( AUXOUT, LF );
                      Bdos( CONOUT, LF )
                    end
                end
            end
          else  { command mode }
            begin
              case inp of 
                $18: { ^Z^X -> exit }
                     begin
                       WriteLn;
                       loop := False;
                     end;
                $1A: { ^Z^Z -> output ^Z }
                     Bdos( AUXOUT, inp );
              end;
              cmdMode := False
            end
        end;

      if Bdos( AUXIST ) <> 0 then { char available }
        begin
          inp := Bdos( AUXIN ); { get it }
          Bdos( CONOUT, inp );  { show }
          Bdos( AUXOUT, inp );  { echo }
          if inp = CR then      { CR -> CRLF }
            begin
              Bdos( CONOUT, LF );
              Bdos( AUXOUT, LF )
            end
        end;

    end;  { do }
  WriteLn( '*** EXIT ***' );
end.
