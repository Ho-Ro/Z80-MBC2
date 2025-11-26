#!/usr/bin/env python3
"""
iload.py - Send text, Intel HEX, or binary files to a serial port line by line.

Purpose:
- Send binary or Intel HEX files to the Z80-MBC2, using its iLoad function.
- Send generic text files, that can be pasted into an CP/M editor, e.g. ZED.
Features:
- Text mode: send lines as-is or auto-detect Intel HEX lines and verify checksums.
- Binary mode: send binary files as Intel HEX, with required starting address.
- Configurable delay between lines (default 50 ms).
- Optional verbose mode (-v) for detailed output.
- Line-ending options: CRLF (-c), LF (-l), CR (-r) (mutually exclusive).
- Input can be a file or stdin.
"""

import sys
import time
import argparse
import re
import os

HEX_LINE_RE = re.compile(r"^:[0-9A-Fa-f]{2}(?:[0-9A-Fa-f]{4}[0-9A-Fa-f]{2}(?:[0-9A-Fa-f]{2})*)?[0-9A-Fa-f]{2}$")

def is_hex_candidate(line: str) -> bool:
    return bool(HEX_LINE_RE.match(line.strip()))

def is_valid_intel_hex(line: str) -> bool:
    line = line.strip()
    if len(line) < 11:
        return False
    if not is_hex_candidate(line):
        return False
    try:
        data = bytes.fromhex(line[1:])
    except ValueError:
        return False
    checksum = sum(data) & 0xFF
    return checksum == 0

def main():
    parser = argparse.ArgumentParser(
        description="Send text, Intel HEX, or binary data to a serial port with delay."
    )

    parser.add_argument("textfile", nargs="?", help="Input file (or stdin if omitted)")
    parser.add_argument("-p", "--port", default="/dev/ttyUSB0",
                        help="Serial port (default: /dev/ttyUSB0)")
    parser.add_argument("-d", "--delay", type=float, default=50,
                        help="Delay between lines in milliseconds (default: 50)")
    parser.add_argument("-t", "--text", action="store_true",
                        help="Treat all input as plain text (disable HEX detection)")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Verbose output")

    # Mutually exclusive line endings
    group = parser.add_mutually_exclusive_group()
    group.add_argument("-c", "--crlf", action="store_true", help="Send CRLF (\\r\\n)")
    group.add_argument("-l", "--lf", action="store_true", help="Send LF (\\n)")
    group.add_argument("-r", "--cr", action="store_true", help="Send CR (\\r)")

    # Binary mode with required starting address
    parser.add_argument(
        "-b", "--binary",
        metavar="ADDR",
        help="Binary mode: required starting hex address, e.g. -b 4000",
        type=str
    )

    args = parser.parse_args()
    delay_seconds = args.delay / 1000.0

    # Determine forced line ending
    if args.crlf:
        forced_ending = "\r\n"
    elif args.lf:
        forced_ending = "\n"
    elif args.cr:
        forced_ending = "\r"
    else:
        forced_ending = None

    # --- BINARY MODE (Intel HEX output) ---
    if args.binary is not None:
        try:
            start_addr = int(args.binary, 16)
        except ValueError:
            print(f"Error: invalid binary start address '{args.binary}'", file=sys.stderr)
            sys.exit(1)

        # Determine input file
        if args.textfile:
            if not os.path.isfile(args.textfile):
                print(f"Error: file '{args.textfile}' not found.", file=sys.stderr)
                sys.exit(1)
            with open(args.textfile, "rb") as f:
                data = f.read()
        else:
            data = sys.stdin.buffer.read()

        if args.verbose:
            print(f"[VERBOSE] Binary->Intel HEX mode, start address = 0x{start_addr:04X}")

        def make_hex_line(addr, chunk):
            """Create a complete Intel HEX line for a given address and data block."""
            ll = len(chunk)
            a_hi = (addr >> 8) & 0xFF
            a_lo = addr & 0xFF
            record = [ll, a_hi, a_lo, 0x00] + list(chunk)
            checksum = (-sum(record)) & 0xFF
            hexdata = "".join(f"{b:02X}" for b in record)
            return f":{hexdata}{checksum:02X}"

        try:
            with open(args.port, "w", buffering=1) as tty:
                addr = start_addr
                block_size = 16
                for offset in range(0, len(data), block_size):
                    chunk = data[offset:offset + block_size]
                    line = make_hex_line(addr, chunk)
                    tty.write(line + "\n")
                    tty.flush()

                    if args.verbose:
                        print(f"[VERBOSE] HEX {addr:04X}-{addr+len(chunk)-1:04X}: {line}")

                    addr += len(chunk)
                    time.sleep(delay_seconds)

                # End-of-file record
                eof = ":00000001FF"
                tty.write(eof + "\n")
                tty.flush()
                if args.verbose:
                    print("[VERBOSE] Sent EOF record:", eof)

        except PermissionError:
            print(f"Error: permission denied when accessing {args.port}.", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

        return  # binary mode ends here

    # ----- TEXT / HEX MODE -----
    infile = open(args.textfile, "r") if args.textfile else sys.stdin

    try:
        with infile, open(args.port, "w", buffering=1) as tty:
            for lineno, original_line in enumerate(infile, 1):
                # Detect original line ending
                if original_line.endswith("\r\n"):
                    base = original_line[:-2]
                    original_ending = "\r\n"
                elif original_line.endswith("\n"):
                    base = original_line[:-1]
                    original_ending = "\n"
                elif original_line.endswith("\r"):
                    base = original_line[:-1]
                    original_ending = "\r"
                else:
                    base = original_line
                    original_ending = ""

                stripped = base.strip()

                # HEX verification
                if not args.text and is_hex_candidate(stripped):
                    if not is_valid_intel_hex(stripped):
                        print(f"Warning: invalid HEX checksum at line {lineno}, skipped.",
                              file=sys.stderr)
                        if args.verbose:
                            print("[VERBOSE] Skipped:", stripped, file=sys.stderr)
                        continue
                    else:
                        if args.verbose:
                            print(f"[VERBOSE] HEX OK line {lineno}: {stripped}")

                # Determine final newline
                newline = forced_ending if forced_ending is not None else original_ending

                # Send the line
                tty.write(base + newline)
                tty.flush()

                if args.verbose:
                    print(f"[VERBOSE] Sent line {lineno}: {repr(base + newline)}")

                time.sleep(delay_seconds)

    except FileNotFoundError:
        print(f"Error: file '{args.textfile}' not found.", file=sys.stderr)
        sys.exit(1)
    except PermissionError:
        print(f"Error: permission denied when accessing {args.port}.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
