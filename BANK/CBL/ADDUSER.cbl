      *Add a single user with an account and transfer history
      *Does not allow modifying existing user (requires password hash)
      *-----------------------
       IDENTIFICATION DIVISION.
      *-----------------------
       PROGRAM-ID.    ADDUSER
       AUTHOR.        Nikolaj R Christensen
      *--------------------
       ENVIRONMENT DIVISION.
      *--------------------
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT USER-ACCOUNTS ASSIGN TO ACCOUNTS
           ORGANIZATION IS INDEXED
           ACCESS MODE IS RANDOM
           RECORD KEY IS F-UID
           FILE STATUS IS WS-FILE-STATUS.
      *-------------
       DATA DIVISION.
      *-------------
       FILE SECTION.
       FD  USER-ACCOUNTS DATA RECORD IS ACT-REC.
       01 ACT-REC.
           05 F-UID      PIC X(10).
           05 F-PASSHASH PIC X(10).
           05 F-NAME     PIC X(20).
           05 F-BALANCE  PIC 9(12)V9(5).
           05 F-CURRENCY PIC X(3).
      *-------------------
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX.
       01 WS-RECORD.
           05 WS-UID      PIC X(10).
           05 WS-PASSHASH PIC X(10).
           05 WS-NAME     PIC X(20).
           05 WS-BALANCE  PIC 9(12)V9(5).
           05 WS-CURRENCY PIC X(3).
       01 WS-IS-DUBLICATE PIC X value 'N'.
      *Using PARM='...' limits me to one currency a time, but the code
      *becomes cleaner
       LINKAGE SECTION.
       01 ARG-BUFFER.
           05 ARG-LENGTH pic S9(4) COMP.
           05 ARG-RECORD.
              10 ARG-UID      PIC X(10).
              10 ARG-PASSHASH PIC X(10).
              10 ARG-BALANCE  PIC 9(12)V9(5).
              10 ARG-CURRENCY PIC X(3).
              10 ARG-NAME     PIC X(20).
       PROCEDURE DIVISION USING ARG-BUFFER.
      *------------------
       READ-INPUT.
           COMPUTE ARG-LENGTH = ARG-LENGTH - 11.
           MOVE SPACES TO WS-NAME.
           MOVE ARG-NAME(1:ARG-LENGTH) to WS-NAME.
           MOVE ARG-UID to WS-UID.
           COMPUTE WS-BALANCE= FUNCTION NUMVAL(ARG-BALANCE).
           COMPUTE WS-CURRENCY= FUNCTION NUMVAL(ARG-CURRENCY).
       OPEN-FILE.
      *Output to write new entries, Input to check for duplicate keys
           OPEN I-O USER-ACCOUNTS.
      *00, opened succesfullu, 97, opened, but not closed correctly last
           IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
      * We don't need to close it, it is not open
      * File not found (35) triggered by opening empty vsam files
              IF WS-FILE-STATUS NOT = '35'
      *Other errors can not be fixed, sorry
                 DISPLAY 'ERROR: FILE OPEN ERROR-CODE:' WS-FILE-STATUS
                 GOBACK
              ELSE
      *Open as output
                 DISPLAY 'Opening as output'
                 OPEN OUTPUT USER-ACCOUNTS
                 IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
                   DISPLAY 'ERROR: FILE OPEN ERROR-CODE:' WS-FILE-STATUS
                   GOBACK
                 ELSE
                     DISPLAY 'Write to out'
      *We can just write, we don't need to check for duplicates
                     PERFORM WRITE-TO-VSAM
                     CLOSE USER-ACCOUNTS
                     GOBACK
                 END-IF
           ELSE
      *Keep as input-output, but first check if it exists, returns error
                PERFORM CHECK-EXISTING
                IF WS-IS-DUBLICATE = 1
                   PERFORM WRITE-TO-VSAM
                   CLOSE USER-ACCOUNTS
                   GOBACK
                ELSE
                   PERFORM WRITE-TO-VSAM
                   CLOSE USER-ACCOUNTS
                   GOBACK
                END-IF
           END-IF.
           GOBACK.
       CHECK-EXISTING.
      *Check for existing key, just get it
           MOVE WS-UID TO F-UID
           READ USER-ACCOUNTS RECORD KEY F-UID
           INVALID KEY
      *This is good, the account doesn't already exist
               MOVE 'N' TO WS-IS-DUBLICATE
           NOT INVALID KEY
      *Well, it is a dublicate
               MOVE 'Y' TO WS-IS-DUBLICATE
           END-READ.


       WRITE-TO-VSAM.
      *Try just uploading it, if it doesn't work, maybe the key exists
           MOVE WS-RECORD TO ACT-REC
           WRITE ACT-REC
           INVALID KEY
      *get the existing record and overwrite it then
               DISPLAY 'FAILED, DUBLICATE'
           END-WRITE.
      *Verify that stuff happened
           IF WS-FILE-STATUS = '00'
               DISPLAY 'UPDATED'
           ELSE
               DISPLAY 'ERROR: UPDATE FAILED WITH STATUS' WS-FILE-STATUS
           END-IF.