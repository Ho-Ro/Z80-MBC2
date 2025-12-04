@echo off

sdasz80 -plosgff -o crt0.s

sdcc -c -mz80 -DNOSTRUCTASSIGN portme.c

sdcc -c -mz80 -DNOSTRUCTASSIGN dhry_1.c

sdcc -c -mz80 -DNOSTRUCTASSIGN dhry_2.c

rem sdcc -mz80 --no-std-crt0 crt0.rel dhry_1.rel dhry_2.rel portme.rel -o out.hex

rem srec_cat -disable-sequence-warnings out.hex -Intel -o load.hex -Intel

sdcc -mz80 --no-std-crt0 crt0.rel dhry_1.rel dhry_2.rel portme.rel -o temp.hex

srec_cat -disable-sequence-warnings temp.hex -Intel -o out.hex -Intel