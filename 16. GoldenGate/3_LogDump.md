# LogDump

- **To find the transaction that has caused Replicat to "ABEND", follow these steps**:
----------------------------------------------------------------------------------------------

0. Find "Error" in OGG LogFile (Replicat):
```
[ ]$ cd /u01/app/oracle/product/gg/
[ ]$ ./ggsci
GGSCI> DBLogin UserIDAlias ogg_user 

GGSCI> info all
Program     Status      Group       Lag at Chkpt  Time Since Chkpt
MANAGER     RUNNING
REPLICAT    ABENDED     RSH         653:55:55     25:21:28


GGSCI> info RSH detail
REPLICAT   RSH       Last Started 2021-01-24 15:54   Status ABENDED
INTEGRATED
Checkpoint Lag       653:55:55 (updated 24:19:54 ago)
Log Read Checkpoint  File /home/oracle/ogg/dirdat/ps000000096
                     2020-12-27 10:39:31.605582  RBA 23332566
Current directory    /home/oracle/ogg
Report file          /home/oracle/ogg/dirrpt/RSH.rpt
Parameter file       /home/oracle/ogg/dirprm/rsh.prm
Checkpoint file      /home/oracle/ogg/dirchk/RSH.cpr
Process file
Error log            /home/oracle/ogg/ggserr.log


[ ]$ less /home/oracle/ogg/ggserr.log
2021-01-24T17:56:19.532+0330  INFO    OGG-02333  Oracle GoldenGate Delivery for Oracle, rsh.prm:  Reading /home/oracle/ogg/dirdat/ps000000097, current RBA 3,828, 2 records, m_file_seqno = 97, m_file_rba = 4,071.
2021-01-24T17:56:19.533+0330  ERROR   OGG-01668  Oracle GoldenGate Delivery for Oracle, rsh.prm:  PROCESS ABENDING.

```

----------------------------------------------------------------------------------------------
1. Open The above Trail:
```
[GoldenGate]$ $GG_HOME/logdump
Logdump> open /home/oracle/ogg/dirdat/ps000000097
Current LogTrail is /home/oracle/ogg/dirdat/ps000000097
```

----------------------------------------------------------------------------------------------
2. Set Output Format: 

- Set trail file header details on: The FILEHEADER contains the header details of the currently opened trail file.
```
Logdump> FILEHEADER DETAIL
```

- Record Header: 
```
Logdump> GHDR ON
```

- Set Column Details on: It displays the list of columns, their ID, length, Hex values etc.
```
Logdump> DETAIL ON
```

- User Token Details: User token is the user-defined information stored in a trail, associated with the table mapping statements. The CSN (SCN in Oracle Database) associated with the transaction is available in this section.
```
Logdump> USERTOKEN DETAIL
```

- Set length of the record to be displayed: In this case, it is 1024 characters.
```
Logdump> RECLEN 1024
```

----------------------------------------------------------------------------------------------
3. Go to "RBA=3828":
```
Logdump> pos 3828
Reading forward from RBA 3828
```

----------------------------------------------------------------------------------------------
4. Read Next Record: 
> NOTE: This is an "INSER" Transsaction: 
> Data = [2248570110, 1, 2021-01-03:15:26:03.160000000, 020820210103152533623867, 3, 0, 958989675, 324201824, 324201824] 
> 		 This Transaction results in "ABENDING" the Replicat RSH. 

```
Logdump> n
___________________________________________________________________
Hdr-Ind    :     E  (x45)     Partition  :     .  (x0c)
UndoFlag   :     .  (x00)     BeforeAfter:     A  (x41)
RecLength  :   163  (x00a3)   IO Time    : 2021/01/10 15:57:58.375.252
IOType     :     5  (x05)     OrigNode   :   255  (xff)
TransInd   :     .  (x02)     FormatType :     R  (x52)
SyskeyLen  :     0  (x00)     Incomplete :     .  (x00)
AuditRBA   :       3866       AuditPos   : 730057636
Continued  :     N  (x00)     RecCount   :     1  (x01)

2021/01/10 15:57:58.375.252 Insert               Len   163 RBA 3828
Name: SHAHKAR3.SUBSCRIPTION_REQUEST  (TDR Index: 2)
After  Image:                                             Partition x0c   G  e
 0000 0e00 0000 0a00 3232 3438 3537 3031 3130 0100 | ........2248570110..
 0500 0000 0100 3102 001f 0000 0032 3032 312d 3031 | ......1......2021-01
 2d30 333a 3135 3a32 363a 3033 2e31 3630 3030 3030 | -03:15:26:03.1600000
 3030 0300 1c00 0000 1800 3032 3038 3230 3231 3031 | 00........0208202101
 3033 3135 3235 3333 3632 3338 3637 0400 0500 0000 | 03152533623867......
 0100 3305 0005 0000 0001 0030 0600 0d00 0000 0900 | ..3........0........
 3935 3839 3839 3637 3507 000d 0000 0009 0033 3234 | 958989675........324
 3230 3138 3234 0800 0d00 0000 0900 3332 3432 3031 | 201824........324201
 3832 34                                           | 824
Column     0 (x0000), Len    14 (x000e)
Column     1 (x0001), Len     5 (x0005)
Column     2 (x0002), Len    31 (x001f)
Column     3 (x0003), Len    28 (x001c)
Column     4 (x0004), Len     5 (x0005)
Column     5 (x0005), Len     5 (x0005)
Column     6 (x0006), Len    13 (x000d)
Column     7 (x0007), Len    13 (x000d)
Column     8 (x0008), Len    13 (x000d)
___________________________________________________________________

```

