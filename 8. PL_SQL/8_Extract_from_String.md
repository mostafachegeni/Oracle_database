# Extract from String
```
SQL> SELECT REGEXP_SUBSTR( 'skncjb sknd 4 GB sckjh',  '\d+ (GB|TB)' ) max_ram FROM dual;
SQL> SELECT REGEXP_SUBSTR( 'skncjb sknd PARALLEL 10 sckjh',  '(PARALLEL|parallel)+ (\d)(\d)' ) max_ram FROM dual;
```
