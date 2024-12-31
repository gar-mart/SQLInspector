CREATE PROCEDURE sp_long_queries
    @days_back INT = 5,                 
    @min_duration_ms BIGINT = 10000,    
    @include_unnamed_objects BIT = 1    
AS
SET NOCOUNT ON

DECLARE @sql NVARCHAR(MAX)
DECLARE @sqlexec NVARCHAR(MAX)

SET @sql = '
DECLARE @t TABLE (
    db NVARCHAR(128),
    query_id INT,
    object_id INT,
    max_duration_ms BIGINT,
    set_options INT,
    name NVARCHAR(128),
    total_duration_ms BIGINT,
    query_sql_text NVARCHAR(MAX),
    execution_type TINYINT
)

;WITH cte AS (
    SELECT
        q.query_id,
        q.object_id,
        rs.max_duration / 1000 max_duration_ms,
        rs.avg_duration * rs.count_executions / 1000 total_duration_ms,
        cs.set_options,
        s.name + ''.'' + o.name name,
        qt.query_sql_text,
        qi.start_time,
        rs.execution_type
    FROM sys.query_store_plan qp
    INNER JOIN sys.query_store_query q
        ON qp.query_id = q.query_id
    INNER JOIN sys.query_store_query_text qt
        ON q.query_text_id = qt.query_text_id
    INNER JOIN sys.query_store_runtime_stats rs
        ON qp.plan_id = rs.plan_id
    INNER JOIN sys.query_store_runtime_stats_interval qi
        ON rs.runtime_stats_interval_id = qi.runtime_stats_interval_id
    LEFT JOIN sys.objects o
        ON q.object_id = o.object_id
    LEFT JOIN sys.schemas s
        ON o.schema_id = s.schema_id
    INNER JOIN sys.query_context_settings cs
        ON q.context_settings_id = cs.context_settings_id
    WHERE qi.start_time >= DATEADD(hour, ' + CAST(@days_back AS NVARCHAR) + ' * (-24), CAST(CAST(GETDATE() AS DATE) AS DATETIME))
        AND (' + CAST(@include_unnamed_objects AS NVARCHAR) + ' = 1 OR o.name IS NOT NULL)
)
INSERT INTO @t (
    db,
    query_id,
    object_id,
    max_duration_ms,
    set_options,
    name,
    total_duration_ms,
    query_sql_text,
    execution_type
)
SELECT
    DB_NAME() db,
    query_id,
    object_id,
    MAX(max_duration_ms) max_duration_ms,
    set_options,
    name,
    MAX(total_duration_ms) total_duration_ms,
    query_sql_text,
    execution_type
FROM cte
GROUP BY
    query_id,
    object_id,
    set_options,
    name,
    query_sql_text,
    execution_type
HAVING MAX(max_duration_ms) > ' + CAST(@min_duration_ms AS NVARCHAR) + '

IF EXISTS (SELECT * FROM @t)
    SELECT
        db database_name,
        execution_type,
        query_id,
        object_id,
        max_duration_ms,
        set_options,
        name,
        total_duration_ms,
        query_sql_text
    FROM @t
    ORDER BY max_duration_ms DESC
'

DECLARE @dbname NVARCHAR(MAX)

DECLARE db_cursor CURSOR FOR
SELECT name FROM sys.databases

OPEN db_cursor

FETCH NEXT FROM db_cursor INTO @dbname

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sqlexec = 'USE ' + QUOTENAME(@dbname) + '; ' + @sql
    EXEC(@sqlexec)

    FETCH NEXT FROM db_cursor INTO @dbname
END

CLOSE db_cursor
DEALLOCATE db_cursor
