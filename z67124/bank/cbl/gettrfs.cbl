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
           SELECT USER-TRANSFERS ASSIGN TO TRANSFER
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS TR-KEY
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  USER-TRANSFERS DATA RECORD IS TR-RECORD.
       01  TR-RECORD.
           05 TR-KEY.
      *From who, and when?
              10 TR-MY-NAME PIC X(9).
              10 TR-TIME-STAMP.
                 15 TR-YEAR PIC 9(4).
                 15 TR-MONTH PIC 9(2).
                 15 TR-DAY PIC 9(2).
                 15 TR-HOUR PIC 9(2).
                 15 TR-MINUTE PIC 9(2).
                 15 TR-SECOND PIC 9(2).
                 15 TR-MILIS PIC 9(2).
      *who do we send to? (or from)
         05 TR-THEIR-NAME PIC X(9).
         05 TR-TYPE-NAME PIC X(15).
      *For example:
      * exchange fee, (bank only)
      * transaction fee, (bank only)
      * cash deposit,
      * cash withdrawal,
      * digital transfer,
      * debit card purchase,
      * mobile pay purchase
      * recuring payment
      * interest
      *what amount was sent, in the currency of the transfer?
         05 TR-AMOUNT PIC S9(11)V9(4).
         05 TR-CURRENCY PIC X(3).
      *what amount was requested, my local currency (at the time)
      *before fees
         05 TR-OWN-CURRENCY PIC X(3).
         05 TR-OWN-AMOUNT PIC S9(11)V9(4).
      *What fees were deducted (are deducted from the receiving account
      *hence 0 for sender) in currency of the account
      *Bank is excempt from fees
         05 TR-EXHANGE-FEE PIC S9(11)V9(4).
         05 TR-TRANSACTION-FEE PIC S9(11)V9(4).
       WORKING-STORAGE SECTION.
      *Json compatible: no leading zeros, and . as decimal marker
       01  WS-BALANCE-JSON     PIC Z(11)9.9999.
       01  WS-FILE-STATUS     PIC XX.
       01  WS-EOF             PIC X VALUE 'N'.
       01  WS-START           PIC X VALUE 'Y'.
       01 WS-DISPLAY-AMOUNT PIC -Z(10)9.9(4).

      *The above signed number may be stored in weird stupid ebsidec
      *We need to move to the below to get something readable
       01 WS-DISPLAY-SIGNED PIC -999.

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           OPEN INPUT USER-TRANSFERS
           IF WS-FILE-STATUS NOT = '00' AND WS-FILE-STATUS NOT = '97'
              DISPLAY '{"success":0,'
              DISPLAY '"error":"File error ' WS-FILE-STATUS '"}'
              GOBACK.
       READ-FILE.
              DISPLAY '{"success":1,'
              DISPLAY '"error":"File error ' WS-FILE-STATUS '",'
              DISPLAY '"Users":['
           PERFORM UNTIL WS-EOF = 'Y'
               READ USER-TRANSFERS NEXT RECORD
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       IF WS-START NOT = 'Y'
                          DISPLAY ','
                       END-IF
           DISPLAY '{'
           DISPLAY '"Key":"' TR-KEY '",'
           DISPLAY '"Account":"' TR-MY-NAME '",'
           DISPLAY '"Timestamp": "' TR-YEAR '-' TR-MONTH
           '-' TR-DAY '-' TR-HOUR '-' TR-MINUTE '-'
           TR-SECOND '-' TR-MILIS '",'

           MOVE "Outside" TO TR-THEIR-NAME
           DISPLAY '"OtherAccount":"' TR-THEIR-NAME '",'
           DISPLAY '"Type":"' TR-TYPE-NAME '",'

           MOVE TR-AMOUNT TO WS-DISPLAY-AMOUNT
           DISPLAY '"AmountNominal":' WS-DISPLAY-AMOUNT ','
           DISPLAY '"TransactionCurrency": "' TR-CURRENCY '",'
           MOVE TR-OWN-AMOUNT TO WS-DISPLAY-AMOUNT
           DISPLAY '"AmountTransfered":' WS-DISPLAY-AMOUNT ','
           DISPLAY '"OwnCurrency": "' TR-OWN-CURRENCY '",'

           MOVE TR-EXHANGE-FEE TO WS-DISPLAY-AMOUNT
           DISPLAY '"ExchangeFee":' WS-DISPLAY-AMOUNT ','

           MOVE TR-TRANSACTION-FEE TO WS-DISPLAY-AMOUNT
           DISPLAY '"TransactionFee":' WS-DISPLAY-AMOUNT
           DISPLAY '},'
              END-READ
           END-PERFORM.
              DISPLAY ']}'
           CLOSE USER-TRANSFERS.
           GOBACK.
