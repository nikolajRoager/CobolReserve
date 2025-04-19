Cobol Reserve Bank program
=====================
A curency reserve bank emulated with a Cobol program. We need to store a few accounts, with amount stored, denoted in different currencies, and transfer history stored on the Z-Explore mainframe.

There need to be a way of updating exchange rate betwixt currencies, transfering between accounts, including currency conversions

The banks need its own account, which gets a cut of all currency conversions, and adds interest to user accounts from bank accounts or gathers interest from dept. There is a different interest rate for dept.


Wisthlist
========

Currency, and global settings
-----------------
All currency is relative to the default currency, a VSAM file contains the currency name, and exchange rate to default currency, keyed by their code (like EUR, DKK, etc). The default currency is also in the list but its exchange rate is forced to be 1

A global constant file sets default currency key. This should not be changed in normal use! It can only be changed by uploading it

A global settings file contains the transaction fee, and exchange fee, interest rate, and time the history was started

A COBOL program allows the uploading of new exchange rates

A GETTIME function gets a fictional time (clock is running at a day per 30 seconds)

A C\# program automatically updates the exchange rates, either using historical or fictional data


Accounts and transfers
----------
Accounts can be added using a JCL program, callable from C\#, each account stores: 9 letter name, account currency, balance, and a list of all historical transaction betwixt other accounts. 

Transfers contain TRANSFER-ID DATE-TIME OTHER-ID OTHER-CURRENCY AMMOUNT-MYACCOUNT AMMOUNT-SEND AMMOUNT-TRANSFER-FEE AMMOUNT-EXCHANGE-FEE. If OTHER-ID is literally "OUTSIDE" the transfer is a withdrawal or money deposited from outside.

It is possible to deposit or withdraw money to your account by calling a cobol program.

This Cobol program returns a JSON report, reporting if the operation was successful, and reporting all fees and amounts. If successful, money is added to or withdrawn from the user account in the currency of that account, a transfer fee is added to the bank account (taken from the depositted amount, or the account in the case of a withdrawal); if the deposit or withdrawal is a different currency, it is converted to that of the account, and an exchange fee is deducted.

The bank account is excempt from all fees.

A similar program allows transfer of money betwixt accounts; the same transfer fee is applied. The amount can be denoted in any currency, an exchange fee is only included if the receiving account has different currency than the sender.

No password check is performed on the IBM Z/OS mainframe, since it realistically is running on an offline mainframe, in the same building as the C# middleware server. So password checks should happen on the C# side.

Interest calculation
-----------
A COBOL program on the mainframe automatically transfers interest to or from each account.

Files and structure
=====
The file structure of this repository exactly mirrors the file structure on the mainframe, I assume the project is stored in z99999.BANK (where 99999 is our user id)

I know the folders aren't nested on IBM Z/OS, but I name them as if they were, and it is easier to think of them that way, and just search for z99999.BANK to only see the bank

BANK contains settings and data
---------
Contains various data used by the programs, DEFAULT simply contains the default currency key and name

STATS contain stats for the bank, from left to right, separeted with 1 space transfer fee, exchange fee, interest on deposits, interest on dept, everything is stored as ZVZZZZ representing a percentage (for instance 1.0000 is 100%)

finally the VSAM file EXCHANGE (can be created as empty with BANK.JCL.MAKEXCHN.JCL) contains the currencies, identified by their 3 letter abbreviation, and containing their name (up to 20 chars), and exchange rate to the default currency (COMP-2), this is needed!!! as both the other and default currency may experience hyper-inflation!

That is, we use 3 bytes for the key, 20 for the name, and 8 for a COMP-8, for 31 in total, which I am just going to round up to 32 bytes. The exchange data can be populated with example data by running SETXCHNJ.jcl (runs the program compiled from SETXCHNG.cbl with default parameters)

USERS
----------
The users live in a data-set USERS, user acounts are stored in USERS.ACCOUNTS the transfers in USERS.TRANSFERS, really I want TRANSFER to be reset every year, month or whatever, with older versions archived, but time compelled me not to do that.

USER.ACCOUNTS has 80 chars, but stores only key (10 chars), name (10 chars), account balance (16 digits, and 8 decimals), denominated currency (3 char), and password has: (10 chars), the rest is set asside for future

JCL
------
All JCL jobs live here, that includes compile jobs (end with a C), and run jobs (ends with a J), these jobs often have default parameters

Compile jobs generally don't compile dependencies, that is up to the user.

CBL
-------
All cobol code live here, I try to keep the names 7 letters or below so that the compile jobs can match without going over the 8 char limit

LOAD
----
All compiled programs get put here by the compile jobs