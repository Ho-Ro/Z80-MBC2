# memtest

- memtest - tests all banks and stops (HALT, 0x76)
- memloop - tests all banks and starts again (can be used for stability tests, e.g. for overclocking)

Warning, both tests require a current IOS version that supports the RAM modification and reports the RAM size via 0x83 alias SYSFLAGS, otherwise only the first 128 kB will be tested.

## how to build

* install zasm from https://github.com/Megatokio/zasm/releases
* make

(tested with zasm 4.4.17 for linux amd64)

## how to start

Use the IOS option 5 `iload` and paste the contents of the `memtest.hex` or `memloop.hex` file into the terminal.
Note that you must send the file in small blocks of 5 to 10 ihex lines or slow down your terminal if checksum errors occur during pasting.

Under Linux, the `iload` tool can be used, which performs the upload in parallel with the open terminal with sufficient delays at the end of each line.

```
usage: iload [-h] [-p PORT] [--baud BAUD] [-d DELAY]
             [-v] [-t] [--eof] [-c | -l | -r] [-b ADDR]
             [textfile]

Send text, Intel HEX, or binary data to a serial port.

positional arguments:
  textfile           Input file (or stdin if omitted)

options:
  -h, --help         show this help message and exit
  -p, --port PORT    Serial port (default: /dev/ttyUSB0)
  --baud BAUD        Baud rate (default: 115200)
  -d, --delay DELAY  Delay between lines in ms (default: 50)
  -v, --verbose      Verbose output
  -t, --text         Treat input as plain text (disable HEX checking)
  --eof              Send CTRL-Z (0x1A) after transmission
  -c, --crlf         Use CRLF (\r\n)
  -l, --lf           Use LF (\n)
  -r, --cr           Use CR (\r)
  -b, --binary ADDR  Binary mode: required starting hex address, e.g. -b 4000
```
