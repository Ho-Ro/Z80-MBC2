# GENCPM.DAT buffer size calculation

## Directory buffer
Directory bufers are created in BANK0 only!

### Memory usage

    (NDIRRECx * 2 + 1) B0pages (256 B)

## Data buffer
Data buffers can be created in other banks (N=2..MAXBANK) too,
but they use also B0pages depending on their size
(calculation not yet fully understood).

### Memory usage

    NDTARECx * 2 BNpages (256 B)
    NDTARECx <  0x08: -> + 0 B0pages
    NDTARECx < ~0x18: -> + 1 B0pages
    NDTARECx < ~0x30: -> + 2 B0pages
    NDTARECx < ~0x40: -> + 3 B0pages
    ...
    NDTARECx > ~0x80: -> + 8 B0pages


## Key Principles for Buffer Optimization
### Directory Buffers (NDIRRECx):

#### Purpose
Cache directory entries (file names, attributes) to speed up
directory operations (DIR, file searches).

#### When to Increase
Systems with frequent directory traversal or many small files
benefit from larger directory buffers.

#### Tradeoff
Directory buffers consume limited pages in BANK0.

### Data Buffers (NDTARECx):
#### Purpose
Cache file data to reduce physical disk reads/writes during file access.

#### When to Increase
Systems handling large files or performing intensive read/write
operations (e.g., databases, compilers) require more data buffers.

#### Tradeoff
Big data buffers consume also pages in BANK0 needed for dir buffer.
