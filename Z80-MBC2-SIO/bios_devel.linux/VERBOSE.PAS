program verbose;

const
    {Z80-MBC2 IOS opcodes and port addresses}
    VERBOSE_ReadOpcode = 254;
    VERBOSE_WriteOpcode = 126;
    STORE_Opcode_Port = 1;
    EXECUTE_WriteOpcode_Port = 0;
    EXECUTE_ReadOpcode_Port = 0;

var
    verbosity, new: byte;
    par : string[1];
    ch : char;


function  getVerbosity: byte;
{Return the verbosity level}
begin
    port[STORE_Opcode_Port] := VERBOSE_ReadOpcode;
    getVerbosity := port[EXECUTE_ReadOpcode_Port];
end;


procedure setVerbosity(v: byte);
{Set verbosity level}
begin
    port[STORE_Opcode_Port]:= VERBOSE_WriteOpcode;
    port[EXECUTE_WriteOpcode_Port] := v;
end;


begin
    new := $FF;
    if paramcount > 0 then
    begin
        par := paramstr(1);
        new := ord(par[1]) - $30; { char to digit }
    end;

    {Get current verbosity value}
    verbosity := getVerbosity;

    if (new <> $FF) and (new <> verbosity) then
    begin
        setVerbosity( new );
        new := getVerbosity;
        writeln( 'verbosity: ', verbosity, ' -> ', new );
    end
    else
        writeln( 'verbosity: ', verbosity );
end.

