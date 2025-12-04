@echo off
rem
rem            L.BAT - Load an intel-hex file to the target Z80-MBC2 using the iLoad boot mode
rem
rem            USAGE:      L <intel-hex-file.hex>
rem            OR:         L
rem
rem ***************************************************************************************
rem
rem Adapt the two following settings to your system configuration!
rem 
rem Note 1: comport=3 means COM3:
rem Note 2: teratermpath is the complete TeraTerm path (e.g. "C:\Program Files\teraterm\")
rem Note 3: the LoadZ80.ttl TeraTerm macro must be placed inside the teraterm folder.
rem
rem ***************************************************************************************
rem
set teratermpath="C:\Programmi\teraterm\"
set comport=3

set teratermmacro=LoadZ80.ttl
set serialspeed=115200
echo * * * Serial speed is %serialspeed% * * *
set ldfile=out.hex
if .%1==. goto :nofile
set ldfile=%1

:load
echo File to load: %ldfile% (it will be copied into load.hex)
if not exist %ldfile% goto :error1
if not exist %teratermpath%%teratermmacro% goto :error2
copy /y %ldfile% load.hex > nul
echo * * * Remember to close the Tera Term windows before a new upload! * * *
"%teratermpath%ttermpro.exe" /c=%comport% /BAUD=%serialspeed% /w="Z80-MBC2 Terminal" /m=%teratermmacro%

echo All done. Bye bye...
goto :end

:nofile
echo Loading last compiled file (%ldfile%).
goto :load

:error2
echo Error: TeraTerm macro file %teratermmacro% not found 
echo        inside path %teratermpath%!
goto :end

:error1
echo Error: file %ldfile% not found!
:end