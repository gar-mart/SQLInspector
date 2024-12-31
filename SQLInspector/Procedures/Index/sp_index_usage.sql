CREATE PROCEDURE sp_index_usage(
    @database_name NVARCHAR(100) NULL
)
AS
SET NOCOUNT ON
SELECT 
    OBJECT_NAME(ius.object_id) AS table_name,
    i.name AS index_name,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    DB_NAME(ius.database_id) AS database_name,
    i.index_id,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    ius.last_user_seek,
    ius.last_user_scan,
    ius.last_user_lookup,
    ius.last_user_update
FROM sys.dm_db_index_usage_stats AS ius
INNER JOIN sys.indexes AS i
    ON ius.object_id = i.object_id AND ius.index_id = i.index_id
WHERE ius.database_id != DB_ID(@database_name) OR @database_name IS NULL
ORDER BY ius.user_seeks DESC
