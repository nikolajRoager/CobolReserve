      *-----------------------
       IDENTIFICATION DIVISION.
      *-----------------------
       PROGRAM-ID.    SETXCH
       AUTHOR.        Nikolaj R Christensen
      *--------------------
       ENVIRONMENT DIVISION.
      *--------------------
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EXCHANGE-RATES ASSIGN TO EXCHANGERATES
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS CKEY
           FILE STATUS IS WS-FILE-STATUS.
      *-------------
       DATA DIVISION.
      *-------------
       FILE SECTION.
       FD  EXCHANGE-RATES.
       01 EXCHANGE-RECORD.
           05 CKEY PIC X(3).
           05 CNAME PIC X(21).
           05 CEXCH USAGE COMP-2.
      *-------------------
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX.
       01 WS-END-OF-FILE PIC X value 'n'.
       01 WS-RECORD.
           05 CKEY PIC X(3).
           05 CNAME PIC X(21).
           05 CEXCH USAGE COMP-2.
      *------------------
       PROCEDURE DIVISION.
      *------------------
       MAIN-PROCEDURE.
           GOBACK.
