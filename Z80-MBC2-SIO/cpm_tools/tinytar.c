/* SPDX-License-Identifier: GPL-3.0-or-later
 *
 * tinytar.c - A minimal ANSI C89-compatible TAR archive utility.
 *
 * This program implements a simplified version of the UNIX tar utility,
 * supporting the creation, listing, extraction, and appending of files
 * to a standard POSIX/GNU-compatible TAR archive (USTAR format).
 *
 * Supported Modes (UNIX-compatible syntax):
 *   -cf archive.tar file1 [file2 ...]  # Create a new archive from files
 *   -rf archive.tar file1 [file2 ...]  # Append files to an existing archive
 *   -xf archive.tar                    # Extract all files from an archive
 *   -tf archive.tar                    # List contents of an archive
 *   archive.tar                        # Same as -tf archive.tar
 *
 * Features:
 *   - Fully ANSI C89 compatible (no POSIX-specific functions used).
 *   - Uses only the standard C library (stdio.h, string.h, etc.).
 *   - Validates USTAR magic to ensure archive format correctness.
 *   - Appending safely handles existing TAR structure and trailing blocks.
 *   - Automatically overwrites and rewrites final zero blocks.
 *   - Stores file modification time (or current time if mtime is missing).
 *   - Creates smaller files than (uncompressed) UNIX tar because it puts
 *     only 2 empty blocks at the archive end (as defined in the standard)
 *     instead of padding the archive to a multiple of 10 KiBi.
 *
 * Limitations:
 *   - Flat archives only (no directory tree structure).
 *   - No support for special files (symlinks, devices, etc.).
 *   - No built-in compression (to maintain POSIX/GNU tar compatibility).
 *
 * Target:
 *   The program is mainly intended for small 8-bit systems like CP/M 3.0
 *   that do provide neither directories nor specials files.
 *   It supports the grouping of multiple files and the transfer between
 *   CP/M and Linux with tools like KERMIT or [XYZ]MODEM.
 *
 * Building on Linux:
 *   gcc -Wall -Wextra -Wpedantic -std=c89 -o tinytar tinytar.c
 *
 * Building on CP/M with HI-TECH C:
 *   Use version V3.09-17 from https://github.com/agn453/HI-TECH-Z80-C
 *   cc -o -v -etar.com tinytar.c
 *   This creates the file tar.com that resembles the std tar commands.
 *
 * Author: Martin Homuth-Rosemann
 * License: GPL-3.0-or-later
 */

#define VERSION "20250423"

#include <ctype.h>  /* isprint */
#include <stdio.h>  /* fopen, fread, fwrite, fclose, printf, sprintf */
#include <stdlib.h> /* malloc, free, exit */
#include <string.h> /* strncpy, memset, strlen */
#include <time.h>   /* time_t */
#ifdef z80
#define const
#include <stat.h> /* for stat, struct stat, S_IFREG */
#ifndef S_ISREG   /* missing macro */
#define S_ISREG( m ) ( ( (m)&S_IFMT ) == S_IFREG )
#endif
#else
#include <sys/stat.h> /* for stat, struct stat, S_IFREG */
#endif

#define BLOCK_SIZE 512

/* -------------------- TAR HEADER STRUCTURE -------------------- */
struct tar_header {
    char name[ 100 ];      /* ascii */
    char mode[ 8 ];        /* octal 0644 */
    char uid[ 8 ];         /* octal 0 */
    char gid[ 8 ];         /* octal 0 */
    char size[ 12 ];       /* octal */
    char mtime[ 12 ];      /* octal */
    char chksum[ 8 ];      /* octal */
    char typeflag;         /* char */
    char linkname[ 100 ];  /* ignore */
    char magic[ 8 ];       /* "ustar  " */
    char uname[ 32 ];      /* ascii "user" */
    char gname[ 32 ];      /* ascii "group" */
    char devmajor[ 8 ];    /* ignore */
    char devminor[ 8 ];    /* ignore */
    char prefix[ 155 ];    /* ignore */
    char pad[ 12 ];        /* fill to 512 byte */
};


/* -------------------- HELPERS -------------------- */
long octal_to_long( const char *str, int len ) {
    long value = 0;
    int i;
    for ( i = 0; i < len && str[ i ]; ++i ) {
        if ( str[ i ] >= '0' && str[ i ] <= '7' ) {
            value = ( value << 3 ) + ( str[ i ] - '0' );
        }
    }
    return value;
}


void long_to_octal( char *out, size_t size, long val ) {
    sprintf( out, "%0*lo", (int)( size - 1 ), val );
    out[ size - 1 ] = '\0';
}


int is_block_empty( const unsigned char *block ) {
    int i;
    for ( i = 0; i < BLOCK_SIZE; ++i ) {
        if ( block[ i ] != 0 )
            return 0;
    }
    return 1;
}


int is_valid_tar_header( const unsigned char *header ) {
    return strncmp( (char *)header + 257, "ustar", 5 ) == 0;
}


long find_append_position( FILE *fp ) {
    long filesize, skip, zpos;
    unsigned char header[ BLOCK_SIZE ];

    fseek( fp, 0, SEEK_SET );

    while ( fread( header, 1, BLOCK_SIZE, fp ) == BLOCK_SIZE ) {
        if ( is_block_empty( header ) ) {
            /* Possible start of trailing zero blocks */
            zpos = ftell( fp ) - BLOCK_SIZE;
            /* Check if the next block is also zero */
            if ( fread( header, 1, BLOCK_SIZE, fp ) == BLOCK_SIZE && is_block_empty( header ) ) {
                /* Found trailing padding — stop here */
                return zpos;
            } else {
                /* False alarm — continue */
                fseek( fp, -BLOCK_SIZE, SEEK_CUR );
            }
        }

        if ( !is_valid_tar_header( header ) ) {
            return -1; /* Invalid TAR */
        }

        /* Get file size and skip content */
        filesize = octal_to_long( (char *)( header + 124 ), 12 );
        skip = ( ( filesize + BLOCK_SIZE - 1 ) / BLOCK_SIZE ) * BLOCK_SIZE;
        fseek( fp, skip, SEEK_CUR );
    }

    /* If we reached EOF with no trailing zeros: append at EOF */
    return ftell( fp );
}


long get_file_size( FILE *f ) {
    long size;
    fseek( f, 0, SEEK_END );
    size = ftell( f );
    fseek( f, 0, SEEK_SET );
    return size;
}


void write_tar_header( FILE *out, const char *filename, long filesize, long mtime ) {
    unsigned int i, checksum;
    struct tar_header header;

    memset( &header, 0, sizeof( header ) );
    strncpy( header.name, filename, 100 );
    long_to_octal( header.mode, 8, 0644 );
    long_to_octal( header.uid, 8, 0 );
    long_to_octal( header.gid, 8, 0 );
    long_to_octal( header.size, 12, filesize );
    long_to_octal( header.mtime, 12, mtime );
    memset( header.chksum, ' ', 8 );
    header.typeflag = '0';
    strncpy( header.magic, "ustar  ", 8 );
    strncpy( header.uname, "user", 32 );
    strncpy( header.gname, "group", 32 );

    checksum = 0;
    for ( i = 0; i < sizeof( header ); ++i ) {
        checksum += ( (unsigned char *)&header )[ i ];
    }

    sprintf( header.chksum, "%06o", checksum );
    header.chksum[ 6 ] = '\0';
    header.chksum[ 7 ] = ' ';

    fwrite( &header, 1, BLOCK_SIZE, out );
}


void write_file_content( FILE *out, FILE *in, long filesize ) {
    size_t n;
    long remaining = filesize;
    char buffer[ BLOCK_SIZE ];

    while ( remaining > 0 ) {
        n = fread( buffer, 1, BLOCK_SIZE, in );
        if ( n < BLOCK_SIZE ) {
            memset( buffer + n, 0, BLOCK_SIZE - n );
        }
        fwrite( buffer, 1, BLOCK_SIZE, out );
        remaining -= n;
    }
}


/* ------------------------------------------------------ */
/* --------------------- CREATE MODE -------------------- */
/* ------------------------------------------------------ */
void mode_create( int argc, char *argv[] ) {
    FILE *out, *in;
    struct stat st;
    long filesize, mtime, now;
    int i;

    time( &now );

    out = fopen( argv[ 2 ], "wb" );
    if ( !out ) {
        perror( "Cannot create archive" );
        exit( 1 );
    }

    for ( i = 3; i < argc; ++i ) {
        in = fopen( argv[ i ], "rb" );
        if ( !in ) {
            perror( argv[ i ] );
            continue;
        }

        if ( stat( argv[ i ], &st ) != 0 || !S_ISREG( st.st_mode ) ) {
            fprintf( stderr, "Skipping: %s (not a regular file)\n", argv[ i ] );
            fclose( in );
            continue;
        }

        filesize = get_file_size( in );
#ifdef z80
        mtime = st.st_atime;
        if ( mtime <= 1702566600 ) /* no valid timestamp */
            mtime = now;
#else
        mtime = st.st_mtime;
#endif
        printf( "%s (%ld bytes)\n", *argv, filesize );

        write_tar_header( out, argv[ i ], filesize, mtime );
        write_file_content( out, in, filesize );
        fclose( in );
    }

    /* Final two 512-byte blocks of zeros */
    {
        char block[ BLOCK_SIZE ];
        memset( block, 0, BLOCK_SIZE );
        fwrite( block, 1, BLOCK_SIZE, out );
        fwrite( block, 1, BLOCK_SIZE, out );
    }

    fclose( out );
}


/* ------------------------------------------------------ */
/* -------------------- APPEND MODE --------------------- */
/* ------------------------------------------------------ */
void mode_append( int argc, char *argv[] ) {
    FILE *tar, *in;
    struct stat st;
    long pos, filesize, mtime;
    int i;

    tar = fopen( argv[ 2 ], "r+b" );
    if ( !tar ) {
        perror( "Cannot open archive" );
        exit( 1 );
    }

    pos = find_append_position( tar );
    if ( pos < 0 ) {
        fprintf( stderr, "Invalid or corrupt TAR archive\n" );
        fclose( tar );
        exit( 1 );
    }

    fseek( tar, pos, SEEK_SET );

    for ( i = 3; i < argc; ++i ) {
        in = fopen( argv[ i ], "rb" );
        if ( !in ) {
            perror( argv[ i ] );
            continue;
        }

        if ( stat( argv[ i ], &st ) != 0 || !S_ISREG( st.st_mode ) ) {
            fprintf( stderr, "Skipping: %s (not a regular file)\n", argv[ i ] );
            fclose( in );
            continue;
        }

        filesize = get_file_size( in );
        mtime = st.st_mtime;
        write_tar_header( tar, argv[ i ], filesize, mtime );
        write_file_content( tar, in, filesize );
        fclose( in );
    }

    /* Re-write final two 512-byte zero blocks */
    {
        char zero[ BLOCK_SIZE ];
        memset( zero, 0, BLOCK_SIZE );
        fwrite( zero, 1, BLOCK_SIZE, tar );
        fwrite( zero, 1, BLOCK_SIZE, tar );
    }

    fclose( tar );
}


/* ------------------------------------------------------ */
/* --------------------- LIST MODE ---------------------- */
/* ------------------------------------------------------ */
void mode_list( const char *tarfile ) {
    FILE *fp;
    long filesize;
    int i;
    unsigned char header[ BLOCK_SIZE ];
    char filename[ 101 ];

    fp = fopen( tarfile, "rb" );
    if ( !fp ) {
        perror( "open" );
        exit( 1 );
    }

    while ( fread( header, 1, BLOCK_SIZE, fp ) == BLOCK_SIZE ) {
        if ( is_block_empty( header ) )
            break;

        if ( !is_valid_tar_header( header ) ) {
            fprintf( stderr, "Invalid TAR format: missing ustar magic.\n" );
            break;
        }

        for ( i = 0; i < 100 && header[ i ]; ++i )
            filename[ i ] = isprint( header[ i ] ) ? header[ i ] : '?';
        filename[ i ] = '\0';

        filesize = octal_to_long( (char *)( header + 124 ), 12 );
        printf( "%s (%ld bytes)\n", filename, filesize );

        fseek( fp, ( ( filesize + 511 ) / 512 ) * 512, SEEK_CUR );
    }

    fclose( fp );
}


/* ------------------------------------------------------ */
/* -------------------- EXTRACT MODE -------------------- */
/* ------------------------------------------------------ */
void mode_extract( const char *tarfile ) {
    FILE *fp, *out;
    long filesize, remaining;
    int i, to_read;
    unsigned char header[ BLOCK_SIZE ];
    char filename[ 101 ];
    char buffer[ BLOCK_SIZE ];

    fp = fopen( tarfile, "rb" );
    if ( !fp ) {
        perror( "open" );
        exit( 1 );
    }

    while ( fread( header, 1, BLOCK_SIZE, fp ) == BLOCK_SIZE ) {
        if ( is_block_empty( header ) )
            break;

        if ( !is_valid_tar_header( header ) ) {
            fprintf( stderr, "Invalid TAR format: missing ustar magic.\n" );
            break;
        }

        for ( i = 0; i < 100 && header[ i ]; ++i )
            filename[ i ] = isprint( header[ i ] ) ? header[ i ] : '?';
        filename[ i ] = '\0';

        filesize = octal_to_long( (char *)( header + 124 ), 12 );
        printf( "Extracting: %s (%ld bytes)\n", filename, filesize );

        out = fopen( filename, "wb" );
        if ( !out ) {
            perror( filename );
            fseek( fp, ( ( filesize + 511 ) / 512 ) * 512, SEEK_CUR );
            continue;
        }

        remaining = filesize;
        while ( remaining > 0 ) {
            to_read = remaining > BLOCK_SIZE ? BLOCK_SIZE : (int)remaining;
            fread( buffer, 1, BLOCK_SIZE, fp );
            fwrite( buffer, 1, to_read, out );
            remaining -= to_read;
        }

        fclose( out );

        if ( filesize % BLOCK_SIZE != 0 )
            fseek( fp, BLOCK_SIZE - ( filesize % BLOCK_SIZE ), SEEK_CUR );
    }

    fclose( fp );
}


/* ---------------------------------------------- */
/* -------------------- MAIN -------------------- */
/* ---------------------------------------------- */
int main( int argc, char *argv[] ) {
    if ( argc < 2 ) {
#ifdef z80
        argv[ 0 ] = "tar"; /* argv[0] from HI-TECH C is the empty string ("") */
#endif
        printf( "Tiny TAR archiving tool version %s\n", VERSION );
        printf( "Usage:\n" );
        printf( "  %s -cf archive.tar file1 [file2 ...]  # Create archive from files.\n", argv[ 0 ] );
        printf( "  %s -rf archive.tar file1 [file2 ...]  # Append files to archive.\n", argv[ 0 ] );
        printf( "  %s [-tf] archive.tar                  # List all files in archive.\n", argv[ 0 ] );
        printf( "  %s -xf archive.tar                    # Extract all files from archive.\n", argv[ 0 ] );
        return 1;
    }

    if ( argc == 2 || strcmp( argv[ 1 ], "-tf" ) == 0 ) {
        mode_list( argv[ argc == 2 ? 1 : 2 ] );
    } else if ( argc == 3 && strcmp( argv[ 1 ], "-xf" ) == 0 ) {
        mode_extract( argv[ 2 ] );
    } else if ( argc >= 4 && strcmp( argv[ 1 ], "-cf" ) == 0 ) {
        mode_create( argc, argv );
    } else if ( argc >= 4 && strcmp( argv[ 1 ], "-rf" ) == 0 ) {
        mode_append( argc, argv );
    } else {
        fprintf( stderr, "Invalid arguments.\n" );
        return 1;
    }

    return 0;
}
