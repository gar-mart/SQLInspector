CREATE PROCEDURE sp_index_frag(
    @database_name     VARCHAR(100),  
    @min_frag          INT,           
    @min_table_size    BIGINT,        
    @print_command     BIT = 0,       
    @execute_command   BIT = 1
)
AS
SET NOCOUNT ON

DECLARE @command NVARCHAR(4000)

DECLARE @fragmentation_details TABLE (
    database_name             VARCHAR(130),
    object_name               VARCHAR(130),
    index_name                VARCHAR(130),
    schema_name               VARCHAR(130),
    avg_fragmentation_percent FLOAT,
    index_type_desc           VARCHAR(50),
    allocation_unit_type      VARCHAR(50),
    has_large_data_type       INT,
    table_size                BIGINT
)

DECLARE @database_check TABLE (
    database_name VARCHAR(100),
    database_id   INT
)

INSERT INTO @database_check
SELECT 
    name, 
    dbid
FROM master.dbo.sysdatabases
WHERE name = CASE WHEN ISNULL(@database_name, '') = '' THEN name ELSE @database_name END
  AND name NOT IN ('master', 'msdb', 'model')
  AND name NOT LIKE '%temp%'
  AND name NOT LIKE '%tmp%'
  AND name NOT LIKE '%train%'
  AND DATABASEPROPERTYEX(name, 'Status') = 'ONLINE'

DECLARE @current_database_name VARCHAR(100)
DECLARE @current_database_id INT
DECLARE @index INT = 1
DECLARE @total_databases INT = (SELECT COUNT(*) FROM @database_check)

WHILE @index <= @total_databases
BEGIN
    WITH cte AS (
        SELECT 
            database_name,
            database_id,
            ROW_NUMBER() OVER (ORDER BY database_name) rn
        FROM @database_check
    )
    SELECT 
        @current_database_name = database_name, 
        @current_database_id = database_id
    FROM cte
    WHERE rn = @index

    SET @command = 'SELECT ''' + @current_database_name + ''' AS database_name,
                           O.name AS object_name,
                           I.name AS index_name,
                           S.name AS schema_name,
                           avg_fragmentation_in_percent,
                           V.index_type_desc AS index_type_desc,
                           alloc_unit_type_desc,
                           ISNULL(SQ.object_id, 1) AS has_large_data_type,
                           SUM(total_pages) AS table_size
                    FROM sys.dm_db_index_physical_stats (' + CAST(DB_ID(@current_database_name) AS VARCHAR(3)) + ', NULL, NULL, NULL, NULL) V
                    INNER JOIN [' + @current_database_name + '].sys.objects O 
                        ON V.object_id = O.object_id
                    INNER JOIN [' + @current_database_name + '].sys.schemas S 
                        ON S.schema_id = O.schema_id
                    INNER JOIN [' + @current_database_name + '].sys.indexes I 
                        ON I.object_id = O.object_id AND V.index_id = I.index_id
                    INNER JOIN [' + @current_database_name + '].sys.partitions P 
                        ON P.object_id = O.object_id
                    INNER JOIN [' + @current_database_name + '].sys.allocation_units A 
                        ON P.partition_id = A.container_id
                    LEFT JOIN (
                        SELECT DISTINCT A.object_id
                        FROM [' + @current_database_name + '].sys.columns A
                        JOIN [' + @current_database_name + '].sys.types B 
                            ON A.user_type_id = B.user_type_id
                        WHERE B.name IN (''type'', ''text'', ''ntext'', ''image'', ''xml'') 
                           OR (B.name IN (''varchar'', ''nvarchar'', ''varbinary'') AND A.max_length = -1)
                    ) SQ 
                        ON SQ.object_id = O.object_id
                    WHERE avg_fragmentation_in_percent >= ' + CAST(@min_frag AS VARCHAR(8)) + '
                      AND I.index_id > 0
                      AND I.is_disabled = 0
                      AND I.is_hypothetical = 0
                    GROUP BY O.name, I.name, S.name, avg_fragmentation_in_percent, 
                             V.index_type_desc, alloc_unit_type_desc, ISNULL(SQ.object_id, 1)
                    HAVING SUM(total_pages) >= ' + CAST(@min_table_size AS VARCHAR(50)) + ''

    IF @print_command = 1
        PRINT @command

    INSERT INTO @fragmentation_details (
        database_name, object_name, index_name, schema_name, 
        avg_fragmentation_percent, index_type_desc, 
        allocation_unit_type, has_large_data_type, table_size
    )
    EXEC(@command)

    SET @index = @index + 1

    SELECT * FROM @fragmentation_details
END
