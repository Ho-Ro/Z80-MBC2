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
 *   -xf archive.tar                    # Extract all files from an archive
 *   -tf archive.tar                    # List contents of an archive
 *   archive.tar                        # Same as -tf archive.tar
 *
 * Features:
 *   - Fully ANSI C89 compatible (no POSIX-specific functions used).
 *   - Uses only the standard C library (stdio.h, string.h, etc.).
 *   - Validates USTAR magic to ensure archive format correctness.
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
 *   Keep the name "tinytar" to distinguish it from real tar.
 *
 * Building on CP/M with HI-TECH C:
 *   Use version V3.09-17 from https://github.com/agn453/HI-TECH-Z80-C
 *   c309-17 -o -v -etar.com tinytar.c
 *   This creates the file TAR.COM that resembles the std. tar commands.
 *
 * Author: Martin Homuth-Rosemann
 * License: GPL-3.0-or-later
 */

#define VERSION "20250503"

#include <ctype.h>  /* isprint */
#include <stdio.h>  /* fopen, fread, fwrite, fclose, printf, sprintf */
#include <stdint.h> /* intN_t, uintN_t */
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


#define RECORD_SIZE 512
uint8_t record[ RECORD_SIZE ];


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
int32_t octal_to_int32( const char *str, int len ) {
    int32_t value = 0;
    int i;
    for ( i = 0; i < len && str[ i ]; ++i ) {
        if ( str[ i ] >= '0' && str[ i ] <= '7' ) {
            value = ( value << 3 ) + ( str[ i ] - '0' );
        }
    }
    return value;
}


int is_block_empty( const uint8_t *block ) {
    int i;
    for ( i = 0; i < RECORD_SIZE; ++i )
        if ( block[ i ] != 0 )
            return 0;
    return 1;
}


int is_valid_tar_header( const uint8_t *header ) {
    fprintf( stderr, "%s\n", (char *)header + 257 );
    return strncmp( (char *)header + 257, "ustar", 5 ) == 0;
}


uint32_t get_file_size( FILE *f ) {
    uint32_t size;
    fseek( f, 0, SEEK_END );
    size = ftell( f );
    fseek( f, 0, SEEK_SET );
    return size;
}


void write_tar_header( FILE *out, const char *filename, uint32_t filesize, time_t mtime ) {
    unsigned int i, checksum;
    struct tar_header header;

    memset( &header, 0, sizeof( header ) );
    strncpy( header.name, filename, 100 );
    sprintf( header.mode, "%07o", 0644 );
    sprintf( header.uid, "%07o", 1000 );
    sprintf( header.gid, "%07o", 1000 );
    sprintf( header.size, "%011o", filesize );
    sprintf( header.mtime, "%011lo", mtime );
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

    fwrite( &header, 1, RECORD_SIZE, out );
}


void write_file_content( FILE *out, FILE *in, long filesize ) {
    size_t n;
    long remaining = filesize;

    while ( remaining > 0 ) {
        n = fread( record, 1, RECORD_SIZE, in );
        if ( n < RECORD_SIZE ) {
            memset( record + n, 0, RECORD_SIZE - n );
        }
        fwrite( record, 1, RECORD_SIZE, out );
        remaining -= n;
    }
}


/* ------------------------------------------------------ */
/* --------------------- CREATE MODE -------------------- */
/* ------------------------------------------------------ */
void mode_create( int argc, char **argv ) {
    FILE *out, *in;
    struct stat st;
    uint32_t filesize;
    time_t mtime;
    int i;

#ifdef CPM
    time( &mtime );
    mtime -= 7200;
#endif

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
#ifndef CPM
        mtime = st.st_mtime;
#endif
        fprintf( stderr, "%s (%d bytes)\n", argv[ i ], filesize );

        write_tar_header( out, argv[ i ], filesize, mtime );
        write_file_content( out, in, filesize );
        fclose( in );
    }

    /* Final two 512-byte blocks of zeros */
    {
        char block[ RECORD_SIZE ];
        memset( block, 0, RECORD_SIZE );
        fwrite( block, 1, RECORD_SIZE, out );
        fwrite( block, 1, RECORD_SIZE, out );
    }

    fclose( out );
}


/* ------------------------------------------------------ */
/* --------------------- LIST MODE ---------------------- */
/* ------------------------------------------------------ */
void mode_list( const char *tarfile ) {
    FILE *fp;
    int32_t filesize;
    int i;
    char filename[ 101 ];

    fp = fopen( tarfile, "rb" );
    if ( !fp ) {
        perror( "open" );
        exit( 1 );
    }

    while ( fread( record, 1, RECORD_SIZE, fp ) == RECORD_SIZE ) {
        if ( is_block_empty( record ) )
            break;

        if ( !is_valid_tar_header( record ) ) {
            fprintf( stderr, "Invalid TAR format: missing ustar magic.\n" );
            break;
        }

        for ( i = 0; i < 100 && record[ i ]; ++i )
            filename[ i ] = isprint( record[ i ] ) ? record[ i ] : '?';
        filename[ i ] = '\0';

        filesize = octal_to_int32( (char *)( record + 124 ), 12 );
        printf( "%s (%d bytes)\n", filename, filesize );

        fseek( fp, ( ( filesize + 511 ) / 512 ) * 512, SEEK_CUR );
    }

    fclose( fp );
}


/* ------------------------------------------------------ */
/* -------------------- EXTRACT MODE -------------------- */
/* ------------------------------------------------------ */
void mode_extract( const char *tarfile ) {
    FILE *fp, *out;
    int32_t filesize, remaining;
    int i, to_read;
    char filename[ 101 ];

    fp = fopen( tarfile, "rb" );
    if ( !fp ) {
        perror( "open" );
        exit( 1 );
    }

    while ( fread( record, 1, RECORD_SIZE, fp ) == RECORD_SIZE ) {
        if ( is_block_empty( record ) )
            break;
        if ( !is_valid_tar_header( record ) ) {
            fprintf( stderr, "Invalid TAR format: missing ustar magic.\n" );
            break;
        }

        for ( i = 0; i < 100 && record[ i ]; ++i )
            filename[ i ] = isprint( record[ i ] ) ? record[ i ] : '?';
        filename[ i ] = '\0';

        filesize = octal_to_int32( (char *)( record + 124 ), 12 );
        printf( "Extracting: %s (%d bytes)\n", filename, filesize );

        out = fopen( filename, "wb" );
        if ( !out ) {
            perror( filename );
            fseek( fp, ( ( filesize + 511 ) / 512 ) * 512, SEEK_CUR );
            continue;
        }

        remaining = filesize;
        while ( remaining > 0 ) {
            to_read = remaining > RECORD_SIZE ? RECORD_SIZE : (int)remaining;
            fread( record, 1, RECORD_SIZE, fp );
            fwrite( record, 1, to_read, out );
            remaining -= to_read;
        }
        fclose( out );

    }

    fclose( fp );
}


void usage( char *argv0 ) {
    printf( "Tiny TAR archiving tool version %s\n", VERSION );
    printf( "Usage:\n" );
    printf( "  %s -cf archive.tar file1 [file2 ...]  # Create archive from files.\n", argv0 );
    printf( "  %s [-tf] archive.tar                  # List all files in archive.\n", argv0 );
    printf( "  %s -xf archive.tar                    # Extract all files from archive.\n", argv0 );
}


/* ---------------------------------------------- */
/* -------------------- MAIN -------------------- */
/* ---------------------------------------------- */
int main( int argc, char *argv[] ) {
#ifdef CPM
    argv[ 0 ] = "tar"; /* argv[0] from HI-TECH C is the empty string ("") */
#endif
    if ( argc < 2 ) {
        usage( argv[ 0 ] );
        return 1;
    }
    /* CP/M converts all args to UPPERCASE! */
    if ( argc == 2 || !strcmp( argv[ 1 ], "-tf" ) || !strcmp( argv [ 1 ], "-TF" ) ) {
        mode_list( argv[ argc == 2 ? 1 : 2 ] );
    } else if ( argc == 3 &&
        ( !strcmp( argv[ 1 ], "-xf" ) || !strcmp( argv[ 1 ], "-XF" ) ) ) {
        mode_extract( argv[ 2 ] );
    } else if ( argc >= 4 &&
        ( !strcmp( argv[ 1 ], "-cf" ) || !strcmp( argv[ 1 ], "-CF" ) ) ) {
        mode_create( argc, argv );
    } else {
        usage( argv[ 0 ] );
        fprintf( stderr, "Invalid arguments.\n" );
        return 1;
    }

    return 0;
}
