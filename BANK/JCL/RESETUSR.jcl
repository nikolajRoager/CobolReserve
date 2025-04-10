//VSMCRJ JOB 1,NOTIFY=&SYSUID
//***************************************************/
//STEP1    EXEC PGM=IDCAMS
//SYSPRINT   DD SYSOUT=*
//SYSIN      DD *
  DELETE Z67124.BANK.USERS.ACCOUNTS
  SET MAXCC=0
  DEFINE CLUSTER(     -
    NAME(Z67124.BANK.USERS.ACCOUNTS) -
    TRACKS(30)        -
    RECSZ(80 80)    -
    INDEXED           -
    KEYS(3 0)        -
    CISZ(1024))
