/* muzcat_simple.c -- decompression filter in simple, portable C
 * by pts@fazekas.hu at Tue Jun 16 16:50:24 CEST 2020
 *
 * This tool is a slow drop-in replacmeent of zcat (gzip -cd), without error
 * handling. It reads compressed data (can be gzip, flate or zip format) on
 * stdin, and it writes uncompressed data to stdout. There is no error
 * handling: if the input is invalid, the tool may do anything.
 *
 * Modifications Ho-Ro:
 * * Error handling: check magic and compression mode before processing,
 *   calculate CRC32 during expanding and check against CRC32 of archive.
 * * CP/M needs a hack to get the real file size (w/o trailing ^Z)
 *   and convert ^Z at end of file into C EOF (-1).
 * * Compiles for CP/M using HI-TECH C: 'cc -v gunzip.c'.
 *   Do not optimise '-o', OPTIM.COM stops due to 'Out of memory'.
 *   Program becomes too big when using time and date functions.
 *
 * The implementation was inspired by https://www.ioccc.org/1996/rcm/index.html
 *
 * Portability notes:
 *
 * * Source code is compatible with C89, C99 and newer. GCC, Clang and TinyCC
 *   do work. 16-bit C compilers should also work.
 * * Source code is compatible with owccdos (http://github.com/pts/owccdos).
 * * Source code isn't compatible with MesCC in GNU Mes 0.22, because MesCC
 *   doesn't support global arrays (initialized or uninitialized). Apart from
 *   that, it would compile.
 * * Feel free to change 'int16_t' and 'char' to int.
 * * It doesn't matter whether 'char' is signed or unsigned.
 * * The code works with any sizeof(short) and sizeof(int).
 * * The code doesn't use multiplication or division.
 * * On Windows, setmode(0, O_BINARY); and setmode(1, O_BINARY) are needed,
 *   otherwise the CRT inserts '\r' (CR) characters, breaking the decompression.
 * * For Linux/UNIX use gcc: 'gcc -o gunzip gunzip.c'
 *
 * Similar code:
 *
 * * https://www.ioccc.org/1996/rcm/index.html
 * * https://github.com/ioccc-src/winner/blob/master/1996/rcm/rcm.c
 * * https://gist.github.com/bwoods/a6a467430ed1c5f3fa35d01212146fe7
 */

#define VERSION "20250502"

#ifndef CPM
#define MTIME
#else
#ifdef __Z88DK
#define MTIME
#endif
#endif

#include <stdio.h>  /* FILE functions, getc(), putc(), etc. */
#include <stdint.h> /* intN_t and uintN_t */
#include <stdlib.h> /* exit() */
#include <string.h> /* strcmp() */
#ifdef MTIME
#include <time.h>
#endif


int16_t constW[] = { 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14,
                   1, 15 };
int16_t constU[] = { 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
                   35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258 };
int16_t constP[] = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3,
                  3, 4, 4, 4, 4, 5, 5, 5, 5, 0 };
int16_t constQ[] = { 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
                   257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
                   8193, 12289, 16385, 24577 };
int16_t constL[] = { 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7,
                   8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13 };
int16_t D, C, T, J, Y;
int16_t Z[320];
int16_t B[17];
int16_t G[17];
int16_t N[1998];
uint8_t S[32768];  /* Dictionary == lookback buffer. */

FILE *infile = NULL, *outfile = NULL;
char *inname = NULL, *outname = NULL;
uint32_t bytecount;

/* Table of CRCs of all 8-bit messages. */
uint32_t crc_table[256];
uint32_t CRC32_gz, CRC32_calc = 0;


/* Make the table for a fast CRC. */
void make_crc_table(void) {
  uint32_t c;
  int16_t n, k;
  for (n = 0; n < 256; n++) {
    c = (uint32_t) n;
    for (k = 0; k < 8; k++) {
      if (c & 1) {
        c = 0xedb88320L ^ (c >> 1);
      } else {
        c = c >> 1;
      }
    }
    crc_table[n] = c;
  }
}


void init_crc( uint32_t c ) {
  CRC32_calc = c ^ 0xffffffffL;
}


void update_crc( uint8_t b ) {
  CRC32_calc = crc_table[(CRC32_calc ^ b) & 0xff] ^ (CRC32_calc >> 8);
}


uint32_t get_crc( void ) {
  return CRC32_calc ^ 0xffffffffL;
}


/*
 * HACK for CP/M: ignore padding ^Z bytes at EOF
 */
int16_t getbyte() {
  static int heartbeat = 1024;
  if ( ++heartbeat >= 1024 ) {
    heartbeat = 0;
    fprintf( stderr, "<" );
    fflush( stderr );
  }
  if ( bytecount-- )
    return getc( infile );
  return EOF; /* C EOF */
}


int16_t putbyte( int16_t b ) {
  static int heartbeat = 1024;
  if ( ++heartbeat >= 1024 ) {
    heartbeat = 0;
    fprintf( stderr, ">" );
    fflush( stderr );
  }
  update_crc( b );
  return putc( b, outfile );
}


int16_t mc_bitread(int16_t arg) {
  int16_t oo, f;
  if (arg) {
    if (Y+7<arg) {
      J+=((((getbyte())&255))<<(Y));
      Y+=8;
    }
    if (Y<arg) {
      f=((getbyte())&255);
      if (arg==16) {
        oo=J+((((f)&((1<<(16-Y))-1)))<<(Y));
        J=((f)>>(16-Y));
      } else {
        oo=((J+((f)<<(Y)))&((1<<(arg))-1));
        J=((f)>>(arg-Y));
      }
      Y+=8-arg;
    } else {
      oo=((J)&((1<<(arg))-1));
      Y-=arg;
      J=((((J)>>(arg)))&((1<<(Y))-1));
    }
  } else {
    oo=0;
  }
  return oo;
}


int16_t mc_nalloc(void) {
  int16_t o;
  o=D;
  D=N[o];
  N[o]=0;
  return o;
}


void mc_free(int16_t arg) {
  if (arg!=0) {
    mc_free(N[arg]);
    mc_free(N[arg+1]);
    N[arg+1]=0;
    N[arg+2]=0;
    N[arg]=D;
    D=arg;
  }
}


int16_t mc_descend(int16_t arg) {
  while (N[arg]!=0) {
    if (mc_bitread(1)) {
      arg=N[arg+1];
    } else {
      arg=N[arg];
    }
  }
  return N[arg+2];
}


int16_t mc_mktree(int16_t arg) {
  int16_t oo, q, o, f;
  B[0]=0; B[1]=0; B[2]=0; B[3]=0; B[4]=0; B[5]=0; B[6]=0; B[7]=0; B[8]=0;
  B[9]=0; B[10]=0; B[11]=0; B[12]=0; B[13]=0; B[14]=0; B[15]=0; B[16]=0;
  oo=0;
  while (oo<arg) { ((B[Z[oo]])++); oo++; }
  B[0]=0;
  G[0]=0;
  G[1]=((G[0]+B[0])<<1); G[2]=((G[1]+B[1])<<1);
  G[3]=((G[2]+B[2])<<1); G[4]=((G[3]+B[3])<<1);
  G[5]=((G[4]+B[4])<<1); G[6]=((G[5]+B[5])<<1);
  G[7]=((G[6]+B[6])<<1); G[8]=((G[7]+B[7])<<1);
  G[9]=((G[8]+B[8])<<1); G[10]=((G[9]+B[9])<<1);
  G[11]=((G[10]+B[10])<<1); G[12]=((G[11]+B[11])<<1);
  G[13]=((G[12]+B[12])<<1); G[14]=((G[13]+B[13])<<1);
  G[15]=((G[14]+B[14])<<1); G[16]=((G[15]+B[15])<<1);
  N[3]=0;
  oo=0;
  while (oo<arg) {
    if (Z[oo]) {
      q=G[Z[oo]];
      ((G[Z[oo]])++);
      f=3;
      o=Z[oo];
      while (o) {
        o--;
        if (N[f]==0) {
          N[f]=mc_nalloc();
        }
        if ((0!=((q)&(((1)<<(o)))))) {
          f=N[f]+1;
        } else {
          f=N[f]+0;
        }
      }
      N[f]=mc_nalloc();
      N[N[f]+2]=oo;
    }
    oo++;
  }
  return N[3];
}


void mc_write(int16_t arg) {
  S[T]=arg;
  T++; T&=32767;
  if (T==C) {
    putbyte(S[C]);
    C++; C&=32767;
  }
}


#ifdef __Z88DK
/* hard coded: timezone = +1 (Europe/Berlin) */
#define TIMEZONE (+1 + (time->tm_isdst ? 1 : 0))

char *isotime( time_t *t )
{
  /* Creates time string in ISO format: */
  /* e.g. "2025-04-30 13:34\0"          */
  static char time_buf[17];
  struct tm *time;
  time = gmtime( t );
  memset(time_buf,' ',16);
  sprintf( time_buf, "%04d-%02d-%02d %02d:%02d",
            1900+time->tm_year,
            time->tm_mon+1, /* 0..11 */
            time->tm_mday,
            time->tm_hour + TIMEZONE,
            time->tm_min );

  return (time_buf);
}
#endif


/* open gzip and show archive info */
/* do not use time functions due to too big CP/M program size */
FILE *gzip_open() {
#define RECSIZE 128
  FILE *fp;
  uint8_t *cp;
  int16_t n;
  uint32_t lrpos;
  uint32_t ISIZE;
#ifdef MTIME
  time_t mtime;
  char timestr[20];
#endif

/* use part of global array uint8_t S[] as record buffer */

  if ( ( fp = fopen( inname, "rb" ) ) == NULL ) {
    perror( inname );
    exit( 2 );
  }

  fseek( fp, 0, SEEK_END ); /* go to EOF */
  bytecount = ftell( fp ); /* get position */
  if ( bytecount < 10 ) {
    fprintf( stderr, "%s: File too short, no GZIP format\n", inname );
    exit( 2 );
  }
  lrpos = (bytecount - 1) & (uint32_t)(-RECSIZE); /* pos of last record */

  /* fprintf( stderr, "bytecount: %u\n", bytecount ); */
  /* fprintf( stderr, "lrpos: %u\n", lrpos ); */
  fseek( fp, lrpos, SEEK_SET ); /* go to last record */
  n = fread( S, 1, RECSIZE, fp ); /* read this record */
  if ( n == RECSIZE ) { /* search backwards for char != ^Z */
      cp = S + RECSIZE;
      n = RECSIZE+1;
      while( --n )
          if ( *--cp != 26 ) /* *real* last file position found */
              break;
  }
  bytecount = lrpos + n;

  fseek( fp, 0, SEEK_SET ); /* rewind infile */
  fread( S, 1, RECSIZE, fp ); /* read header */

  if ( S[ 0 ] != 0x1f || S[ 1 ] != 0x8b || S[ 2 ] != 0x08 ) {
    fprintf( stderr, "%s: Bad magic (%02x%02x) or compression mode (%02x)\n",
             inname, S[0], S[1], S[3] );
    exit( 2 );
  }
  /* fprintf( stderr, "XFL: %d, OS: %d - ", S[8], S[9] ); */
  fprintf( stderr, "compressed: %u - uncompressed: ", bytecount );
  if ( S[ 3 ] == 0x08 ) {
    outname = (char *)(S+10);
    fprintf( stderr, "%s ", outname);
  }

  fseek( fp, bytecount - 8, SEEK_SET ); /* read 2 x uint32_t at end of file */
  fread( &CRC32_gz, 4, 1, fp ); /* pos: -8 */
  fread( &ISIZE, 4, 1, fp ); /* pos: -4 */

#ifdef MTIME
  /* get modification time of archive content and display in ISO 8601 format */
  mtime = *(uint32_t*)(S+4);
#ifdef __Z88DK
  /* use local isotime function */
  fprintf( stderr, "%lu %s\n", ISIZE, isotime( &mtime ) );
#else
  strftime( timestr, sizeof timestr, "%Y-%m-%d %H:%M", localtime( &mtime ) );
  fprintf( stderr, "%u %s\n", ISIZE, timestr );
#endif
#else
  /* HiTech C: no time functions b/c they blow up the com file too much */
  fprintf( stderr, "%lu\n", ISIZE );
#endif

  fseek( fp, 0, SEEK_SET ); /* rewind infile */
  return fp;
}



int main(int argc, char **argv) {
  int16_t o, q, ty, oo, ooo, oooo, f, p, x, v, h, g;

  if ( argc < 2 || argc > 3 ) {
    fprintf( stderr, "Tiny GUNZIP tool version %s\n", VERSION );
#ifdef CPM
/* CPM cannot access argv[0], args are converted to upper case */
#define OPTION_O "-O"
    fprintf( stderr, "usage: gunzip <infile> [-o | <outfile>]\n" );
#else
/* handle normal UNIX cmd line args */
#define OPTION_O "-o"
    fprintf( stderr, "usage: %s <infile> [-o | <outfile>]\n", argv[ 0 ] );
#endif
    return 1 ;
  }
  inname = argv[ 1 ];

  infile = gzip_open(); /* open file and show archive info */

  if ( argc == 2 ) { /* show only archive info, ready */
    fclose( infile );
    return 0;
  }

  /* no uncompressed name in gzip or no cmd line arg "-o" given  */
  if ( !outname || strcmp( argv[2], OPTION_O ) )
    outname = argv[ 2 ];

  if ( ( outfile = fopen( outname, "wb" ) ) == NULL ) {
    perror( outname );
    return 3;
  }

  make_crc_table();
  init_crc( 0 );

  /**********************************************/
  /* HIC SUNT DRACONES - do not touch below ... */
  /**********************************************/
  ty=3;
  while (ty!=4) {
    oo=0; ooo=0;
    J=0; Y=0; C=0; T=0;
    v=0; h=0;
    N[0]=0; N[1]=0; N[2]=0;
    N[3]=0; N[4]=0; N[5]=0;
    D=6;
    o=D;
    while (o<1998) {
      N[o]=o+3; o++;
      N[o]=0; o++;
      N[o]=0; o++;
    }
    ty=getbyte();
    if ((0!=((512+ty)&(256)))) {
      ty=4;
    } else if (ty==120) {
      mc_bitread(8);
    } else if (ty==80) {
      mc_bitread(8);
      o=mc_bitread(8);
      ty=3;
      if (o==3) {
        mc_bitread(8);
        mc_bitread(16);
        mc_bitread(16);
        ty=mc_bitread(8);
        mc_bitread(8);
        mc_bitread(16); mc_bitread(16);
        mc_bitread(16); mc_bitread(16);
        oo=mc_bitread(8); oo+=((mc_bitread(8))<<(8));
        ooo=mc_bitread(8); ooo+=((mc_bitread(8))<<(8));
        mc_bitread(16); mc_bitread(16);
        f=mc_bitread(8); f+=((mc_bitread(8))<<(8));
        q=mc_bitread(8); q+=((mc_bitread(8))<<(8));
        while (f) { mc_bitread(8); f--; }
        while (q) { mc_bitread(8); q--; }
      } else if (o==7) {
        o=0; while (o<13) { mc_bitread(8); o++; }
      } else if (o==5) {
        o=0; while (o<17) { mc_bitread(8); o++; }
        o=mc_bitread(8); o+=((mc_bitread(8))<<(8));
        while (o) { mc_bitread(8); o--; }
      } else if (o==1) {
        oo=0; while (oo<25) { mc_bitread(8); oo++; }
        f=mc_bitread(8); f+=((mc_bitread(8))<<(8));
        o=mc_bitread(8); o+=((mc_bitread(8))<<(8));
        q=mc_bitread(8); q+=((mc_bitread(8))<<(8));
        oo=0; while (oo<12) { mc_bitread(8); oo++; }
        while (f) { mc_bitread(8); f--; }
        while (o) { mc_bitread(8); o--; }
        while (q) { mc_bitread(8); q--; }
      }
    } else if (ty==31) {
      mc_bitread(16);
      o=mc_bitread(8);
      mc_bitread(16); mc_bitread(16); mc_bitread(16);
      if ((0!=((o)&(2)))) {
        mc_bitread(16);
      }
      if ((0!=((o)&(4)))) {
        q=mc_bitread(16);
        while (q) { mc_bitread(8); q--; }
      }
      if ((0!=((o)&(8)))) {
        while (mc_bitread(8)) {}
      }
      if ((0!=((o)&(16)))) {
        while (mc_bitread(8)) {}
      }
      if ((0!=((o)&(32)))) {
        f=0; while (f<12) { mc_bitread(8); f++; }
      }
    }
    if (ty==0) {
      while (oo) { g=getbyte(); putbyte(g); oo--; }
      while (ooo) {
        g=getbyte(); putbyte(g);
        g=getbyte(); putbyte(g);
        oo=32767;
        while (oo) {
          g=getbyte(); putbyte(g);
          g=getbyte(); putbyte(g);
          oo--;
        }
        ooo--;
      }
    } else if (ty==4) {
    } else if (ty!=3) {
      o=0;
      while (o==0) {
        o=mc_bitread(1);
        q=mc_bitread(2);
        if (q) {
          if (q==1) {
            oo=288;
            while (oo) {
              oo--;
                if (oo<144) {
                  Z[oo]=8;
                } else if (oo<256) {
                  Z[oo]=9;
                } else if (oo<280) {
                  Z[oo]=7;
                } else {
                  Z[oo]=8;
                }
            }
            v=mc_mktree(288);
            Z[0]=5; Z[1]=5; Z[2]=5; Z[3]=5; Z[4]=5; Z[5]=5; Z[6]=5; Z[7]=5;
            Z[8]=5; Z[9]=5; Z[10]=5; Z[11]=5; Z[12]=5; Z[13]=5; Z[14]=5; Z[15]=5;
            Z[16]=5; Z[17]=5; Z[18]=5; Z[19]=5; Z[20]=5; Z[21]=5; Z[22]=5; Z[23]=5;
            Z[24]=5; Z[25]=5; Z[26]=5; Z[27]=5; Z[28]=5; Z[29]=5; Z[30]=5; Z[31]=5;
            h=mc_mktree(32);
          } else {
            p=mc_bitread(5)+257;
            x=mc_bitread(5)+1;
            v=mc_bitread(4)+4;
            oo=0;
            while (oo<v) { Z[constW[oo]]=mc_bitread(3); oo++; }
            while (oo<19) { Z[constW[oo]]=0; oo++; }
            v=mc_mktree(19);
            ooo=0;
            oo=0;
            while (oo<p+x) {
              oooo=mc_descend(v);
              if (oooo==16) {
                oooo=ooo; f=3+mc_bitread(2);
              } else if (oooo==17) {
                oooo=0; f=3+mc_bitread(3);
              } else if (oooo==18) {
                oooo=0; f=11+mc_bitread(7);
              } else {
                ooo=oooo; f=1;
              }
              q=f;
              while (q) { Z[oo]=oooo; oo++; q--; }
            }
            mc_free(v);
            v=mc_mktree(p);
            oo=x;
            while (oo) { oo--; Z[oo]=Z[oo+p]; }
            h=mc_mktree(x);
          }
          oo=mc_descend(v);
          while (oo!=256) {
            if (oo<257) {
              mc_write(oo);
            } else {
              oo-=257;
              f=constU[oo]+mc_bitread(constP[oo]);
              oo=mc_descend(h);
              oo=constQ[oo]+mc_bitread(constL[oo]);
              if (T<oo) {
                oo=32768-oo+T;
              } else {
                oo=T-oo;
              }
              while (f) {
                mc_write(S[oo]);
                oo++; oo&=32767;
                f--;
              }
            }
            oo=mc_descend(v);
          }
          mc_free(v);
          mc_free(h);
        } else {
          mc_bitread((Y&7));
          oo=mc_bitread(16);
          mc_bitread(16);
          while (oo) { mc_write(mc_bitread(8)); oo--; }
        }
      }
      while (C!=T) {
        putbyte(S[C]);
        C++; C&=32767;
      }
    }
    mc_bitread(((Y)&7));
    if (ty==31) {
      mc_bitread(16); mc_bitread(16); mc_bitread(16); mc_bitread(16);
    } else if (ty==120) {
      mc_bitread(16); mc_bitread(16);
    }
  }

  fclose( infile );
  fclose( outfile );
  fprintf( stderr, "\n" );

  if ( get_crc() != CRC32_gz )
    fprintf( stderr, "CRC of archive (%u) and calculated CRC (%u) differ\n",
             get_crc(), CRC32_gz );
  return 0;
}
