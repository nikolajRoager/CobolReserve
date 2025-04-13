      *deposit or withdraw an ammount in this currency on this account
      *A transfer fee is always added to the bank's account
      *If the currency doesn't match the account, we get an exchange fee
      *
      *In the event of a deposit, the fees are taken from the amount
      *So the amount deposited to the account is smaller
      *
      *In the event of a withdrawal, the fees are taken from the account
      *So the amount taken from the account is larger
      *
      *The fees get added to the bank account
      *-----------------------
       IDENTIFICATION DIVISION.
      *-----------------------
       PROGRAM-ID.    DEPWIT
       AUTHOR.        Nikolaj R Christensen
      *--------------------
       ENVIRONMENT DIVISION.
      *--------------------
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT USER-ACCOUNTS ASSIGN TO ACCOUNTS
           ORGANIZATION IS INDEXED
           ACCESS MODE IS RANDOM
           RECORD KEY IS ACT-NAME
           FILE STATUS IS WS-FILE-STATUS.
           SELECT STATS ASSIGN TO STATFILE
              FILE STATUS IS WS-STAT-FILE-STATUS.
      *For converting deposit
           SELECT EXCHANGE-RATES ASSIGN TO EXCHANGE
              ORGANIZATION IS INDEXED
              ACCESS MODE IS DYNAMIC
              RECORD KEY IS E-KEY
              FILE STATUS IS WS-E-FILE-STATUS.
      *-------------
       DATA DIVISION.
      *-------------
       FILE SECTION.
       FD  USER-ACCOUNTS DATA RECORD IS ACT-REC.
       01 ACT-REC.
           05 ACT-NAME     PIC X(9).
           05 ACT-BALANCE  PIC 9(12)V9(4).
           05 ACT-CURRENCY PIC X(3).
       FD  STATS RECORDING MODE F.
       01 STAT-RECORD.
           05 DEFAULT-CURRENCY PIC X(3).
           05 FILLER PIC X VALUE SPACE.
           05 S-TRANSACTION-FEE PIC XXXXXX.
           05 FILLER PIC X VALUE SPACE.
           05 S-EXCHANGE-FEE PIC XXXXXX.
           05 FILLER PIC X VALUE SPACE.
           05 S-INTEREST PIC XXXXXX.
           05 FILLER PIC X VALUE SPACE.
           05 S-DEPT-INTEREST PIC XXXXXX.
      *The file assumes itself to be one line
           05 FILLER PIC X(49) VALUE SPACES.
       FD  EXCHANGE-RATES DATA RECORD IS E-RECORD.
       01  E-RECORD.
           05 E-KEY PIC X(3).
           05 E-NAME PIC X(20).
           05 E-MAN  PIC 999999.
           05 E-EXP  PIC S9.
      *-------------------
       WORKING-STORAGE SECTION.
       01 FLAGS.
           05 WS-FILE-STATUS PIC XX.
           05 WS-E-FILE-STATUS PIC XX.
           05 WS-VALID-CURRENCY PIC XX.
           05 WS-STAT-FILE-STATUS PIC XX.
       01 WS-EXCHANGE-CALCULATIONS.
      *Exchange rate from what the user entered to default
           05 ARG-TO-DEFAULT-RATE-MAN PIC 999999.
           05 ARG-TO-DEFAULT-RATE-EXP PIC S9.
      *And back to what they want
           05 DEFAULT-TO-ACT-RATE-MAN PIC 999999.
           05 DEFAULT-TO-ACT-RATE-EXP PIC S9.
       01 WS-TRANSFER-CALCULATIONS.
      *positive or negative Amount the user wants to remove or insert
      *Will be converted to account currency! arg ammount have original
           05 WS-AMOUNT PIC S9(11)V9(4).
           05 WS-DUM PIC 9V99.
      *The currency the amount is in right now
           05 WS-CURRENCY PIC X(3).
      *always positive: banks cut of transfer
      *will mostly be in default currency, only converted to account end
           05 WS-TRNS-FEE PIC S9(11)V9(4).
      *always positive or 0: cost of currency exchange
      *will mostly be in default currency, only converted to account end
           05 WS-EXCH-FEE PIC S9(11)V9(4).
      *positive or negative: Actual ammount added to the account
      *In account currency
           05 WS-D-BLNCE PIC S9(11)V9(4).

           05 WS-EXCHANGE-FEE PIC 9V9999.
           05 WS-TRANSACTION-FEE PIC 9V9999.

      *The above signed number may be stored in weird stupid ebsidec
      *We need to move to the below to get something readable
       01 WS-DISPLAY-SIGNED PIC -9.
       01 WS-DISPLAY-AMOUNT PIC -9(11).9(4).
       LINKAGE SECTION.
       01 ARG-BUFFER.
           05 ARG-LENGTH pic S9(4) COMP.
           05 ARG-AMOUNT PIC X(12)XX(4).
           05 ARG-CURRENCY PIC X(3).
           05 ARG-NAME     PIC X(9).
       PROCEDURE DIVISION USING ARG-BUFFER.
      *------------------
       READ-INPUT.
           COMPUTE ARG-LENGTH = ARG-LENGTH - 21.
           COMPUTE WS-AMOUNT = FUNCTION NUMVAL(ARG-AMOUNT).
           MOVE SPACES TO ACT-NAME.
           MOVE ARG-CURRENCY TO WS-CURRENCY.
           MOVE ARG-NAME(1:ARG-LENGTH) TO ACT-NAME.
       OPEN-FILES.

      *I-O, because we both need to read and write
           OPEN I-O USER-ACCOUNTS.
           OPEN INPUT STATS.
           READ STATS.
           IF WS-STAT-FILE-STATUS NOT = '00' AND NOT = '97'
      * We don't need to close it, it is not open
              DISPLAY '{'
              DISPLAY '  "success":0,'
           DISPLAY '  "error":"Stat file error ' WS-STAT-FILE-STATUS '"'
              DISPLAY '}'
              GOBACK
           ELSE IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
      * We don't need to close it, it is not open
              DISPLAY '{'
              DISPLAY '  "success":0,'
           DISPLAY '  "error":"Accounts file error ' WS-FILE-STATUS ' "'
              DISPLAY '}'
              GOBACK
           ELSE
              MOVE ARG-NAME TO ACT-NAME
           COMPUTE WS-EXCHANGE-FEE = FUNCTION NUMVAL(S-EXCHANGE-FEE)
           COMPUTE WS-TRANSACTION-FEE
              = FUNCTION NUMVAL(S-TRANSACTION-FEE)
      *Keep as input-output, but first check if it exists, returns error
      *Check for existing key, just get it
               READ USER-ACCOUNTS RECORD KEY ACT-NAME
               INVALID KEY
               DISPLAY '{'
               DISPLAY '  "success":0,'
               DISPLAY '  "error":"Account ' ACT-NAME ' not found "'
               DISPLAY '}'
               CLOSE USER-ACCOUNTS
               CLOSE STATS
               GOBACK
               END-READ

      *Check if currency is valid, setting exchange rates in process
              PERFORM GET-EXCHANGE
              IF WS-VALID-CURRENCY = 'N'
                 DISPLAY '{'
                 DISPLAY '  "success":0,'
                 DISPLAY '  "error":"currency not supported"'
                 DISPLAY '}'
                 GOBACK
              END-IF
      *00, opened succesfullu, 97, opened, but not closed correctly last

      *Convert currencies and calculate expected fees
               PERFORM CALC-CURRENCY-AND-FEES
           MOVE WS-AMOUNT TO WS-DISPLAY-AMOUNT
           DISPLAY 'Amout         :' WS-DISPLAY-AMOUNT  WS-CURRENCY
           MOVE WS-TRANSACTION-FEE TO WS-DISPLAY-AMOUNT
           DISPLAY 'Transactionfee:' WS-DISPLAY-AMOUNT  DEFAULT-CURRENCY
           MOVE WS-EXCHANGE-FEE TO WS-DISPLAY-AMOUNT
           DISPLAY 'Exchange-fee  :' WS-DISPLAY-AMOUNT  DEFAULT-CURRENCY
           MOVE WS-D-BLNCE TO WS-DISPLAY-AMOUNT
           DISPLAY 'Total change  :' WS-DISPLAY-AMOUNT  WS-CURRENCY
           MOVE ACT-BALANCE TO WS-DISPLAY-AMOUNT
           DISPLAY 'Balance before:' WS-DISPLAY-AMOUNT  WS-CURRENCY

      *Check that the user can afford it
               IF ACT-BALANCE < WS-D-BLNCE
                     DISPLAY '{'
                     DISPLAY '  "success":0,'
               DISPLAY '"error":"Overdraft"'
                     DISPLAY '}'
                     CLOSE USER-ACCOUNTS
                     CLOSE STATS
                     GOBACK
               END-IF

      *Ok, now we can update the user account
               COMPUTE ACT-BALANCE = ACT-BALANCE + WS-D-BLNCE
               REWRITE ACT-REC
      *And update the bank
               MOVE "BANK     " TO ACT-NAME
               READ USER-ACCOUNTS RECORD KEY ACT-NAME
               INVALID KEY
               DISPLAY '{'
      *Shouldn't happen, but if it does the transfer did succeed
               DISPLAY '  "success":1,'
               DISPLAY '  "error":"Bank account not found"'
               DISPLAY '}'
               CLOSE USER-ACCOUNTS
               CLOSE STATS
               GOBACK
               END-READ

      *Exploit the proletariate real hard right here
           COMPUTE ACT-BALANCE = ACT-BALANCE + WS-TRNS-FEE + WS-EXCH-FEE
               REWRITE ACT-REC

               IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
      * We don't need to close it, it is not open
                 DISPLAY '{'
                 DISPLAY '  "success":0,'
           DISPLAY '"error":"Writing accounts error ' WS-FILE-STATUS '"'
                 DISPLAY '}'
                 CLOSE USER-ACCOUNTS
                 CLOSE STATS
                 GOBACK
              ELSE
                 DISPLAY '{'
                 DISPLAY '  "success":1,'
                 DISPLAY '"error":"No error"'
                 DISPLAY '}'
              END-IF
           END-IF
           CLOSE USER-ACCOUNTS
           CLOSE STATS
           GOBACK.
      *Set exchange rate variables
      *We also check for currency existing
       GET-EXCHANGE.
      *Start assuming both currencies exist
           MOVE 'Y' TO WS-VALID-CURRENCY
           OPEN INPUT EXCHANGE-RATES
           IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
      *Currency not found, nor the file it is in
               MOVE 'N' TO WS-VALID-CURRENCY
           ELSE
               MOVE WS-CURRENCY TO E-KEY
               READ EXCHANGE-RATES RECORD KEY E-KEY
               INVALID KEY
      *Currency not found
                   MOVE 'N' TO WS-VALID-CURRENCY
               NOT INVALID KEY
      *The exchange rate is stored in number of other currency,
      *to get 1 default currency
      *so we need to divide 1 by this to get the multiplier from arg to
      *default
      *1= 100000E-5, apply the first to the mantissa, and the second EXP
      *    DISPLAY WS-CURRENCY '>' DEFAULT-CURRENCY ':' E-MAN 'E' E-EXP
                   COMPUTE E-MAN = 100000 / E-MAN
                   COMPUTE E-EXP = - E-EXP - 5
                   MOVE E-MAN TO ARG-TO-DEFAULT-RATE-MAN
                   MOVE E-EXP TO ARG-TO-DEFAULT-RATE-EXP
           DISPLAY WS-CURRENCY '>' DEFAULT-CURRENCY ':' E-MAN 'E' E-EXP
               END-READ
               MOVE ACT-CURRENCY TO E-KEY
               READ EXCHANGE-RATES RECORD KEY E-KEY
               INVALID KEY
      *Currency not found
           DISPLAY E-KEY 'NOT FOUND'
                   MOVE 'N' TO WS-VALID-CURRENCY
               NOT INVALID KEY
      *The exchange rate is stored in number of other currency, for 1DEF
      *So this is the multiplier to go from default to account
                   MOVE E-MAN TO DEFAULT-TO-ACT-RATE-MAN
                   MOVE E-EXP TO DEFAULT-TO-ACT-RATE-EXP
      *So we need to divide 1 by this
           DISPLAY DEFAULT-CURRENCY '>' ACT-CURRENCY ':' E-MAN 'E' E-EXP

           DISPLAY ARG-TO-DEFAULT-RATE-MAN 'E' ARG-TO-DEFAULT-RATE-EXP
               END-READ
           END-IF
           CLOSE EXCHANGE-RATES.


      *This chunk of code makes sure the depost/withdrawal currency
      *matches account, if not, we convert it and take a cut to the bank
      *and also calculates EXCHANGE-FEE and TRANSACTION-FEE
      *
      *After this function the fees will be in default currency
      *And WS-AMOUNT and WS-D-BLNCE will both be in account currency
       CALC-CURRENCY-AND-FEES.

           MOVE WS-AMOUNT TO WS-DISPLAY-AMOUNT
           DISPLAY WS-DISPLAY-AMOUNT ' ' WS-CURRENCY
      *To get the exchange rate from WS-CURRENCY to ACT-CURRENCY
      *we will exchange through the default currency, and get fees there
      *Conversion is only needed if we don't have default currency now
           IF DEFAULT-CURRENCY NOT = WS-CURRENCY
              COMPUTE WS-AMOUNT = WS-AMOUNT * ARG-TO-DEFAULT-RATE-MAN
           COMPUTE WS-AMOUNT = WS-AMOUNT * 10 ** ARG-TO-DEFAULT-RATE-EXP


           MOVE WS-AMOUNT TO WS-DISPLAY-AMOUNT
           DISPLAY WS-DISPLAY-AMOUNT ' ' DEFAULT-CURRENCY
      *In principle WS-CURRENCY is now DEFAULT-CURRENCY, but not need to
      * actually call
      *      MOVE DEFAULT-CURRENCY TO WS-CURRENCY
           END-IF.

      *If there is an overall change in currency, apply a fee
           IF ARG-CURRENCY NOT = ACT-CURRENCY
               MOVE WS-AMOUNT TO WS-DISPLAY-AMOUNT
               MOVE 0 TO WS-EXCH-FEE
      *Calculate the fee while in the banks own currency
              COMPUTE WS-EXCH-FEE =  WS-AMOUNT * WS-EXCHANGE-FEE
              MOVE WS-EXCH-FEE TO WS-DISPLAY-AMOUNT

      *The banks cut is always positive
      *This cut is now in default currency
              COMPUTE WS-EXCH-FEE = FUNCTION ABS ( WS-EXCH-FEE )
           ELSE
              MOVE 0 TO WS-EXCH-FEE
           END-IF

      *Calculate the fee while in the banks own currency
              COMPUTE WS-TRNS-FEE = WS-AMOUNT * WS-TRANSACTION-FEE
      *The banks cut is always positive
      *This cut is now in default currency
              COMPUTE WS-TRNS-FEE = FUNCTION ABS ( WS-TRNS-FEE )

      *Now the actual change in the balance is this (default currency):
           COMPUTE WS-D-BLNCE = WS-AMOUNT - WS-EXCH-FEE - WS-TRNS-FEE
      *Since the fee is positive, the deposit will be smaller, or larger
      *withdrawal will be made

      *Now change amount and the change in account over to the account
      *currency
            IF DEFAULT-CURRENCY NOT = ACT-CURRENCY
              COMPUTE WS-AMOUNT = WS-AMOUNT * DEFAULT-TO-ACT-RATE-MAN
           COMPUTE WS-AMOUNT = WS-AMOUNT * 10 ** DEFAULT-TO-ACT-RATE-EXP
              COMPUTE WS-D-BLNCE = WS-D-BLNCE * DEFAULT-TO-ACT-RATE-MAN
           COMPUTE WS-AMOUNT = WS-AMOUNT * 10 ** DEFAULT-TO-ACT-RATE-EXP
      *This is the currency we are using now
              MOVE ACT-CURRENCY TO WS-CURRENCY
            MOVE WS-AMOUNT TO WS-DISPLAY-AMOUNT
            DISPLAY WS-DISPLAY-AMOUNT ' ' WS-CURRENCY
            END-IF.
