//DEPWITC JOB 1,NOTIFY=&SYSUID
//***************************************************/
//STEP1 EXEC PGM=SETXCH,PARM='1100-003USDUS Dollar'
//*Link VSAM file
//EXCHANGE DD DSN=&SYSUID..BANK.EXCHANGE,DISP=SHR
//*Link libraries
//STEPLIB DD DSN=&SYSUID..BANK.LOAD,DISP=SHR
//SYSOUT    DD SYSOUT=*,OUTLIM=15000
//CEEDUMP   DD DUMMY
//SYSUDUMP  DD DUMMY