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
           RECORD KEY IS F-NAME
           FILE STATUS IS WS-FILE-STATUS.
      *For checking if the account currency is valid
           SELECT EXCHANGE-RATES ASSIGN TO EXCHANGE
              ORGANIZATION IS INDEXED
              ACCESS MODE IS DYNAMIC
              RECORD KEY IS E-KEY
              FILE STATUS IS WS-E-FILE-STATUS.
      *-------------
       DATA DIVISION.
      *-------------
       FILE SECTION.
      *Just for checking if it exists
       FD  EXCHANGE-RATES DATA RECORD IS E-RECORD.
       01  E-RECORD.
      *UID is generated from navy, type, and id number
           05 E-KEY PIC X(3).
           05 E-NAME PIC X(20).
           05 E-MAN  PIC 9999.
           05 E-EXP  PIC S999.
       FD  USER-ACCOUNTS DATA RECORD IS ACT-REC.
       01 ACT-REC.
           05 F-NAME     PIC X(9).
           05 F-BALANCE  PIC 9(12)V9(5).
           05 F-CURRENCY PIC X(3).
      *-------------------
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX.
       01 WS-E-FILE-STATUS PIC XX.
       01 WS-RECORD.
           05 WS-NAME     PIC X(9).
           05 WS-BALANCE  PIC 9(12)V9(5).
           05 WS-CURRENCY PIC X(3).
       01 WS-IS-DUBLICATE PIC X value 'N'.
       01 WS-VALID-CURRENCY PIC X value 'Y'.
      *Using PARM='...' limits me to one currency a time, but the code
      *becomes cleaner
       LINKAGE SECTION.
       01 ARG-BUFFER.
           05 ARG-LENGTH pic S9(4) COMP.
           05 ARG-RECORD.
              10 ARG-BALANCE  PIC X(12)XX(5).
              10 ARG-CURRENCY PIC X(3).
              10 ARG-NAME     PIC X(9).
       PROCEDURE DIVISION USING ARG-BUFFER.
      *------------------
       READ-INPUT.
           COMPUTE ARG-LENGTH = ARG-LENGTH - 21.
           COMPUTE WS-BALANCE = FUNCTION NUMVAL(ARG-BALANCE).
           MOVE SPACES TO WS-NAME.
           MOVE ARG-NAME(1:ARG-LENGTH ) TO WS-NAME.
           MOVE ARG-CURRENCY TO WS-CURRENCY.
           PERFORM CHECK-CURRENCY.
           IF WS-VALID-CURRENCY = 'N'
               DISPLAY '{'
               DISPLAY '  "success":0'
           DISPLAY '  "error":"Currency invalid ' WS-VALID-CURRENCY ' "'
               DISPLAY '}'.
              
       OPEN-FILE.
      *Output to write new entries, Input to check for duplicate keys
           OPEN I-O USER-ACCOUNTS.
      *00, opened succesfullu, 97, opened, but not closed correctly last
           IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
      * We don't need to close it, it is not open
      * File not found (35) triggered by opening empty vsam files
              IF WS-FILE-STATUS NOT = '35'
      *Other errors can not be fixed, sorry
                   DISPLAY '{'
                   DISPLAY '  "success":0'
           DISPLAY '  "error":"Accounts file error ' WS-FILE-STATUS ' "'
                   DISPLAY '}'
                 GOBACK
              ELSE
      *Open as output
                 OPEN OUTPUT USER-ACCOUNTS
                 IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
                   DISPLAY '{'
                   DISPLAY '  "success":0'
           DISPLAY '  "error":"Accounts file error ' WS-FILE-STATUS ' "'
                   DISPLAY '}'
                   GOBACK
                 ELSE
      *We can just write, we don't need to check for duplicates
                     PERFORM WRITE-TO-VSAM
                     CLOSE USER-ACCOUNTS
                     GOBACK
                 END-IF
           ELSE
      *Keep as input-output, but first check if it exists, returns error
                PERFORM CHECK-EXISTING
                IF WS-IS-DUBLICATE = 'Y'
                   DISPLAY '{'
                   DISPLAY '  "success":0'
                   DISPLAY '  "error":"user already exists"'
                   DISPLAY '}'
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
           READ USER-ACCOUNTS RECORD KEY F-NAME
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
      *Should not happen, we already checked dublicates
               DISPLAY '{'
               DISPLAY '  "success":0'
               DISPLAY '  "error":"Invalid key writing user account"'
               DISPLAY '}'
           END-WRITE.
      *Verify that stuff happened
           IF WS-FILE-STATUS = '00'
               DISPLAY '{'
               DISPLAY '  "success":1'
               DISPLAY '  "error":"added ' WS-NAME ' "'
               DISPLAY '}'
           ELSE
                   DISPLAY '{'
                   DISPLAY '  "success":0'
           DISPLAY '  "error":"Accounts file error ' WS-FILE-STATUS ' "'
                   DISPLAY '}'
           END-IF.
       CHECK-CURRENCY.
      *Check for existing key, first open the file
           MOVE WS-CURRENCY TO E-KEY
           OPEN INPUT EXCHANGE-RATES
           IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
      *Currency not found, nor the file it is in
               MOVE 'N' TO WS-E-FILE-STATUS 
           ELSE
               READ EXCHANGE-RATES RECORD KEY E-KEY
               INVALID KEY
      *Currency not found
                   MOVE 'N' TO WS-E-FILE-STATUS 
               NOT INVALID KEY
      *There it is
                   MOVE 'Y' TO WS-E-FILE-STATUS 
               END-READ
               CLOSE EXCHANGE-RATES
           END-IF.
      *Verify that the requested currency exists 