CREATE PROCEDURE sp_table_sizes(
	@schema SYSNAME = NULL
)
AS
SET NOCOUNT ON
SELECT 
    s.Name AS schema_name,
    t.Name AS table_name,
    MAX(p.rows) AS row_counts,
    SUM(a.total_pages) * 8 AS total_space_kb, 
    SUM(a.used_pages) * 8 AS used_space_kb, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS unused_space_kb
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.Name NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.object_id > 255 
    AND (s.Name = @schema OR @schema IS NULL)
GROUP BY t.Name, s.Name
ORDER BY row_counts DESC
