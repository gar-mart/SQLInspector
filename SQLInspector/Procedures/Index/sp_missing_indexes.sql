CREATE PROCEDURE sp_missing_indexes(
    @database_name NVARCHAR(100),
    @is_current BIT
)
AS
SET NOCOUNT ON
SELECT 
    migs.group_handle,
    migs.user_seeks * migs.avg_total_user_cost * ( migs.avg_user_impact * 0.01 ) AS index_advantage,
    migs.avg_total_user_cost,
    migs.avg_user_impact,
    migs.user_seeks,
    migs.user_scans,
    DB_NAME(mid.database_id) AS database_name,
    OBJECT_NAME(mid.object_id, mid.database_id) AS table_name,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_group_stats migs
INNER JOIN sys.dm_db_missing_index_groups mig
    ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid
    ON mig.index_handle = mid.index_handle
WHERE 
    (
        @database_name IS NULL 
        AND (@is_current = 0 OR @is_current IS NULL) -- Include all databases
    )
    OR 
    (
        @is_current = 1 
        AND mid.database_id = DB_ID() -- Just the current database
    )
    OR 
    (
        DB_NAME(mid.database_id) = @database_name -- Given database name
    )
ORDER BY migs.avg_user_impact DESC
