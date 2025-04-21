Cobol Reserve Bank program
=====================
This training project in Cobol and Ibm Z/OS simulates a bank emulated with dozens of Cobol and JCL program.

The bank can store multiple different accounts, denoted in different currencies, and there are Cobol programs which can handle transfers betwixt accounts, or deposits, and withdrawals.

The bank's own account gets a cut of all currency conversions, and adds interest to user accounts from bank accounts or gathers interest from dept. There is a different interest rate for dept.



Main challanges
================
The main interesting challanges (beyond my earlier COBOL Navy project) I had to solve were: working with floating point numbers in Cobol, and viewing lists of entries for certain users in VSAM files.

Floating point numbers
---------
The exchange rate between currencies must be floating point numbers, that is decimal numbers where we don't know where the decimal is.

That is how every civilized language stores decimal numbers, but not COBOL, COBOL wants to know exactly how many digits are before or after the decimal marker.

There are situation where the COBOL approach is better than even C++, but this is Not one of them. Today, there may be 6.45 Kr per US$, but if or when Trump finds the room with the money printer that might drop to 1 Kr per million US$

COBOL does support floating point numbers `COMP 2` ... but they are not as flexible as a `double` in C++, in particular there is not good way of printing the value in a useable format, nor is there a good way of uploading a floating point number to a COBOL program.

The `DISPLAY` statement only prints the individual bytes of the number, and the `NUMVAL` function for converting strings to numbers only understands digits and explicit decimals.

IBM claims that is because there doesn't exist a way of writing floating point numbers; this is not true, scientific notation exist, where we write the number `0.00001356` as `1.356e-5`. The number before the e is called the mantissa, the number after is the exponent.

This is understood by numerous programming languges such as C++, C\# regular C and Javascript, and as such is accepted bythe JSON format (the format of the internet, which I am going to be using for returning the result of the COBOL programs).

It is possible to convert a `COMP-2` number to its mantissa and exponent in Cobol, and using it, it is possible to print it in scientific notation. It is also possible to extract the mantissa and exponent from a string in scientific notation... But doing so is so difficult, uggly and annoying that it was easier to just implement my own floating point numbers, by explicitly storing the mantissa and exponent of exchange rates as variables in my Cobol program.

In particular my Mantissa of the exchange rate is stored with 6 digits, and my exponent has 1 digit and a sign.

This takes the same number of bytes as a `COMP-2` but has slightly smaller range of exponents, but in practice the exchange rate between two currencies is very unlikely to be a billion to one (and if it is, if Trump does find the aforementioned money-printer, I doubt anybody will be doing any transfers in that currency anyway)


Setting up the project
==============

COBOL project
------------
The Cobol and JCL scripts are stored in z67124/bank/cbl and z67124/bank/jcl which mirror the structure on the Z/OS mainframe (my free account on Z explorer is z67124, replace it with yours if you have one).

In general jcl scripts ending with a C compile the associated cobol file.

The JCL scripts resetusr.jcl and makexchn.jcl create empty VSAM files containing exchange rates and users (they include my account explicitly, so may require some reworking if yours is different)

The file z67124/bank/stats.txt must also be uploaded to the mainframe, it contains some basic stats, including default currency, fees, and the (unused) interest rate.

C\# middleware
------------
The C\# dotnet project acts as middleware betwixt a swagger frontend, and the Z/OS mainframe. 

In particular it allows you to add or see users, deposit or withdraw money, and transfer money between accounts.

All actual calculations happen in the Cobol programs

Quick note: how to download the files
----------
Cobol and JCL files can be downloaded with the zowe cli:, for example:

    zowe zos-files download all-members "Z67124.BANK.CBL"

After doing so it is necessary to fix the file-endings with the following bash command (use git bash on windows)

    for file in z67124/bank/cbl/*; do mv "$file" "${file%.txt}.cbl"; done

This is how I have updated the files in the project, if it looks like the github repo is having the files deleted and new files created in one commit, it is simply because I have run those commands.