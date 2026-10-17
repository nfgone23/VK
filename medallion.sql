-- ==========================================
-- 1. BRONZE LAYER (—ырые данные, сжатие SNAPPY)
-- ==========================================
CREATE TABLE bronze.bronze_part
WITH (format = 'PARQUET', compression_codec = 'SNAPPY')
AS SELECT * FROM tpch.sf1.part;

CREATE TABLE bronze.bronze_partsupp
WITH (format = 'PARQUET', compression_codec = 'SNAPPY')
AS SELECT * FROM tpch.sf1.partsupp;

CREATE TABLE bronze.bronze_supplier
WITH (format = 'PARQUET', compression_codec = 'SNAPPY')
AS SELECT * FROM tpch.sf1.supplier;

-- ==========================================
-- 2. SILVER LAYER (ќчистка и обогащение)
-- ==========================================

-- ”бираем поставщиков с жалобами
CREATE TABLE silver.dim_suppliers
WITH (format = 'PARQUET', compression_codec = 'SNAPPY')
AS SELECT suppkey
FROM bronze.bronze_supplier
WHERE comment NOT LIKE '%Customer%Complaints%';

-- —оедин€ем детали и поставки, сразу фильтру€ по чистым поставщикам
CREATE TABLE silver.fact_parts
WITH (format = 'PARQUET', compression_codec = 'SNAPPY')
AS SELECT
  p.partkey,
  p.brand,
  p.type,
  p.size,
  ps.suppkey
FROM bronze.bronze_partsupp AS ps
JOIN bronze.bronze_part AS p ON p.partkey = ps.partkey
JOIN silver.dim_suppliers AS s ON ps.suppkey = s.suppkey;

-- ==========================================
-- 3. GOLD LAYER (¬итрина дл€ BI)
-- ==========================================
CREATE TABLE gold.gold_supplier_counts
WITH (format = 'PARQUET', compression_codec = 'SNAPPY')
AS SELECT
  brand,
  type,
  size,
  count(DISTINCT suppkey) AS supplier_cnt
FROM silver.fact_parts
WHERE brand <> 'Brand#45'
  AND type NOT LIKE 'MEDIUM POLISHED%'
  AND size IN (49, 14, 23, 45, 19, 3, 36, 9)
GROUP BY brand, type, size
ORDER BY supplier_cnt DESC, brand, type, size;