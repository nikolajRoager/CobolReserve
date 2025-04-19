//DEPWITC JOB 1,NOTIFY=&SYSUID
//***************************************************/
//STEP1 EXEC IGYWCL
//*SECOND compile task, compile the program to list ships
//COBOL.SYSIN  DD DSN=&SYSUID..BANK.CBL(DEPWIT),DISP=SHR
//LKED.SYSLMOD DD DSN=&SYSUID..BANK.LOAD(DEPWIT),DISP=SHR
//*Link VSAM file
//ACCOUNTS DD DSN=&SYSUID..BANK.USERS.ACCOUNTS,DISP=SHR
