# GENCPM.DAT

## System Configuration
Based on tests, two configurations were created for gencpm3:

- [gen128k.dat](gen128k.dat) for the standard Z80-MBC2 version with 128 Kbytes
- [gen512k.dat](gen512k.dat) for the HW modification with 512 (or 256) Kbytes.

The *small* variant uses the entire 128 K RAM (4 x 32 K, 1 common and 3 banks), [-> log](gen128k.log).
The *large* variant uses 7 x 32 K RAM (1 common and 6 banks 0x00..0x05), [-> log](gen512k.log)
and leaves the remaining 9 banks 0x06..0x0E (288 KB) unused, which can be used e.g. as a RAM disk.

To create `cpm3.sys`, the corresponding variant must be copied or linked as `gencpm.dat`.

##  Buffer Size Calculation

### Directory Buffers (NDIRRECx)
Directory bufers are created in BANK0 only!

#### Purpose
Cache directory entries (file names, attributes) to speed up
directory operations (DIR, file searches).

#### Memory Usage

    (NDIRRECx * 2 + 1) B0 pages (256 B)

#### When to Increase
Systems with frequent directory traversal or many small files
benefit from larger directory buffers.

#### Tradeoff
Directory buffers consume limited pages in BANK0.


### Data Buffers (NDTARECx)
Data buffers can be created in other banks (N=2..MAXBANK) too,
but depending on their size, they also use different numbers of
B0 pages (not documented, calculation not yet entirely clear).

#### Purpose
Cache file data to reduce physical disk reads/writes during file access.

#### Memory Usage

    NDTARECx * 2             BN pages (256 B)
    NDTARECx <= 0x08: -> + 0 B0 pages
    NDTARECx < ~0x18: -> + 1 B0 pages
    NDTARECx < ~0x30: -> + 2 B0 pages
    NDTARECx < ~0x40: -> + 3 B0 pages
    ...
    NDTARECx > ~0x80: -> + 8 B0 pages

#### When to Increase
Systems handling large files or performing intensive read/write
operations (e.g., databases, compilers) require more data buffers.

#### Tradeoff
Big data buffers consume also pages in BANK0 needed for dir buffer.

