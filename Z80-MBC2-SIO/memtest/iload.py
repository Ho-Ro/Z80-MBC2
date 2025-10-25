#!/usr/bin/env python3
import sys
import time
import argparse
import re

# iload.py
# tool that uploads an intel hex file to Z80-MBC2
# input from the command line argument or stdin
# use the already open terminal port (default /dev/ttyUSB0 or change with -p <PORT>)
# send line by line, check for correct ihex syntax, ignore invalid lines
# add a delay (default 100 ms or change with -d <DELAY>) after each line to avoid overrunning

# Regular expression for Intel HEX line format
INTEL_HEX_RE = re.compile(r"^:[0-9A-Fa-f]{2}(?:[0-9A-Fa-f]{4}[0-9A-Fa-f]{2}(?:[0-9A-Fa-f]{2})*)?[0-9A-Fa-f]{2}$")

def is_valid_intel_hex(line: str) -> bool:
    """Check if a line is a valid Intel HEX record."""
    line = line.strip()
    if not INTEL_HEX_RE.match(line):
        return False
    # Optional checksum validation
    try:
        # Convert hex pairs (after ':') to bytes
        bytestr = bytes.fromhex(line[1:])
        checksum = sum(bytestr) & 0xFF
        return checksum == 0
    except ValueError:
        return False

def main():
    parser = argparse.ArgumentParser(
        description="Send Intel HEX text (from file or stdin) line-by-line to a serial port with delay.",
        add_help=True
    )
    parser.add_argument(
        "hexfile", nargs="?",
        help="Path to the hex file to send (if omitted, read from stdin)"
    )
    parser.add_argument(
        "-p", "--port", default="/dev/ttyUSB0",
        help="Serial port device (default: /dev/ttyUSB0)"
    )
    parser.add_argument(
        "-d", "--delay", type=float, default=100,
        help="Delay between lines in milliseconds (default: 100)"
    )

    args = parser.parse_args()
    delay_seconds = args.delay / 1000.0

    infile = open(args.hexfile, "r") if args.hexfile else sys.stdin

    try:
        with infile, open(args.port, "w", buffering=1) as tty:
            for lineno, line in enumerate(infile, 1):
                stripped = line.strip()
                if not stripped:
                    continue
                if not is_valid_intel_hex(stripped):
                    print(f"Warning: line {lineno} is not valid Intel HEX, skipped.", file=sys.stderr)
                    continue
                tty.write(line)
                tty.flush()
                time.sleep(delay_seconds)
    except FileNotFoundError:
        print(f"Error: file '{args.hexfile}' not found.", file=sys.stderr)
        sys.exit(1)
    except PermissionError:
        print(f"Error: permission denied when accessing {args.port}.", file=sys.stderr)
        print("Try running as root or adjust device permissions.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
