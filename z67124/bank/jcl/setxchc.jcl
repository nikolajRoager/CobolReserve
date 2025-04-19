//SETEXCHC  JOB 1,NOTIFY=&SYSUID
//***************************************************/
//STEP1 EXEC IGYWCL
//*SECOND compile task, compile the program to list ships
//COBOL.SYSIN  DD DSN=&SYSUID..BANK.CBL(SETXCH),DISP=SHR
//LKED.SYSLMOD DD DSN=&SYSUID..BANK.LOAD(SETXCH),DISP=SHR
