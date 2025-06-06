      *Transfer an ammount in this currency betwixt two accounts
      *An additional transfer fee is always deducted from the sender
      *If the currency of the accounts doesn#t match we get exchange fee
      *
      *The fees get added to the bank account
      *-----------------------
       IDENTIFICATION DIVISION.
      *-----------------------
       PROGRAM-ID.    TRNSFR
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
           SELECT USER-TRANSFERS ASSIGN TO TRANSFER
           ORGANIZATION IS INDEXED
           ACCESS MODE IS RANDOM
           RECORD KEY IS TR-KEY
           FILE STATUS IS WS-T-FILE-STATUS.
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
      *-------------------
       WORKING-STORAGE SECTION.
       01 WS-FROM-NAME PIC X(9).
       01 WS-TO-NAME   PIC X(9).

       01 WS-ORIGINAL-AMOUNT PIC S9(11)V9(4).
       01 WS-ORIGINAL-CURRENCY PIC X(3).

       01 WS-TRANSFER-REPORT.
           05 WS-TR-KEY.
      *From who, and when?
              10 WS-TR-MY-NAME PIC X(9).
              10 WS-TR-TIME-STAMP.
                 15 WS-TR-YEAR PIC 9(4).
                 15 WS-TR-MONTH PIC 9(2).
                 15 WS-TR-DAY PIC 9(2).
                 15 WS-TR-HOUR PIC 9(2).
                 15 WS-TR-MINUTE PIC 9(2).
                 15 WS-TR-SECOND PIC 9(2).
                 15 WS-TR-MILIS PIC 9(2).
      *who do we send to? (or from)
         05 WS-TR-THEIR-NAME PIC X(9).
         05 WS-TR-TYPE-NAME PIC X(15).
      *For example:
      * exchange fee, (bank only)
      * transaction fee, (bank only)
      * cash deposit,
      * cash withdrawal,
      * digital transfer,
      * debit card purchase,
      * mobile pay purchase
      * recuring payment
      *what amount was sent, in the currency of the transfer?
         05 WS-TR-AMOUNT PIC S9(11)V9(4).
         05 WS-TR-CURRENCY PIC X(3).
      *what amount was requested, my local currency (at the time)
      *before fees
         05 WS-TR-OWN-CURRENCY PIC X(3).
         05 WS-TR-OWN-AMOUNT PIC S9(11)V9(4).
      *What fees were deducted (are deducted from the receiving account
      *hence 0 for sender) in currency of the account
      *Bank is excempt from fees
         05 WS-TR-EXHANGE-FEE PIC S9(11)V9(4).
         05 WS-TR-TRANSACTION-FEE PIC S9(11)V9(4).
       01 FLAGS.
           05 WS-SUCCESS-WRITE PIC X VALUE 'Y'.
           05 WS-FILE-STATUS PIC XX.
           05 WS-E-FILE-STATUS PIC XX.
           05 WS-T-FILE-STATUS PIC XX.
           05 WS-VALID-CURRENCY PIC XX.
           05 WS-STAT-FILE-STATUS PIC XX.
       01 WS-EXCHANGE-CALCULATIONS.
           05 WS-AC0-CURRENCY PIC XXX.
           05 WS-AC1-CURRENCY PIC XXX.
      *Exchange rate from what the user entered to default
           05 ARG-TO-DEFAULT-RATE-MAN PIC 999999.
           05 ARG-TO-DEFAULT-RATE-EXP PIC S9.
      *And back to the account of the sende
           05 DEFAULT-TO-AC0-MAN PIC 999999.
           05 DEFAULT-TO-AC0-EXP PIC S9.
      *And the account of the receiver
           05 DEFAULT-TO-AC1-MAN PIC 999999.
           05 DEFAULT-TO-AC1-EXP PIC S9.
       01 WS-TRANSFER-CALCULATIONS.
      *positive or negative Amount the user wants to remove or insert
      *starts in arg currency, but will be converted to default.
      *The sign is there to catch bad signed inputs and respond
      *with a message
      *and it is easier since I can reuse code
           05 WS-AMOUNT PIC S9(11)V9(4).
      *The currency the amount is in right now
           05 WS-CURRENCY PIC X(3).
      *Amount to be deducted from the senders accounts (excluding fees)
      *always negative or 0 in their currency
           05 WS-AMOUNT-AC0 PIC S9(11)V9(4).
      *always negative or 0: Actual ammount subtracted from sender account
      *In account currency
           05 WS-D-BLNCE0 PIC S9(11)V9(4).
      *amount to be added to receivers account, in their currency
      *always positive or 0 in their currency
           05 WS-AMOUNT-AC1 PIC S9(11)V9(4).
      *always positive: banks cut of transfer
      *will mostly be in default currency, default currency
           05 WS-TRNS-FEE PIC S9(11)V9(4).
      *Account currency
           05 WS-TRNS-FEE-ACT PIC S9(11)V9(4).
      *always positive or 0: cost of currency exchange
      *will mostly be in default currency, default currency
           05 WS-EXCH-FEE PIC S9(11)V9(4).
      *Account currency
           05 WS-EXCH-FEE-ACT PIC S9(11)V9(4).

           05 WS-EXCHANGE-FEE PIC 9V9999.
           05 WS-TRANSACTION-FEE PIC 9V9999.

      *The above signed number may be stored in weird stupid ebsidec
      *We need to move to the below to get something readable
       01 WS-DISPLAY-SIGNED PIC -9.
       01 WS-DISPLAY-AMOUNT PIC -Z(10)9.9(4).
       LINKAGE SECTION.
       01 ARG-BUFFER.
           05 ARG-LENGTH    pic S9(4) COMP.
           05 ARG-AMOUNT    PIC X(12)XX(4).
           05 ARG-CURRENCY  PIC X(3).
           05 ARG-FROM-NAME PIC X(9).
           05 ARG-TO-NAME   PIC X(9).
       PROCEDURE DIVISION USING ARG-BUFFER.
      *------------------
       READ-INPUT.
           COMPUTE ARG-LENGTH = ARG-LENGTH - 20.
           COMPUTE WS-AMOUNT = FUNCTION NUMVAL(ARG-AMOUNT).

           IF WS-AMOUNT < 0
              DISPLAY '{'
              DISPLAY '  "success":0,'
           DISPLAY '"error":"Transfer amount can not be negative"'
              DISPLAY '}'
              GOBACK.

           MOVE SPACES TO ACT-NAME.
           MOVE ARG-CURRENCY TO WS-CURRENCY.
           MOVE ARG-FROM-NAME TO WS-FROM-NAME.
           MOVE ARG-TO-NAME(1:ARG-LENGTH) TO WS-TO-NAME.

           MOVE WS-FROM-NAME TO ACT-NAME.
       OPEN-FILES.

      *I-O, because we both need to read and write
           OPEN I-O USER-ACCOUNTS.
           OPEN I-O USER-TRANSFERS.

           OPEN INPUT STATS.
           READ STATS.
           IF WS-T-FILE-STATUS NOT = '00' AND NOT = '97'
      *If it was fault 35, Try again as output
              IF WS-T-FILE-STATUS = '35'
                 OPEN OUTPUT USER-TRANSFERS
              End-IF
      *if that didn't work, it didn't work
              IF WS-T-FILE-STATUS NOT = '00' AND NOT = '97'
              DISPLAY '{'
              DISPLAY '  "success":0,'
           DISPLAY '"error":"Transfers file error ' WS-T-FILE-STATUS '"'
              DISPLAY '}'
      * Close any files which may have been opened, should just ignore
      * any files which failed to open
               CLOSE USER-ACCOUNTS
               CLOSE USER-TRANSFERS
               CLOSE STATS
              GOBACK
              END-IF
      * Test the other files, we won't be adding new keys to them, so
      * they MUST exist and can not be taken as output
           ELSE IF WS-STAT-FILE-STATUS NOT = '00' AND NOT = '97'
              DISPLAY '{'
              DISPLAY '  "success":0,'
           DISPLAY '  "error":"Stat file error ' WS-STAT-FILE-STATUS '"'
              DISPLAY '}'
               CLOSE USER-ACCOUNTS
               CLOSE USER-TRANSFERS
               CLOSE STATS
              GOBACK
           ELSE IF WS-FILE-STATUS NOT = '00' AND NOT = '97'
              DISPLAY '{'
              DISPLAY '  "success":0,'
           DISPLAY '  "error":"Accounts file error ' WS-FILE-STATUS ' "'
              DISPLAY '}'
               CLOSE USER-ACCOUNTS
               CLOSE USER-TRANSFERS
               CLOSE STATS
              GOBACK.
       TEST-SENDER.
      *Test if receiver account exists
           MOVE WS-TO-NAME TO ACT-NAME.
           READ USER-ACCOUNTS RECORD KEY ACT-NAME
           INVALID KEY
           DISPLAY '{'
           DISPLAY '  "success":0,'
           DISPLAY '  "error":"Account ' ACT-NAME(1:ARG-LENGTH)
             ' not found"'
           DISPLAY '}'
           CLOSE USER-ACCOUNTS
           CLOSE USER-TRANSFERS
           CLOSE STATS
           GOBACK
           END-READ

      *While we are at it, save the currency we are moving to
           MOVE ACT-CURRENCY TO WS-AC1-CURRENCY.

       TRANFER-AWAY.
           MOVE WS-FROM-NAME TO ACT-NAME

      *Move amount and name to report, so we have the amount, currency
           MOVE WS-AMOUNT   TO WS-ORIGINAL-AMOUNT
           MOVE WS-CURRENCY TO WS-ORIGINAL-CURRENCY

           COMPUTE WS-EXCHANGE-FEE = FUNCTION NUMVAL(S-EXCHANGE-FEE)
           COMPUTE WS-TRANSACTION-FEE
              = FUNCTION NUMVAL(S-TRANSACTION-FEE)
      *Keep as input-output, but first check if it exists, returns error
      *Check for existing key, just get it
               READ USER-ACCOUNTS RECORD KEY ACT-NAME
               INVALID KEY
               DISPLAY '{'
               DISPLAY '  "success":0,'
               DISPLAY '  "error":"Account ' ACT-NAME(1:ARG-LENGTH)
                 ' not found"'
               DISPLAY '}'
               CLOSE USER-ACCOUNTS
               CLOSE USER-TRANSFERS
               CLOSE STATS
               GOBACK
               END-READ

      *While we are at it, save the currency we are moving from
              MOVE ACT-CURRENCY TO WS-AC0-CURRENCY.


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
      *The sender is still loaded
      *Check that the user can afford it
               IF ACT-BALANCE < - WS-D-BLNCE0
                     DISPLAY '{'
                     DISPLAY '  "success":0,'
               DISPLAY '"error":"Overdraft"'
                     DISPLAY '}'
                    CLOSE USER-ACCOUNTS
                    CLOSE USER-TRANSFERS
                    CLOSE STATS
                     GOBACK
               END-IF

      *Ok, now we can update the user account, D BLNCE is negative
               COMPUTE ACT-BALANCE = ACT-BALANCE + WS-D-BLNCE0
               REWRITE ACT-REC
      *now load the receiver account and reset it
               MOVE WS-TO-NAME TO ACT-NAME.
               READ USER-ACCOUNTS RECORD KEY ACT-NAME.
      *Ok, now we can update the user account
               COMPUTE ACT-BALANCE = ACT-BALANCE + WS-AMOUNT-AC1
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
               PERFORM LOG-TRANSFER
               CLOSE USER-ACCOUNTS
               CLOSE USER-TRANSFERS
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
               CLOSE USER-TRANSFERS
               CLOSE STATS
                 GOBACK
              ELSE
                 DISPLAY '{'
      *This will write success or failure
                 PERFORM LOG-TRANSFER
                 IF WS-SUCCESS-WRITE = 'Y'
                      DISPLAY '  "success":1,'
                      DISPLAY '"error":"No error"'
                 ELSE
      *It still counts as a success, the transaction went through
      *But the log failed to update
                      DISPLAY '  "success":1,'
                      DISPLAY '"error":"Error writing log"'
                 END-IF
                 DISPLAY '}'
               CLOSE USER-ACCOUNTS
               CLOSE USER-TRANSFERS
               CLOSE STATS
              END-IF
           GOBACK.
      *Set exchange rate variables
      *We also check for currency existing
       GET-EXCHANGE.
      *Start assuming all three currencies exist
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
                   MOVE E-EXP TO WS-DISPLAY-SIGNED
               END-READ
      *Now get the currency exchange rate of the two accounts, from def.
               MOVE WS-AC0-CURRENCY TO E-KEY
               READ EXCHANGE-RATES RECORD KEY E-KEY
               INVALID KEY
      *Currency not found
                   MOVE 'N' TO WS-VALID-CURRENCY
               NOT INVALID KEY
      *The exchange rate is stored in number of other currency, for 1DEF
      *So this is the multiplier to go from default to account
               MOVE E-MAN TO DEFAULT-TO-AC0-MAN
               MOVE E-EXP TO DEFAULT-TO-AC0-EXP
      *So we need to divide 1 by this
               MOVE E-EXP TO WS-DISPLAY-SIGNED
               END-READ
               MOVE WS-AC1-CURRENCY TO E-KEY
               READ EXCHANGE-RATES RECORD KEY E-KEY
               INVALID KEY
      *Currency not found
                   MOVE 'N' TO WS-VALID-CURRENCY
               NOT INVALID KEY
      *The exchange rate is stored in number of other currency, for 1DEF
      *So this is the multiplier to go from default to account
               MOVE E-MAN TO DEFAULT-TO-AC1-MAN
               MOVE E-EXP TO DEFAULT-TO-AC1-EXP
      *So we need to divide 1 by this
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
      *To get the exchange rate from WS-CURRENCY to ACT-CURRENCY
      *we will exchange through the default currency, and get fees there
      *Conversion is only needed if we don't have default currency now
           IF DEFAULT-CURRENCY NOT = WS-CURRENCY
              COMPUTE WS-AMOUNT = WS-AMOUNT * ARG-TO-DEFAULT-RATE-MAN
           COMPUTE WS-AMOUNT = WS-AMOUNT * 10 ** ARG-TO-DEFAULT-RATE-EXP

      *In principle WS-CURRENCY is now DEFAULT-CURRENCY, but not need to
      * actually call
      *      MOVE DEFAULT-CURRENCY TO WS-CURRENCY
           END-IF.

      *Excempt the bank account from all fees
           IF ARG-FROM-NAME NOT = "BANK     " AND
                    ARG-TO-NAME NOT = "BANK     "

      *If there is an overall change in currency, apply a fee
           IF WS-AC0-CURRENCY NOT = WS-AC1-CURRENCY
               MOVE 0 TO WS-EXCH-FEE
      *Calculate the fee while in the banks own currency
              COMPUTE WS-EXCH-FEE =  WS-AMOUNT * WS-EXCHANGE-FEE

      *The banks cut is always positive
      *This cut is now in default currency
              COMPUTE WS-EXCH-FEE = FUNCTION ABS ( WS-EXCH-FEE )
           ELSE
              MOVE 0 TO WS-EXCH-FEE
           END-IF

      *Calculate the transaction fee while in the banks own currency
              COMPUTE WS-TRNS-FEE = WS-AMOUNT * WS-TRANSACTION-FEE
      *The banks cut is always positive
      *This cut is now in default currency
              COMPUTE WS-TRNS-FEE = FUNCTION ABS ( WS-TRNS-FEE )
           ELSE
      *If either the sender or receiver is the bank, there is no fee
              MOVE 0 TO WS-TRNS-FEE
              MOVE 0 TO WS-EXCH-FEE
           END-IF.

      *Now the actual change in the balance of the SENDER's account
      *still in default currency
           COMPUTE WS-D-BLNCE0 = - WS-AMOUNT - WS-EXCH-FEE - WS-TRNS-FEE
      *Since the fee is positive, the D balance is more negative

      *Now change amount and the change in account over to the account
      *currencies
      *Convert the fees to the senders currency, their reciept is the
      *only which need include them
           IF DEFAULT-CURRENCY NOT = WS-AC0-CURRENCY
              COMPUTE WS-AMOUNT-AC0 = WS-AMOUNT * DEFAULT-TO-AC0-MAN
           COMPUTE WS-AMOUNT-AC0 = WS-AMOUNT * 10 ** DEFAULT-TO-AC0-EXP
              COMPUTE WS-D-BLNCE0 =  WS-D-BLNCE0 * DEFAULT-TO-AC0-MAN
           COMPUTE WS-D-BLNCE0 = WS-D-BLNCE0 * 10 ** DEFAULT-TO-AC0-EXP
              COMPUTE WS-EXCH-FEE-ACT = WS-EXCH-FEE * DEFAULT-TO-AC0-MAN
              COMPUTE WS-EXCH-FEE-ACT
                            = WS-EXCH-FEE-ACT * 10 ** DEFAULT-TO-AC0-EXP
              COMPUTE WS-TRNS-FEE-ACT = WS-TRNS-FEE * DEFAULT-TO-AC0-MAN
              COMPUTE WS-TRNS-FEE-ACT
                            = WS-TRNS-FEE-ACT * 10 ** DEFAULT-TO-AC0-EXP
           END-IF.
           IF DEFAULT-CURRENCY NOT = WS-AC1-CURRENCY
              COMPUTE WS-AMOUNT-AC1 = WS-AMOUNT * DEFAULT-TO-AC1-MAN
           COMPUTE WS-AMOUNT-AC1 =
            WS-AMOUNT-AC1 * 10 ** DEFAULT-TO-AC1-EXP

           END-IF.
       LOG-TRANSFER.
           MOVE WS-ORIGINAL-AMOUNT TO WS-TR-AMOUNT
           MOVE WS-ORIGINAL-CURRENCY TO WS-TR-CURRENCY
           MOVE WS-FROM-NAME TO WS-TR-MY-NAME
           MOVE FUNCTION CURRENT-DATE to WS-TR-TIME-STAMP.

           MOVE SPACES TO WS-TR-THEIR-NAME.
           MOVE ARG-TO-NAME TO WS-TR-THEIR-NAME.
           MOVE "digital transfer" TO WS-TR-TYPE-NAME

           MOVE WS-EXCH-FEE-ACT TO WS-TR-EXHANGE-FEE.
           MOVE WS-TRNS-FEE-ACT TO WS-TR-TRANSACTION-FEE.
           MOVE WS-D-BLNCE0 TO WS-TR-OWN-AMOUNT.
           MOVE WS-AC0-CURRENCY TO WS-TR-OWN-CURRENCY.

      *Also display it as a JSON object
           DISPLAY '"from-receipt":{'
           DISPLAY '"Key":"' WS-TR-KEY '",'.
           DISPLAY '"Account":"' WS-TR-MY-NAME '",'.
           DISPLAY '"Timestamp": "' WS-TR-YEAR '-' WS-TR-MONTH
           '-' WS-TR-DAY '-' WS-TR-HOUR '-' WS-TR-MINUTE '-'
           WS-TR-SECOND '-' WS-TR-MILIS '",'.

           DISPLAY '"OtherAccount":"' WS-TR-THEIR-NAME '",'.
           DISPLAY '"Type":"' WS-TR-TYPE-NAME '",'.

           MOVE WS-TR-AMOUNT TO WS-DISPLAY-AMOUNT
           DISPLAY '"AmountNominal":-' WS-DISPLAY-AMOUNT ','
           DISPLAY '"TransactionCurrency": "' WS-TR-CURRENCY '",'
           MOVE WS-TR-OWN-AMOUNT TO WS-DISPLAY-AMOUNT
           DISPLAY '"AmountTransfered":' WS-DISPLAY-AMOUNT ','.
           DISPLAY '"OwnCurrency": "' WS-TR-OWN-CURRENCY '",'.

           MOVE WS-TR-EXHANGE-FEE TO WS-DISPLAY-AMOUNT
           DISPLAY '"ExchangeFee":' WS-DISPLAY-AMOUNT ','.

           MOVE WS-TR-TRANSACTION-FEE TO WS-DISPLAY-AMOUNT
           DISPLAY '"TransactionFee":' WS-DISPLAY-AMOUNT.
           DISPLAY '},'.
           MOVE WS-TRANSFER-REPORT TO TR-RECORD.
           WRITE TR-RECORD
           INVALID KEY
      *Should NEVER happen unless transactions happen same millisecond
              MOVE 'N' to WS-SUCCESS-WRITE
           END-WRITE.


           MOVE WS-ORIGINAL-AMOUNT TO WS-TR-AMOUNT
           MOVE WS-ORIGINAL-CURRENCY TO WS-TR-CURRENCY
           MOVE WS-TO-NAME TO WS-TR-MY-NAME
           MOVE FUNCTION CURRENT-DATE to WS-TR-TIME-STAMP.

           MOVE SPACES TO WS-TR-THEIR-NAME.
           MOVE ARG-FROM-NAME TO WS-TR-THEIR-NAME.
           MOVE "digital transfer" TO WS-TR-TYPE-NAME

           MOVE 0 TO WS-TR-EXHANGE-FEE.
           MOVE 0 TO WS-TR-TRANSACTION-FEE.
           MOVE WS-AMOUNT-AC1 TO WS-TR-OWN-AMOUNT.
           MOVE WS-AC1-CURRENCY TO WS-TR-OWN-CURRENCY.
      *Also display it as a JSON object
           DISPLAY '"to-receipt":{'
           DISPLAY '"Key":"' WS-TR-KEY '",'.
           DISPLAY '"Account":"' WS-TR-MY-NAME '",'.
           DISPLAY '"Timestamp": "' WS-TR-YEAR '-' WS-TR-MONTH
           '-' WS-TR-DAY '-' WS-TR-HOUR '-' WS-TR-MINUTE '-'
           WS-TR-SECOND '-' WS-TR-MILIS '",'.

           DISPLAY '"OtherAccount":"' WS-TR-THEIR-NAME '",'.
           DISPLAY '"Type":"' WS-TR-TYPE-NAME '",'.

           MOVE WS-TR-AMOUNT TO WS-DISPLAY-AMOUNT
           DISPLAY '"AmountNominal":' WS-DISPLAY-AMOUNT ','
           DISPLAY '"TransactionCurrency": "' WS-TR-CURRENCY '",'
           MOVE WS-TR-OWN-AMOUNT TO WS-DISPLAY-AMOUNT
           DISPLAY '"AmountTransfered":' WS-DISPLAY-AMOUNT ','.
           DISPLAY '"OwnCurrency": "' WS-TR-OWN-CURRENCY '",'.

           MOVE WS-TR-EXHANGE-FEE TO WS-DISPLAY-AMOUNT
           DISPLAY '"ExchangeFee":' WS-DISPLAY-AMOUNT ','.

           MOVE WS-TR-TRANSACTION-FEE TO WS-DISPLAY-AMOUNT
           DISPLAY '"TransactionFee":' WS-DISPLAY-AMOUNT.
           DISPLAY '},'.
           MOVE WS-TRANSFER-REPORT TO TR-RECORD.
           WRITE TR-RECORD
           INVALID KEY
      *Should NEVER happen unless transactions happen same millisecond
              MOVE 'N' to WS-SUCCESS-WRITE
           END-WRITE.
