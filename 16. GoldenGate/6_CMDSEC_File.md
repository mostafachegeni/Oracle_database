# CMDSEC File
=============================================================
-------------------------------------------------------------
=============================================================
[docs.oracle.com](https://docs.oracle.com/en/cloud/paas/goldengate-cloud/gwuad/configuring-ggsci-command-security.html#GUID-BF267A08-4470-4ACB-BA10-E35D72B2F48E)


------------------------------------------------------------------------------
- Login as new user "ggmonitor":
```
[ggmonitor@shdgtest ~]$ vi .bash_profile
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1
export LD_LIBRARY_PATH=/usr/lib:/usr/X11R6/lib:$ORACLE_HOME/lib
export ORACLE_SID=S1T2
export PATH=$ORACLE_HOME/bin:$PATH
export TMP=/tmp; 
export TMPDIR=/tmp; 
```
=============================================================
-------------------------------------------------------------
=============================================================
