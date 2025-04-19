      *-----------------------
       IDENTIFICATION DIVISION.
      *-----------------------
       PROGRAM-ID.    GETUSERS
       AUTHOR.        Nikolaj R Christensen
      *--------------------
       ENVIRONMENT DIVISION.
      *--------------------
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT USER-ACCOUNTS ASSIGN TO ACCOUNTS
              ORGANIZATION IS INDEXED
              ACCESS MODE IS DYNAMIC
              RECORD KEY IS F-NAME
              FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  USER-ACCOUNTS DATA RECORD IS ACT-REC.
       01 ACT-REC.
           05 F-NAME     PIC X(9).
           05 F-BALANCE  PIC 9(12)V9(4).
           05 F-CURRENCY PIC X(3).
       WORKING-STORAGE SECTION.
      *Json compatible: no leading zeros, and . as decimal marker
       01  WS-BALANCE-JSON     PIC Z(11)9.9999.
       01  WS-FILE-STATUS     PIC XX.
       01  WS-EOF             PIC X VALUE 'N'.
       01  WS-START           PIC X VALUE 'Y'.

      *The above signed number may be stored in weird stupid ebsidec
      *We need to move to the below to get something readable
       01 WS-DISPLAY-SIGNED PIC -999.

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           OPEN INPUT USER-ACCOUNTS
           IF WS-FILE-STATUS NOT = '00' AND WS-FILE-STATUS NOT = '97'
              DISPLAY '{"success":0,'
              DISPLAY '"error":"File error ' WS-FILE-STATUS '"}'
              GOBACK.
        READ-FILE.
              DISPLAY '{"success":1,'
              DISPLAY '"error":"File error ' WS-FILE-STATUS '",'
              DISPLAY '"Users":['
           PERFORM UNTIL WS-EOF = 'Y'
               READ USER-ACCOUNTS NEXT RECORD
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       IF WS-START NOT = 'Y'
                          DISPLAY ','
                       END-IF

                       DISPLAY '{'
                       DISPLAY '"Name":"' F-NAME '",'
                       MOVE F-BALANCE TO WS-BALANCE-JSON
                       DISPLAY '"Balance":' WS-BALANCE-JSON ','
                       DISPLAY '"Currency":"' F-CURRENCY '"'
                       DISPLAY '}'
                       MOVE 'N' TO WS-START
              END-READ
           END-PERFORM.
              DISPLAY ']}'
           CLOSE USER-ACCOUNTS.
           GOBACK.
