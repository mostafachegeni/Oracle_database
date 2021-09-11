# Create Mat View
[docs.oracle.com](https://docs.oracle.com/database/121/DWHSG/basicmv.htm#GUID-1F42F25D-739B-4FEE-BEBC-212869D5CD10__i1006694) \
[oracle-base.com](https://oracle-base.com/articles/misc/materialized-views) \
[docs.oracle.com](https://docs.oracle.com/database/121/DWHSG/basicmv.htm#DWHSG-GUID-A7AE8E5D-68A5-4519-81EB-252EAAF0ADFF)


-------------------------------------------------------------------------------------------------------
- "BUILD clause": 
	>	IMMEDIATE : The materialized view is populated immediately. \
	>	DEFERRED : The materialized view is populated on the first requested refresh.

- "Refresh Types": 
	>	FAST : A fast refresh is attempted. If materialized view logs are not present against the source tables in advance, the creation fails. \
	>	COMPLETE : The table segment supporting the materialized view is truncated and repopulated completely using the associated query. \
	>	FORCE : A fast refresh is attempted. If one is not possible a complete refresh is performed. 

- "Refresh can be triggered" in two ways: 
	>	ON COMMIT : The refresh is triggered by a committed data change in one of the dependent tables. \
	>	ON DEMAND : The refresh is initiated by a manual request or a scheduled task. 

-------------------------------------------------------------------------------------------------------
- **Normal MatView**:
```
CREATE MATERIALIZED VIEW view-name
BUILD [IMMEDIATE | DEFERRED]
REFRESH [FAST | COMPLETE | FORCE ]
ON [COMMIT | DEMAND ]
[[ENABLE | DISABLE] QUERY REWRITE]
AS
SELECT ...;
```

- **Pre-Built MatView**:
```
CREATE MATERIALIZED VIEW view-name
ON PREBUILT TABLE
REFRESH [FAST | COMPLETE | FORCE ]
ON [COMMIT | DEMAND ]
[[ENABLE | DISABLE] QUERY REWRITE]
AS
SELECT ...;
```

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
- List of all MatViews:
```
select * from dba_mviews;

```
- List of all MatView Logs:
```
SQL> select * from dba_mview_logs;
```


-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
- Materialized View Containing Only "Joins":

1.
```
SQL> conn scott/tiger
```
2. Create MatView Logs:
```
--SQL> DROP MATERIALIZED VIEW LOG ON scott.emp;
--SQL> CREATE MATERIALIZED VIEW LOG ON scott.emp TABLESPACE users WITH PRIMARY KEY INCLUDING NEW VALUES;
SQL> CREATE MATERIALIZED VIEW LOG ON scott.sales WITH ROWID;
SQL> CREATE MATERIALIZED VIEW LOG ON scott.times WITH ROWID;
SQL> CREATE MATERIALIZED VIEW LOG ON scott.customers WITH ROWID;

```
3. Grant Access to MatView Logs:
```
SQL> select * from dba_mview_logs;

SQL> grant select on scott.MLOG$_SALES 		to inquiry;
SQL> grant select on scott.MLOG$_TIMES      to inquiry;
SQL> grant select on scott.MLOG$_CUSTOMERS  to inquiry;
```

4. Create MatView:
```
SQL> CREATE MATERIALIZED VIEW mosch.detail_sales_mv 
		PARALLEL 
		BUILD IMMEDIATE
		REFRESH FAST 
		--enable query rewrite 
	AS
	SELECT s.rowid "sales_rid", t.rowid "times_rid", c.rowid "customers_rid",
		   c.cust_id, c.cust_last_name, s.amount_sold, s.quantity_sold, s.time_id
	FROM scott.sales s, scott.times t, scott.customers c 
	WHERE  s.cust_id = c.cust_id(+) AND s.time_id = t.time_id(+);

```

5. Create a JOB to Fast Refresh:
```
BEGIN 
    dbms_mview.refresh(list=>'mosch.detail_sales_mv',method=>'f');
END;
```


-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
- Materialized Views with "Aggregates": 
	>	Creating a Materialized View (Total Number and Value of Sales) 


1.
```
SQL> CREATE MATERIALIZED VIEW LOG ON products WITH SEQUENCE, ROWID
		(prod_id, prod_name, prod_desc, prod_subcategory, prod_subcategory_desc, 
		prod_category, prod_category_desc, prod_weight_class, prod_unit_of_measure,
		prod_pack_size, supplier_id, prod_status, prod_list_price, prod_min_price)
		INCLUDING NEW VALUES;

SQL> CREATE MATERIALIZED VIEW LOG ON sales
		WITH SEQUENCE, ROWID
		(prod_id, cust_id, time_id, channel_id, promo_id, quantity_sold, amount_sold)
		INCLUDING NEW VALUES;
```

2.
```
SQL> CREATE MATERIALIZED VIEW product_sales_mv
		PCTFREE 0  TABLESPACE demo
		STORAGE (INITIAL 8M)
		BUILD IMMEDIATE
		REFRESH FAST
		ENABLE QUERY REWRITE
	AS 
	SELECT p.prod_name, SUM(s.amount_sold) AS dollar_sales,
		COUNT(*) AS cnt, COUNT(s.amount_sold) AS cnt_amt
	FROM sales s, products p
	WHERE s.prod_id = p.prod_id GROUP BY p.prod_name;

```


-------------------------------------------------------------------------------------------------------
