-- Save this Silver Layer (ETL) Quality check colde

USE DataWarehousePractice1;

select * from bronze.crm_cust_info;
select * from bronze.crm_prd_info;
select * from bronze.crm_sales_details;
select * from bronze.erp_cust_az12;
select * from bronze.erp_loc_a101;
select * from bronze.erp_px_cat_g1v2;


-- Table #1 -------------------------------------------------------------
-- ===== MAIN QUERY =========================================================================

select
	cst_id,
	trim(cst_key) cst_key,
	trim(cst_firstname) cst_firstname,
	trim(cst_lastname) cst_lastname,
	case
		when cst_marital_status = 'M' then 'Married'
		when cst_marital_status = 'S' then 'Single'
		else 'n/a'
	end cst_marital_status,
	case
		when cst_gndr = 'M' then 'Male'
		when cst_gndr = 'F' then 'Female'
		else 'n/a'
	end cst_gndr2,
	cst_create_date
from
(
	select
		*,
		row_number() over(partition by cst_id order by cst_create_date desc) row_num
	from bronze.crm_cust_info
	where cst_id is not null
)d
where d.row_num = 1 and len(trim(cst_key)) = 10;


-- ===================================================================================
-- ===================================================================================
-- ===================================================================================


-- Table #1 -------------------------------------------------------------
-- Quality Check - Table #1 --------------------------------------
-- Remove duplicates
select
	cst_id,
	trim(cst_key) cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
from
(
	select
		*,
		row_number() over(partition by cst_id order by cst_create_date desc) row_num
	from bronze.crm_cust_info
	where cst_id is not null
)d
where d.row_num = 1;

-- cst_key ------------------

select
	cst_key,
	len(trim(cst_key)) cst_key_len
from bronze.crm_cust_info
order by cst_key_len desc;

-- Marital Status ----------------------------

select distinct 
	cst_marital_status,
	case
		when cst_marital_status = 'M' then 'Married'
		when cst_marital_status = 'S' then 'Single'
		else 'n/a'
	end cst_marital_status2
from bronze.crm_cust_info;

-- Gender ----------------------------

select distinct 
	cst_gndr,
	case
		when cst_gndr = 'M' then 'Male'
		when cst_gndr = 'F' then 'Female'
		else 'n/a'
	end cst_gndr2

from bronze.crm_cust_info;

-- ===================================================================================
-- ===================================================================================
-- ===================================================================================


-- Table #2
-- =============================================================================

select
	prd_id,
	replace(substring(prd_key, 1,5), '-', '_') prd_key, 
	substring(prd_key, 7, len(prd_key)) prd_cat,
	trim(prd_nm) prd_nm,
	ISNULL(prd_cost,0) prd_cost,
	case
		when prd_line = 'M' then 'Mountain'
		when prd_line = 'R' then 'Road'
		when prd_line = 'S' then 'Other Sales'
		when prd_line = 'T' then 'Touring'
		else 'n/a'
	end prd_line,
	prd_start_dtdate as prd_start_dt,
	dateadd(day, -1, lead(prd_start_dtdate) over (partition by prd_nm order by prd_start_dtdate)) prd_end_dt
from bronze.crm_prd_info;

-- ===== Quality Check ===================================================================================

select *
from
(
	select prd_id,
		prd_start_dtdate,
		row_number() over(partition by prd_id order by prd_start_dtdate desc) row_num
	from bronze.crm_prd_info
)d
where d.row_num > 1;

-- === Quality Check #2 ==========================

select
	prd_key,
	replace(substring(prd_key, 1,5), '-', '_') prd_key2, 
	substring(prd_key, 7, len(prd_key)) prd_cat
from bronze.crm_prd_info;

select * from bronze.erp_px_cat_g1v2;

-- === Qualtity check #4 =====================
-- Mountain, Road, Other sales, Touring

select distinct 
	prd_line,
	case
		when prd_line = 'M' then 'Mountain'
		when prd_line = 'R' then 'Road'
		when prd_line = 'S' then 'Other Sales'
		when prd_line = 'T' then 'Touring'
		else 'n/a'
	end prd_line
from bronze.crm_prd_info;

-- === Quality check #5 ==============================

select
	prd_nm,
	prd_start_dtdate,
	dateadd(day, -1, lead(prd_start_dtdate) over (partition by prd_nm order by prd_start_dtdate)) next_date,
	prd_end_dt
from bronze.crm_prd_info
where prd_start_dtdate > prd_end_dt
	or prd_start_dtdate is null;

-- prd_nm = 'Sport-100 Helmet- Red';

-- ===================================================================================
-- ===================================================================================
-- ===================================================================================


-- Table #3
-- ======================================================================

select
	sls_ord_num,
	trim(sls_prd_key) sls_prd_key,
	sls_cust_id,
	case
		when sls_order_dt = 0 OR len(sls_order_dt) != 8 then NULL
		else cast(cast(sls_order_dt as varchar) as date)
	end sls_order_dt,
	case
		when sls_ship_dt = 0 OR len(sls_ship_dt) != 8 then NULL
		else cast(cast(sls_ship_dt as varchar) as date)
	end sls_ship_dt,
	case
		when sls_due_dt = 0 OR len(sls_due_dt) != 8 then NULL
		else cast(cast(sls_due_dt as varchar) as date)
	end sls_due_dt,
	case
		when sls_sales is null OR sls_sales <=0 OR sls_sales != sls_quantity * abs(sls_price)
			then sls_quantity * abs(sls_price)
		else sls_sales
	end sls_sales2,
	sls_quantity,
	case
		when sls_price is null or sls_price <= 0
			then sls_sales / NULLIF(sls_quantity,0)
	end sls_price
from bronze.crm_sales_details;


-- ====== sls_prd_key ====================================

select * from bronze.crm_sales_details;

select
	sls_prd_key,
	len(trim(sls_prd_key)) len_prd_key
from bronze.crm_sales_details
order by len_prd_key asc;

-- === sls_order_dt ========================================

select
	sls_order_dt,
	-- sls_order_dt is 0 or length is not 8
	case
		when sls_order_dt = 0 OR len(sls_order_dt) != 8 then NULL
		else cast(cast(sls_order_dt as varchar) as date)
	end sls_order_dt,
	case
		when sls_ship_dt = 0 OR len(sls_ship_dt) != 8 then NULL
		else cast(cast(sls_ship_dt as varchar) as date)
	end sls_ship_dt,
	case
		when sls_due_dt = 0 OR len(sls_due_dt) != 8 then NULL
		else cast(cast(sls_due_dt as varchar) as date)
	end sls_due_dt
from bronze.crm_sales_details;


-- Quality Check (sls_order_dt) ---------------------------------------
select
	sls_order_dt,
	-- sls_order_dt is 0 or length is not 8
	case
		when sls_order_dt = 0 OR len(sls_order_dt) != 8 then NULL
		else cast(cast(sls_order_dt as varchar) as date)
	end sls_order_dt
from bronze.crm_sales_details
where sls_order_dt = 0 OR len(sls_order_dt) != 8;

-----------------------------------------------------------------------------------
-- Quality Check (sls_sales) ---------------------------------------

select
	sls_sales,
	sls_quantity,
	sls_price
from bronze.crm_sales_details
where -- sls_sales <=0 OR
	sls_sales != sls_quantity * sls_price;


-- Query --------------------------------

select
	sls_sales,
	sls_quantity,
	sls_price,
	case
		when sls_sales is null OR sls_sales <=0 OR sls_sales != sls_quantity * abs(sls_price)
			then sls_quantity * abs(sls_price)
		else sls_sales
	end sls_sales2,
	case
		when sls_price is null or sls_price <= 0
			then sls_sales / NULLIF(sls_quantity,0)
	end sls_price2
from bronze.crm_sales_details
where sls_sales <=0 OR sls_sales != sls_quantity * sls_price;

-- ===================================================================================
-- ===================================================================================
-- ===================================================================================

-- Table #4
-- MAIN QUERY -----------------------------------------

SELECT
	case
		when substring(cid, 1,3) LIKE 'NAS%' then substring(cid,4, len(cid))
		else cid
	end cid,
	case
		when bdate < '1920-01-01' OR bdate > GETDATE() then NULL
		else bdate
	end bdate,
	case
		when gen = 'F' then 'Female'
		when gen = 'M' then 'Male'
		when gen is null or gen = '' then NULL
		else gen
	end gen
from bronze.erp_cust_az12;



--where len(bdate) != 10
--	OR bdate < '1920-01-01'
--	OR bdate > GETDATE();


-- ---- Quality Check --------------------------------------------------------------------

select
	cid,
	case
		when substring(cid, 1,3) LIKE 'NAS%' then substring(cid,4, len(cid))
		else cid
	end cid2,
	len(	case
		when substring(cid, 1,3) LIKE 'NAS%' then substring(cid,4, len(cid))
		else cid
	end) cid_len
from bronze.erp_cust_az12
order by cid_len desc;


select distinct gen,
	case
		when gen = 'F' then 'Female'
		when gen = 'M' then 'Male'
		when gen is null or gen = '' then NULL
		else gen
	end gen2
from bronze.erp_cust_az12;

select * from bronze.crm_cust_info;


-- ===================================================================================
-- ===================================================================================
-- ===================================================================================

-- Table #5
-- MAIN QUERY -----------------------------------------

select
	replace(cid, '-', '') cid,
	case
		when cntry = '' then NULL
		when cntry = 'DE' then 'Germany'
		when cntry IN ('US', 'USA') then 'United States'
		else cntry
	end cntry
from bronze.erp_loc_a101;



-- ----- Quality Check -----------------------------------------------------

select * from bronze.erp_loc_a101;

select * from bronze.crm_cust_info;
 ----------------------------------------------------
select
	cid,
	replace(cid, '-', '') cid2
from bronze.erp_loc_a101;

---------------------------------------------------------------

select distinct
	cntry,
	case
		when cntry = '' then NULL
		when cntry = 'DE' then 'Germany'
		when cntry IN ('US', 'USA') then 'United States'
		else cntry
	end cntry2
from bronze.erp_loc_a101
order by cntry;

-- Table #6 -------------------------------------------------------------

select
	id,
	cat,
	subcat,
	maintenance
from bronze.erp_px_cat_g1v2;



