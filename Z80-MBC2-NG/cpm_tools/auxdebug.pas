PROGRAM AUXdebug;

FUNCTION KeyPressed : Boolean;
BEGIN
  (* BDOS function 6 with E=$FF:
     Non-blocking test for console key.
     Returns 0 if no key, else ASCII code. *)
  KeyPressed := BDOS(6, $FF) <> 0;
END;

FUNCTION AuxReady : Boolean;
BEGIN
  (* BDOS function 7 (A_STATIN):
     Returns $FF if AUXIN has a character ready,
     otherwise returns 0. *)
  AuxReady := BDOS(7, 0) = $FF;
END;

FUNCTION HexDigit(n: Byte): Char;
BEGIN
  n := n AND $0F;
  IF n < 10 THEN
    HexDigit := Chr(Ord('0') + n)
  ELSE
    HexDigit := Chr(Ord('A') + (n - 10));
END;

PROCEDURE PrintByte(b: Byte);
BEGIN
  IF ( ( b >= $20 ) AND (b < $80 ) ) THEN
    Write( Chr( b ) )
  ELSE
    Write( '.' );
  Write( ' ', HexDigit(b SHR 4), HexDigit(b), ' ' );
END;

VAR
  ch : Integer;
  col : Integer;

BEGIN
  col := 0;
  Writeln( 'Checking AUX: input, press any key to exit.' );
  REPEAT
    (* Check whether AUXIN has a character available *)
    WHILE AuxReady DO
      BEGIN
        (* BDOS function 3: AUXIN (blocking, but safe now because AuxReady checked) *)
        ch := BDOS(3, 0);
        PrintByte( ch );
        col := col + 5;
        IF col >= 80 THEN
          BEGIN
            WriteLn;
            col := 0;
          END
      END;

  UNTIL KeyPressed;
END.
