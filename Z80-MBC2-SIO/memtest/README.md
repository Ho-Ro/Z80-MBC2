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

Under Linux, the `iload.py` tool can be used, which performs the upload in parallel with the open terminal with sufficient delays at the end of each line.

```
usage: iload.py [-h] [-p PORT] [-d DELAY] [hexfile]

Send Intel HEX text (from file or stdin) line-by-line to a serial port with delay.

positional arguments:
  hexfile            Path to the hex file to send (if omitted, read from stdin)

options:
  -h, --help         show this help message and exit
  -p, --port PORT    Serial port device (default: /dev/ttyUSB0)
  -d, --delay DELAY  Delay between lines in milliseconds (default: 100)
```

