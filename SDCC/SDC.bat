@echo off
rem
rem            SDC.BAT - Compile a C source file to target Z80-MBC2. Output file: out.hex
rem
rem            USAGE:    SDC <source_file.c>
rem
rem
rem            REQUIRED: IOS S220718-R290823 (and following revisions unless stated otherwise)
rem
rem            REQUIRED: Following files in the working dirctory:
rem                      S190818-R011023_crt0.rel;
rem                      S290923_Z80-MBC2.rel.
rem
rem            NOTE: S290923_Z80-MBC2.rel must be compiled with the -DZ80MBC2IRQ option 
rem                  (sdcc -c -mz80 -DZ80MBC2IRQ S290923_Z80-MBC2.c) to enable the IRQ support.
rem                  To compile S290923_Z80-MBC2.c with IRQ support disabled: sdcc -c -mz80 S290923_Z80-MBC2.c.
rem                  In both cases (IRQ enabled or not) you can use the SDC.BAT batch.

if .%1==. goto :error2
set scfile=%1

if not exist %scfile% goto :error1
sdcc -mz80 --no-std-crt0 S190818-R011023_crt0.rel %scfile% S290923_Z80-MBC2.rel -o temp.hex

if not %ERRORLEVEL%==0 goto :error3
echo No compiler errors.

rem Sorting the Intel-Hex output
if not exist srec_cat.exe goto :error4
srec_cat -disable-sequence-warnings temp.hex -Intel -o out.hex -Intel

echo All done! Output executable file (Intel-Hex): out.hex
goto :end

:error4
echo Error: utility srec_cat.exe not found!
echo Nothing to load to the target.
goto :end

:error3
echo Errors found in source file %scfile% during C compilation.
echo Nothing to load to the target.
goto :end

:error2
echo Please specify a source file!
echo USAGE:    %0 ^<source_file.c^>
goto :end

:error1
echo Error: file %scfile% not found!

:end