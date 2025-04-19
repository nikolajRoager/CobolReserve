      *-----------------------
       IDENTIFICATION DIVISION.
      *-----------------------
       PROGRAM-ID.    SETEXCH
       AUTHOR.        Nikolaj R Christensen
      *--------------------
       ENVIRONMENT DIVISION.
      *--------------------
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EXCHANGE-RATES ASSIGN TO EXCHANGE
           ORGANIZATION IS INDEXED
           ACCESS MODE IS RANDOM
           RECORD KEY IS E-KEY
           FILE STATUS IS WS-FILE-STATUS.
      *-------------
       DATA DIVISION.
      *-------------
       FILE SECTION.
       FD  EXCHANGE-RATES DATA RECORD IS E-RECORD.
       01 E-RECORD.
           05 E-KEY PIC X(3).
           05 E-NAME PIC X(20).
      *Custom floating point number, mantissa * 10^exp
      *COMP-2 takes up the same space as this, but this fits better with
      *our case, we don't need more than +- 1000 billion for exchange
      *rate... Unless Trump gets his hands on the money printer
      *Also, COMP-2 can not be directly printed to display, and is hard
      *to upload, as the version of COBOL on IBM Z Xplore doesn't allow
      *scientific notation
           05 E-RATE-MAN PIC 999999.
           05 E-RATE-EXP PIC S9.
      *-------------------
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX.
       01 WS-RECORD.
           05 WS-KEY PIC X(3).
           05 WS-NAME PIC X(20).
           05 WS-MAN PIC 999999.
           05 WS-EXP PIC S9.
      *Using PARM='...' limits me to one currency a time, but the code
      *becomes cleaner
       LINKAGE SECTION.
       01 ARG-BUFFER.
           05 ARG-LENGTH pic S9(4) COMP.
           05 ARG-RECORD.
               10 ARG-BASE PIC XXXXXX.
               10 ARG-EXP  PIC XX.
               10 ARG-KEY PIC X(3).
               10 ARG-NAME PIC X(20).
       PROCEDURE DIVISION USING ARG-BUFFER.
      *------------------
       READ-INPUT.
           COMPUTE ARG-LENGTH = ARG-LENGTH - 11.
           MOVE SPACES TO WS-NAME.
           MOVE ARG-NAME(1:ARG-LENGTH) to WS-NAME.
           MOVE ARG-KEY to WS-KEY.
           COMPUTE WS-MAN = FUNCTION NUMVAL(ARG-BASE).
           COMPUTE WS-EXP  = FUNCTION NUMVAL(ARG-EXP).
       OPEN-FILE.
      *Output to write new entries, Input to check for duplicate keys
           OPEN I-O EXCHANGE-RATES.
      *00, opened succesfullu, 97, opened, but not closed correctly last
           IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
      * We don't need to close it, it is not open
      * File not found (35) triggered by opening empty vsam files
              IF WS-FILE-STATUS NOT = '35'
      *Other errors can not be fixed, sorry
                   DISPLAY '{'
                   DISPLAY '  "success":0,'
           DISPLAY '  "error":"Exchange file error ' WS-FILE-STATUS ' "'
                   DISPLAY '}'
                 GOBACK
              ELSE
      *Open as output
                 OPEN OUTPUT EXCHANGE-RATES
                 IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
                   DISPLAY '{'
                   DISPLAY '  "success":0,'
           DISPLAY '  "error":"Exchange file error ' WS-FILE-STATUS ' "'
                   DISPLAY '}'
                   GOBACK
                 ELSE
                     PERFORM WRITE-TO-VSAM
                     CLOSE EXCHANGE-RATES
                     GOBACK
                 END-IF
           ELSE
                PERFORM WRITE-TO-VSAM
                CLOSE EXCHANGE-RATES
                GOBACK
           END-IF.
           GOBACK.
       WRITE-TO-VSAM.
      *Try just uploading it, if it doesn't work, maybe the key exists
           MOVE WS-KEY TO E-KEY
           MOVE WS-NAME TO E-NAME
           MOVE WS-MAN TO E-RATE-MAN
           MOVE WS-EXP TO E-RATE-EXP

           WRITE E-RECORD
           INVALID KEY
      *get the existing record and overwrite it then
               READ EXCHANGE-RATES  RECORD KEY E-KEY
               INVALID KEY
      *I don't know if this is a thing which can even happen
                   DISPLAY '{'
                   DISPLAY '  "success":0,'
           DISPLAY '  "error":"Dublicate key could not be loaded"'
                   DISPLAY '}'
                   GOBACK
               END-READ
      *Update the rest of the data, not the UID
               MOVE WS-KEY TO E-KEY
               MOVE WS-NAME TO E-NAME
               MOVE WS-MAN TO E-RATE-MAN
               MOVE WS-EXP TO E-RATE-EXP
               REWRITE E-RECORD
               END-WRITE.
      *Verify that stuff happened
           IF WS-FILE-STATUS = '00'
               DISPLAY '{'
               DISPLAY '  "success":1,'
               DISPLAY '  "error":"Added ' WS-NAME ' as ' WS-KEY ' "'
               DISPLAY '}'
           ELSE
              DISPLAY '{'
              DISPLAY '  "success":0,'
           DISPLAY '  "error":"Exchange file error ' WS-FILE-STATUS ' "'
              DISPLAY '}'
           END-IF.
