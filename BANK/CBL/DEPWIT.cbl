      *deposit or withdraw an ammount from this account
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
      *-------------
       DATA DIVISION.
      *-------------
       FILE SECTION.
       FD  USER-ACCOUNTS DATA RECORD IS ACT-REC.
       01 ACT-REC.
           05 F-NAME     PIC X(9).
           05 F-BALANCE  PIC 9(12)V9(5).
           05 F-CURRENCY PIC X(3).
      *-------------------
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX.
       01 WS-AMOUNT PIC 9(12)V9(5).
      *Using PARM='...' limits me to one currency a time, but the code
      *becomes cleaner
       LINKAGE SECTION.
       01 ARG-BUFFER.
           05 ARG-LENGTH pic S9(4) COMP.
           05 ARG-AMOUNT PIC X(12)XX(5).
           05 ARG-NAME     PIC X(9).
       PROCEDURE DIVISION USING ARG-BUFFER.
      *------------------
       READ-INPUT.
           COMPUTE ARG-LENGTH = ARG-LENGTH - 18.
           COMPUTE WS-AMOUNT = FUNCTION NUMVAL(ARG-AMOUNT).
           MOVE ARG-NAME(1:ARG-LENGTH) TO F-NAME.
       OPEN-FILE.
      *Output to write new entries, Input to check for duplicate keys
           OPEN I-O USER-ACCOUNTS.
      *00, opened succesfullu, 97, opened, but not closed correctly last
           IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
      * We don't need to close it, it is not open
              DISPLAY '{'
              DISPLAY '  "success":0,'
           DISPLAY '  "error":"Accounts file error ' WS-FILE-STATUS ' "'
              DISPLAY '}'
              GOBACK
           ELSE
              MOVE ARG-NAME TO F-NAME
      *Keep as input-output, but first check if it exists, returns error
      *Check for existing key, just get it
               READ USER-ACCOUNTS RECORD KEY F-NAME
               INVALID KEY
               DISPLAY '{'
               DISPLAY '  "success":0,'
               DISPLAY '  "error":"Account ' F-NAME ' not found "'
               DISPLAY '}'
               GOBACK
               END-READ
      *Update the rest of the data, not the UID
               COMPUTE F-BALANCE = F-BALANCE + WS-AMOUNT
               REWRITE ACT-REC
           END-IF.
           GOBACK.