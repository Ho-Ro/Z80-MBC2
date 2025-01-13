program verbose;

const
    {Z80-MBC2 IOS opcodes and port addresses}
    VERBOSE_ReadOpcode = 254;
    VERBOSE_WriteOpcode = 126;
    STORE_Opcode_Port = 1;
    EXECUTE_WriteOpcode_Port = 0;
    EXECUTE_ReadOpcode_Port = 0;

var
    verbosity, new: integer;


function  getVerbosity: integer;
{Return the verbosity level}
begin
    port[STORE_Opcode_Port] := VERBOSE_ReadOpcode;
    getVerbosity := port[EXECUTE_ReadOpcode_Port];
end;


procedure setVerbosity(v: integer);
{Set verbosity level}
begin
    port[STORE_Opcode_Port]:= VERBOSE_WriteOpcode;
    port[EXECUTE_WriteOpcode_Port] := v;
end;


begin

    {Get current verbosity value}
    verbosity := getVerbosity;
    writeln('Current verbosity: ', verbosity );

    write( 'Set new verbosity: ' );
    readln( new );

    if new <> verbosity then
    begin
        setVerbosity( new );
    end;

    {Get new verbose value}
    verbosity := getVerbosity;
    writeln( 'new verbosity: ', verbosity );
end.
