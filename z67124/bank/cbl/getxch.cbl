      *-----------------------
       IDENTIFICATION DIVISION.
      *-----------------------
       PROGRAM-ID.    GETEXCH
       AUTHOR.        Nikolaj R Christensen
      *--------------------
       ENVIRONMENT DIVISION.
      *--------------------
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EXCHANGE-RATES ASSIGN TO EXCHANGE
              ORGANIZATION IS INDEXED
              ACCESS MODE IS DYNAMIC
              RECORD KEY IS E-KEY
              FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  EXCHANGE-RATES DATA RECORD IS E-RECORD.
       01  E-RECORD.
           05 E-KEY PIC X(3).
           05 E-NAME PIC X(20).
           05 E-MAN  PIC 999999.
           05 E-EXP  PIC S9.

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS     PIC XX.
       01  WS-EOF             PIC X VALUE 'N'.
       01  WS-START           PIC X VALUE 'Y'.

      *The above signed number may be stored in weird stupid ebsidec
      *We need to move to the below to get something readable
       01 WS-DISPLAY-SIGNED PIC -9.

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           OPEN INPUT EXCHANGE-RATES
           IF WS-FILE-STATUS NOT = '00' AND WS-FILE-STATUS NOT = '97'
              DISPLAY '{"success":0,'
              DISPLAY '"error":"File error ' WS-FILE-STATUS '"}'
              GOBACK.
        READ-FILE.
              DISPLAY '{"success":1,'
              DISPLAY '"error":"File error ' WS-FILE-STATUS '",'
              DISPLAY '"exchangeRates":['
           PERFORM UNTIL WS-EOF = 'Y'
               READ EXCHANGE-RATES NEXT RECORD
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       IF WS-START NOT = 'Y'
                          DISPLAY ','
                       END-IF

                       DISPLAY '{'
                       DISPLAY '"Key":"' E-KEY '",'
                       DISPLAY '"Name":"' E-NAME '",'
                       MOVE E-EXP TO WS-DISPLAY-SIGNED
                       DISPLAY '"Rate":' E-MAN 'E' WS-DISPLAY-SIGNED
                       DISPLAY '}'
                       MOVE 'N' TO WS-START
              END-READ
           END-PERFORM.
              DISPLAY ']}'
           CLOSE EXCHANGE-RATES.
           GOBACK.
