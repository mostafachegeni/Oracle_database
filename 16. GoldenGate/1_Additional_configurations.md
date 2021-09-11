# Additional configurations

========================================================================================
----------------------------------------------------------------------------------------
========================================================================================
- add "New Directory" for Trail Files:
```
	GGSCI> edit params ./GLOBALS
	ALLOWOUTPUTDIR /disk_1000/gg/dirdat/
```
-------------------------------------------------------------
[goldengate12.rssing.com](https://goldengate12.rssing.com/chan-8693777/all_p3.html#c8693777a43?zx=813) 

- Problem: \
	INFO: OGG-25221 Processing Tranaction (XID:... Seqno:... RBA:...) larger than eager size (15,100)

- Solution (Increase EAGER_SIZE):
```
-- (When "EAGER_SIZE" is increased, Also increase "STREAMS_POOL_SIZE")
	-- edit Replicat:
	GGSCI> edit params rinta
	DBOPTIONS INTEGRATEDPARAMS(PARALLELISM 8, EAGER_SIZE 10000000)

	SQL> ALTER SYSTEM SET STREAMS_POOL_SIZE=3G scope=both;
```
-------------------------------------------------------------
- Force to stop a replicat:
```
	GGSCI> stop replicat rinta
	ERROR ---> Timeout

	GGSCI> kill replicat rinta
```
-------------------------------------------------------------
- KEYCOLS:
```
GGSCI> edit params rinta
MAP owner.source, owner.target, KEYCOLS(col1, col3, col8);
```
-------------------------------------------------------------
- (Malyat Project):

- 1. PINTA(Data Pump) ABENDED:
```
2021-05-11 14:26:36  ERROR   OGG-01163  Oracle GoldenGate Capture for Oracle, pinta.prm:  Bad column length (21) specified for column CR07_FIN in table REG.TR07_BRANCH_TAX_TYPE_REG, maximum allowable length is 20.
2021-05-11 14:26:36  ERROR   OGG-01668  Oracle GoldenGate Capture for Oracle, pinta.prm:  PROCESS ABENDING.

-- 2. According Document "1540652.1" -> Add Parameter "passthru" to parameter file.
-> OK!
```
-------------------------------------------------------------

========================================================================================
----------------------------------------------------------------------------------------
========================================================================================
