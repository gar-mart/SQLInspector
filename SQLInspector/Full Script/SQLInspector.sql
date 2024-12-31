USE [master]

DROP TABLE IF EXISTS dbo.sqlins_procs_desc
GO

DROP TABLE IF EXISTS dbo.sqlins_procs_param
GO

DROP TABLE IF EXISTS dbo.sqlins_procs_output
GO

CREATE TABLE dbo.sqlins_procs_desc(
	name VARCHAR(50),
	description NVARCHAR(2000)

	CONSTRAINT PK_sqlins_desc PRIMARY KEY (name)
)

GO

CREATE TABLE dbo.sqlins_procs_param(
	proc_name VARCHAR(50),
	parameter VARCHAR(50),
	parameter_type VARCHAR(50),
	description VARCHAR(500)

	CONSTRAINT PK_sqlins_procs_param PRIMARY KEY (proc_name, parameter)
)

GO

CREATE TABLE dbo.sqlins_procs_output(
	proc_name VARCHAR(50),
	output_index TINYINT CONSTRAINT DF_sqlins_procs_output_output_index DEFAULT (1),
	[column] VARCHAR(50),
	description VARCHAR(500)

	CONSTRAINT PK_sqlins_procs_output PRIMARY KEY (proc_name, output_index, [column])
)

GO

INSERT INTO dbo.sqlins_procs_desc (name, description)
VALUES 
('sp_backup_info', 'Retrieves and displays detailed backup information for each database on the SQL Server instance.'),
('sp_table_sizes', 'Displays detailed information about table sizes in the database.'),
('sp_active_tran', 'Provides details about active transactions within the SQL Server instance, offering insights into transaction metadata, associated sessions, and their recent execution plans.'),
('sp_current_locks', 'Provides information about the current locks held by sessions on various database resources.'),
('sp_index_usage', 'Retrieves index usage statistics, showing which indexes are frequently used, as opposed to unused or rarely used ones.'),
('sp_missing_indexes', 'Returns costly missing indexes in a given database or all databases. Missing indexes are ranked by their potential performance benefit, calculated based on the user impact and query cost.'),
('sp_index_frag', 'Provides insights into index fragmentation across one or more databases. Highlights indexes with fragmentation above the specified threshold.'),
('sp_long_queries', 'Identifies long-running queries across all databases in a SQL Server instance using Query Store data.'),
('sp_long_proc_xe', 'Retrieves details of long-running stored procedure calls or queries captured by Extended Events. Provides insights into query performance by filtering based on duration, database name, client hostname, or SQL statement patterns.'),
('sp_job_info', 'Retrieves detailed information about SQL Server Agent jobs. Identifies jobs that failed based on historical data. Drills down into specific job steps to troubleshoot issues.'),
('sp_long_jobs', 'Detects long-running SQL Server Agent jobs by comparing current execution duration against thresholds derived from historical averages or default limits. Sends email notifications for detected jobs if specified.');

GO

INSERT INTO dbo.sqlins_procs_param (proc_name, parameter, parameter_type, description)
VALUES
('sp_table_sizes', '@schema', 'SYSNAME', 'Specifies the schema for filtering the tables. If NULL, returns results for all schemas.'),

('sp_index_usage', '@database_name', 'NVARCHAR(100)', 'The name of the database to display index usage information for. If NULL, retrieves indexes for all databases.'),

('sp_missing_indexes', '@database_name', 'NVARCHAR(100)', 'Specifies the name of a database to analyze. If NULL, returns missing indexes for all databases.'),
('sp_missing_indexes', '@is_current', 'BIT', 'If set to 1, returns missing indexes for the current database only.'),

('sp_index_frag', '@database_name', 'VARCHAR(100)', 'The name of the database to analyze. If NULL, analyzes all eligible databases.'),
('sp_index_frag', '@min_frag', 'INT', 'The minimum fragmentation percentage for filtering indexes.'),
('sp_index_frag', '@min_table_size', 'BIGINT', 'The minimum table size (in pages) to filter the results.'),
('sp_index_frag', '@print_command', 'BIT', 'If set to 1, prints the dynamic SQL commands for debugging purposes. Default: 0.'),
('sp_index_frag', '@execute_command', 'BIT', 'If set to 1, executes the generated SQL commands to analyze fragmentation. Default: 1.'),

('sp_long_queries', '@days_back', 'INT', 'Filters queries executed within the specified number of days back from the current date. Default: 5.'),
('sp_long_queries', '@min_duration_ms', 'BIGINT', 'Filters queries with a maximum execution duration (in milliseconds) greater than this value. Default: 10,000.'),
('sp_long_queries', '@include_unnamed_objects', 'BIT', 'If set to 1, includes queries from unnamed objects (e.g., ad hoc queries). If 0, excludes unnamed objects. Default: 1.'),

('sp_long_proc_xe', '@xe_session', 'NVARCHAR(128)', 'The name of the Extended Events session to retrieve data from. Default: "Proc_Calls".'),
('sp_long_proc_xe', '@database_name', 'NVARCHAR(128)', 'Filters results to include only events from a specific database. Default: NULL (no filtering).'),
('sp_long_proc_xe', '@duration', 'BIGINT', 'Filters results to include only events with a duration greater than this value (in microseconds). Default: NULL (no filtering).'),
('sp_long_proc_xe', '@hostname', 'NVARCHAR(128)', 'Filters results to include only events generated by a specific client host. Default: NULL (no filtering).'),
('sp_long_proc_xe', '@statement', 'NVARCHAR(MAX)', 'Filters results to include only events containing a specific SQL statement or pattern. Default: NULL (no filtering).'),

('sp_job_info', '@start_date', 'DATE', 'Filters jobs by execution start date. If NULL, no filter is applied.'),
('sp_job_info', '@job_owner', 'NVARCHAR(128)', 'Filters jobs by the owner’s name. If NULL, no filter is applied.'),
('sp_job_info', '@run_status', 'INT', 'Filters jobs by their execution status. Example values: 0 (Failed), 1 (Succeeded). If NULL, no filter is applied.'),
('sp_job_info', '@step_name', 'NVARCHAR(128)', 'Filters jobs by the name of a specific step. If NULL, no filter is applied.'),

('sp_long_jobs', '@deviation_times', 'INT', 'Multiplier for historical average duration to define a threshold. Default: 3.'),
('sp_long_jobs', '@default_max_duration_minutes', 'INT', 'Fallback duration threshold (in minutes). Default: 15.'),
('sp_long_jobs', '@from_address', 'NVARCHAR(128)', 'Email address used for sending notifications. Optional.'),
('sp_long_jobs', '@recipients', 'NVARCHAR(128)', 'Email addresses of recipients (comma-separated). Optional.')

GO

-- sp_backup_info
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_backup_info', 1, 'database_id', 'The unique identifier for each database in the SQL Server instance.'),
('sp_backup_info', 1, 'name', 'The name of the database.'),
('sp_backup_info', 1, 'state_desc', 'The current state of the database (e.g., ONLINE, OFFLINE, RECOVERING).'),
('sp_backup_info', 1, 'recovery_model_desc', 'The recovery model of the database (e.g., FULL, SIMPLE, BULK_LOGGED).'),
('sp_backup_info', 1, 'data_size', 'The total size of all data files in the database, measured in megabytes (MB).'),
('sp_backup_info', 1, 'log_size', 'The total size of all log files in the database, measured in megabytes (MB).'),
('sp_backup_info', 1, 'full_last_date', 'The date and time of the last full backup for the database.'),
('sp_backup_info', 1, 'full_size', 'The size of the last full backup for the database, measured in bytes.'),
('sp_backup_info', 1, 'log_last_date', 'The date and time of the last transaction log backup for the database.'),
('sp_backup_info', 1, 'last_log_backup_size', 'The size of the last transaction log backup for the database, measured in bytes.');

GO

-- sp_table_sizes
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_table_sizes', 1, 'schema_name', 'The name of the schema containing the table.'),
('sp_table_sizes', 1, 'table_name', 'The name of the table.'),
('sp_table_sizes', 1, 'row_counts', 'The number of rows in the table.'),
('sp_table_sizes', 1, 'total_space_kb', 'The total allocated space for the table, in kilobytes.'),
('sp_table_sizes', 1, 'used_space_kb', 'The space actively used by the table, in kilobytes.'),
('sp_table_sizes', 1, 'unused_space_kb', 'The allocated but unused space for the table, in kilobytes.');

GO

-- sp_active_tran
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_active_tran', 1, 'session_id', 'The ID of the session associated with the transaction.'),
('sp_active_tran', 1, 'login_name', 'The login name of the user initiating the session.'),
('sp_active_tran', 1, 'database_name', 'The name of the database involved in the transaction.'),
('sp_active_tran', 1, 'begin_time', 'The timestamp when the database transaction began.'),
('sp_active_tran', 1, 'log_bytes', 'The number of log bytes used by the database transaction.'),
('sp_active_tran', 1, 'log_bytes_reserved', 'The number of log bytes reserved for the transaction.'),
('sp_active_tran', 1, 'sql_text', 'The SQL statement most recently executed in the session.'),
('sp_active_tran', 1, 'last_plan', 'The execution plan associated with the most recent SQL query in the session.');

GO

-- sp_current_locks
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_current_locks', 1, 'session_id', 'The ID of the session holding or requesting the lock.'),
('sp_current_locks', 1, 'database_name', 'The name of the database where the lock is held.'),
('sp_current_locks', 1, 'resource_associated_entity_id', 'The ID of the resource associated with the lock (e.g., object, partition).'),
('sp_current_locks', 1, 'entity_name', 'The name of the resource associated with the lock (e.g., table or index).'),
('sp_current_locks', 1, 'index_id', 'The ID of the index associated with the lock, if applicable.'),
('sp_current_locks', 1, 'resource', 'The type of resource being locked (e.g., OBJECT, KEY, PAGE, EXTENT).'),
('sp_current_locks', 1, 'description', 'Additional details about the locked resource (e.g., page ranges, key details).'),
('sp_current_locks', 1, 'mode', 'The lock mode (e.g., SHARED, EXCLUSIVE), which indicates the type of operation requiring the lock.'),
('sp_current_locks', 1, 'status', 'The status of the lock request (e.g., GRANTED, WAITING).');

GO

-- sp_index_usage
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_index_usage', 1, 'table_name', 'The name of the table where the index resides.'),
('sp_index_usage', 1, 'index_name', 'The name of the index being analyzed.'),
('sp_index_usage', 1, 'user_seeks', 'Number of seek operations performed on the index.'),
('sp_index_usage', 1, 'user_scans', 'Number of scan operations performed on the index.'),
('sp_index_usage', 1, 'user_lookups', 'Number of lookup operations performed on the index.'),
('sp_index_usage', 1, 'user_updates', 'Number of updates to the index.'),
('sp_index_usage', 1, 'database_name', 'The name of the database where the index resides.'),
('sp_index_usage', 1, 'last_user_seek', 'Timestamp of the last seek operation.'),
('sp_index_usage', 1, 'last_user_scan', 'Timestamp of the last scan operation.'),
('sp_index_usage', 1, 'last_user_lookup', 'Timestamp of the last lookup operation.'),
('sp_index_usage', 1, 'last_user_update', 'Timestamp of the last update operation.');

GO

-- sp_missing_indexes
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_missing_indexes', 1, 'group_handle', 'The unique identifier for the missing index group.'),
('sp_missing_indexes', 1, 'index_advantage', 'A calculated metric that estimates the advantage of creating the missing index.'),
('sp_missing_indexes', 1, 'avg_total_user_cost', 'The average cost of queries that would benefit from the missing index.'),
('sp_missing_indexes', 1, 'avg_user_impact', 'The estimated percentage improvement in query performance if the missing index is created.'),
('sp_missing_indexes', 1, 'user_seeks', 'The number of times queries attempted to use an index for seek operations but found it missing.'),
('sp_missing_indexes', 1, 'user_scans', 'The number of times queries attempted to use an index for scan operations but found it missing.'),
('sp_missing_indexes', 1, 'database_name', 'The name of the database where the missing index was identified.'),
('sp_missing_indexes', 1, 'table_name', 'The name of the table where the missing index is suggested.'),
('sp_missing_indexes', 1, 'equality_columns', 'The columns used in equality comparisons in the queries benefiting from the index.'),
('sp_missing_indexes', 1, 'inequality_columns', 'The columns used in inequality comparisons in the queries benefiting from the index.'),
('sp_missing_indexes', 1, 'included_columns', 'The columns that should be included in the index to cover queries effectively.');

GO

-- sp_index_frag
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_index_frag', 1, 'database_name', 'The name of the database containing the index.'),
('sp_index_frag', 1, 'object_name', 'The name of the table or view containing the index.'),
('sp_index_frag', 1, 'index_name', 'The name of the index being analyzed.'),
('sp_index_frag', 1, 'schema_name', 'The schema of the table or view containing the index.'),
('sp_index_frag', 1, 'avg_fragmentation_percent', 'The average fragmentation percentage of the index.'),
('sp_index_frag', 1, 'index_type_desc', 'The type of index (e.g., CLUSTERED, NONCLUSTERED).'),
('sp_index_frag', 1, 'allocation_unit_type', 'The type of allocation unit (e.g., IN_ROW_DATA, LOB_DATA).'),
('sp_index_frag', 1, 'has_large_data_type', 'Indicates whether the table contains large data types (e.g., LOB, XML, or MAX types).'),
('sp_index_frag', 1, 'table_size', 'The size of the table in pages.');

GO

-- sp_long_queries
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_long_queries', 1, 'database_name', 'The name of the database where the query was executed.'),
('sp_long_queries', 1, 'execution_type', 'The type of execution (e.g., stored procedure, ad hoc query).'),
('sp_long_queries', 1, 'query_id', 'The unique identifier for the query within the Query Store.'),
('sp_long_queries', 1, 'object_id', 'The object ID of the query (e.g., stored procedure ID).'),
('sp_long_queries', 1, 'max_duration_ms', 'The maximum duration (in milliseconds) of the query execution.'),
('sp_long_queries', 1, 'set_options', 'The SET options in effect when the query was executed.'),
('sp_long_queries', 1, 'name', 'The name of the object containing the query (e.g., stored procedure name).'),
('sp_long_queries', 1, 'total_duration_ms', 'The total execution time (in milliseconds) across all executions of the query.'),
('sp_long_queries', 1, 'query_sql_text', 'The SQL text of the query.');

GO

-- sp_long_proc_xe
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_long_proc_xe', 1, 'timestamp', 'The time the query was executed.'),
('sp_long_proc_xe', 1, 'database_name', 'The name of the database where the query was executed.'),
('sp_long_proc_xe', 1, 'duration', 'The duration of the query in microseconds.'),
('sp_long_proc_xe', 1, 'statement', 'The SQL statement executed.'),
('sp_long_proc_xe', 1, 'hostname', 'The client machine that executed the query.');

GO

-- sp_job_info: Output 1 - Jobs Sorted by Execution Start Time
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_job_info', 1, 'job_name', 'The name of the SQL Server Agent job.'),
('sp_job_info', 1, 'description', 'A description of the job.'),
('sp_job_info', 1, 'start_execution_date', 'The date and time the job started execution.');

GO

-- sp_job_info: Output 2 - Jobs with Their Owners
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_job_info', 2, 'job_name', 'The name of the SQL Server Agent job.'),
('sp_job_info', 2, 'job_owner', 'The name of the user who owns the job.');

GO

-- sp_job_info: Output 3 - Failed Agent Jobs
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_job_info', 3, 'job_name', 'The name of the SQL Server Agent job.'),
('sp_job_info', 3, 'step_name', 'The name of the specific step in the job.'),
('sp_job_info', 3, 'sql_severity', 'The severity level of the SQL error, if any.'),
('sp_job_info', 3, 'message', 'The error message associated with the job or step failure.'),
('sp_job_info', 3, 'run_date', 'The date the job was run.'),
('sp_job_info', 3, 'run_time', 'The time the job was run.');

GO

-- sp_job_info: Output 4 - Jobs with Specific Step Name
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_job_info', 4, 'job_name', 'The name of the SQL Server Agent job.'),
('sp_job_info', 4, 'step_name', 'The name of the specific step in the job.'),
('sp_job_info', 4, 'sql_severity', 'The severity level of the SQL error, if any.'),
('sp_job_info', 4, 'message', 'The error message associated with the job or step.'),
('sp_job_info', 4, 'run_date', 'The date the job was run.'),
('sp_job_info', 4, 'run_time', 'The time the job was run.');

GO

-- sp_long_jobs: Output 1 - Currently Running Jobs
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_long_jobs', 1, 'job_id', 'Unique identifier for the job.'),
('sp_long_jobs', 1, 'job_state', 'State of the job (e.g., running).');

GO

-- sp_long_jobs: Output 2 - Detected Long Running Jobs
INSERT INTO dbo.sqlins_procs_output (proc_name, output_index, [column], description)
VALUES
('sp_long_jobs', 2, 'job_name', 'The name of the SQL Server Agent job.'),
('sp_long_jobs', 2, 'execution_date', 'The start date and time of the job execution.'),
('sp_long_jobs', 2, 'avg_duration', 'Historical average execution duration (in seconds).'),
('sp_long_jobs', 2, 'max_duration', 'Threshold duration (in seconds) for detecting long-running jobs.'),
('sp_long_jobs', 2, 'current_duration', 'Current execution duration (in seconds).');

GO

CREATE OR ALTER PROCEDURE sp_sqlins_help (
	@proc_name VARCHAR(50) = NULL
)
AS
SET NOCOUNT ON

IF @proc_name IS NULL
BEGIN
	SELECT name [Procedure], description Description 
	FROM sqlins_procs_desc 
END

ELSE
BEGIN
	SELECT name [Procedure], description Description 
	FROM sqlins_procs_desc 
	WHERE name = @proc_name
	
	SELECT parameter Parameter,
		   parameter_type Type,
		   description Description
	FROM sqlins_procs_param WHERE proc_name = @proc_name
	
	DECLARE @max_output INT 
	
	SET @max_output = (
		SELECT DISTINCT COUNT(DISTINCT output_index)
		FROM sqlins_procs_output
		WHERE proc_name = @proc_name
	)
	
	IF @max_output > 1 
	BEGIN
		DECLARE @i INT = 1
		
		WHILE (@i <= @max_output)
		BEGIN
			SELECT output_index [Output Index],
				   [column] [Output Column],
				   description Description
			FROM sqlins_procs_output  A
			WHERE proc_name = @proc_name
				  AND output_index = @i
		
			SET @i += 1
		END
	END
	
	ELSE 
	BEGIN
		SELECT [column] [Output Column], description Description 
		FROM sqlins_procs_output 
		WHERE proc_name = @proc_name
	END
END

GO

CREATE OR ALTER PROCEDURE sp_backup_info 
AS SET NOCOUNT ON
SELECT
      d.database_id,
      d.name,
      d.state_desc,
      d.recovery_model_desc,
      data_size = CAST(SUM(CASE WHEN mf.[type] = 0 THEN mf.size END) * 8. / 1024 AS DECIMAL(18,2)), -- Data file size in MB
      log_size = CAST(SUM(CASE WHEN mf.[type] = 1 THEN mf.size END) * 8. / 1024 AS DECIMAL(18,2)), -- Log file size in MB
      bu.full_last_date,
      bu.full_size,
      bu.log_last_date,
      bu.log_size last_log_backup_size 
FROM sys.databases d
JOIN sys.master_files mf ON d.database_id = mf.database_id
LEFT JOIN (
    SELECT
          database_name,
          full_last_date = MAX(CASE WHEN [type] = 'D' THEN backup_finish_date END),
          full_size = MAX(CASE WHEN [type] = 'D' THEN backup_size END),
          log_last_date = MAX(CASE WHEN [type] = 'L' THEN backup_finish_date END),
          log_size = MAX(CASE WHEN [type] = 'L' THEN backup_size END)
    FROM msdb.dbo.backupset
    WHERE [type] IN ('D', 'L')
    GROUP BY database_name
) bu ON d.name = bu.database_name
GROUP BY
    d.database_id, d.name, d.state_desc, d.recovery_model_desc, bu.full_last_date, bu.full_size, bu.log_last_date, bu.log_size
ORDER BY data_size DESC

GO

CREATE OR ALTER PROCEDURE sp_table_sizes(
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

GO

CREATE OR ALTER PROCEDURE sp_current_locks
AS SET NOCOUNT ON
SELECT 
    request_session_id AS session_id, 
    DB_NAME(resource_database_id) AS database_name,
    resource_associated_entity_id, 
    CASE WHEN resource_type = 'OBJECT' 
         THEN OBJECT_NAME(resource_associated_entity_id) 
         WHEN resource_associated_entity_id = 0 THEN 'N/A' 
         ELSE OBJECT_NAME(p.object_id) 
    END AS entity_name, 
    index_id, 
    resource_type AS resource, 
    resource_description AS description, 
    request_mode AS mode, 
    request_status AS status 
FROM sys.dm_tran_locks t 
LEFT JOIN sys.partitions p ON p.partition_id = t.resource_associated_entity_id 
WHERE resource_database_id = DB_ID() AND resource_type != 'DATABASE'

GO

CREATE OR ALTER PROCEDURE sp_active_tran
AS 
SET NOCOUNT ON
SELECT
    st.session_id,
    es.login_name,
    DB_NAME(dt.database_id) AS database_name, 
    dt.database_transaction_begin_time AS begin_time,
    dt.database_transaction_log_bytes_used AS log_bytes,
    dt.database_transaction_log_bytes_reserved AS log_bytes_reserved,
    est.text AS sql_text,
    qp.query_plan AS last_plan
FROM sys.dm_tran_database_transactions dt
INNER JOIN sys.dm_tran_session_transactions st
ON st.transaction_id = dt.transaction_id
INNER JOIN sys.dm_exec_sessions es
ON es.session_id = st.session_id
INNER JOIN sys.dm_exec_connections ec
ON ec.session_id = st.session_id
LEFT OUTER JOIN sys.dm_exec_requests er
ON er.session_id = st.session_id
CROSS APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) AS est
OUTER APPLY sys.dm_exec_query_plan(er.plan_handle) AS qp
ORDER BY begin_time

GO

CREATE OR ALTER PROCEDURE sp_index_usage(
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

GO

CREATE OR ALTER PROCEDURE sp_missing_indexes(
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

GO

CREATE OR ALTER PROCEDURE sp_index_frag(
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

GO

CREATE OR ALTER PROCEDURE sp_long_queries
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

GO

CREATE OR ALTER PROCEDURE sp_long_proc_xe
    @xe_session NVARCHAR(128) = 'Proc_Calls',
    @database_name NVARCHAR(128) = NULL,             
    @duration BIGINT = NULL,         
    @hostname NVARCHAR(128) = NULL,           
    @statement NVARCHAR(MAX) = NULL     
AS
SET NOCOUNT ON

DECLARE @target XML

IF CHARINDEX('Microsoft SQL Azure', @@VERSION, 1) > 0 
BEGIN
    SELECT @target = CAST(t.target_data AS XML)
    FROM sys.dm_xe_database_sessions s
    JOIN sys.dm_xe_database_session_targets t ON t.event_session_address = s.address
    WHERE s.name = @xe_session AND t.target_name = N'ring_buffer'
END
ELSE 
BEGIN
    SELECT @target = CAST(t.target_data AS XML)
    FROM sys.dm_xe_sessions s
    JOIN sys.dm_xe_session_targets t ON t.event_session_address = s.address
    WHERE s.name = @xe_session AND t.target_name = N'ring_buffer'
END

IF @target IS NULL
BEGIN
    RAISERROR ('The specified extended events session or ring_buffer target ''%s'' was not found.', 16, 1, @xe_session)
    RETURN
END


;WITH CTE AS (
    SELECT
        DATEADD(HH, DATEDIFF(HH, GETUTCDATE(), GETDATE()), n.value('(@timestamp)[1]', 'datetime2')) AS [timestamp],
        n.value('(action[@name="database_name"]/value)[1]', 'nvarchar(max)') AS database_name,
        n.value('(data[@name="duration"]/value)[1]', 'bigint') AS duration,
        n.value('(data[@name="statement"]/value)[1]', 'nvarchar(max)') AS statement,
        n.value('(action[@name="client_hostname"]/value)[1]', 'nvarchar(max)') AS hostname
    FROM @target.nodes('RingBufferTarget/event[@name="rpc_completed"]') q(n)
)
SELECT *
FROM CTE
WHERE 
    (@database_name IS NULL OR database_name = @database_name)
    AND (@duration IS NULL OR duration > @duration)
    AND (@hostname IS NULL OR hostname = @hostname)
    AND (@statement IS NULL OR statement LIKE '%' + @statement + '%')
ORDER BY duration DESC

GO

CREATE OR ALTER PROCEDURE sp_job_info
    @start_date  DATE = NULL,
    @job_owner NVARCHAR(128) = NULL,
    @run_status INT = NULL,
    @step_name NVARCHAR(128) = NULL
AS 
SET NOCOUNT ON

-- Jobs sorted by execution start time
SELECT j.name AS job_name, j.description, ja.start_execution_date
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobactivity ja ON j.job_id = ja.job_id
WHERE (@start_date  IS NULL OR ja.start_execution_date > @start_date )
AND j.enabled = 1
ORDER BY ja.start_execution_date

-- Jobs with their owners
SELECT a.name AS job_name, b.name AS job_owner
FROM msdb.dbo.sysjobs_view a
LEFT JOIN master.dbo.syslogins b ON a.owner_sid = b.sid
WHERE (@job_owner IS NULL OR b.name = @job_owner)

-- Failed agent jobs
SELECT j.name AS job_name, js.step_name, jh.sql_severity, jh.message, jh.run_date, jh.run_time
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobsteps AS js ON js.job_id = j.job_id
INNER JOIN msdb.dbo.sysjobhistory AS jh ON jh.job_id = j.job_id 
WHERE (@run_status IS NULL OR jh.run_status = @run_status)

-- Jobs with specific step name
SELECT j.name AS job_name, js.step_name, jh.sql_severity, jh.message, jh.run_date, jh.run_time
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobsteps AS js ON js.job_id = j.job_id
INNER JOIN msdb.dbo.sysjobhistory AS jh ON jh.job_id = j.job_id 
WHERE (@step_name IS NULL OR js.step_name = @step_name)

GO

CREATE OR ALTER PROCEDURE sp_long_jobs(
    @deviation_times INT = 3,
    @default_max_duration_minutes INT = 15,
    @from_address NVARCHAR(128) NULL,
    @recipients NVARCHAR(128) NULL
)
AS
SET NOCOUNT ON

DECLARE
    @start_exec_count INT = 5,
    @subject NVARCHAR(255) = 'Long Running Job Detected On ' + HOST_NAME(),
    @body NVARCHAR(MAX)

DECLARE @RunningJobs TABLE (
    job_id UNIQUEIDENTIFIER NOT NULL,
    last_run_date INT NOT NULL,
    last_run_time INT NOT NULL,
    next_run_date INT NOT NULL,
    next_run_time INT NOT NULL,
    next_run_schedule_id INT NOT NULL,
    requested_to_run INT NOT NULL,
    request_source INT NOT NULL,
    request_source_id SYSNAME NULL,
    running INT NOT NULL,
    current_step INT NOT NULL,
    current_retry_attempt INT NOT NULL,
    job_state INT NOT NULL
)

DECLARE @DetectedJobs TABLE(
    job_id UNIQUEIDENTIFIER,
    job_name SYSNAME,
    execution_date DATETIME,
    avg_duration INT,
    max_duration INT,
    current_duration INT
)

DECLARE @JobMaxDurationSetting TABLE(
        job_name SYSNAME NOT NULL,
        max_duration_minutes INT NOT NULL
    )



INSERT INTO @RunningJobs
EXEC MASTER.dbo.xp_sqlagent_enum_jobs 1, ''

;WITH JobsHistory AS (
    SELECT
        job_id,
        msdb.dbo.agent_datetime(run_date, run_time) AS date_executed,
        run_duration / 10000 * 3600 + run_duration % 10000 / 100 * 60 + run_duration % 100 AS duration
    FROM msdb.dbo.sysjobhistory
    WHERE step_id = 0
    AND run_status = 1
),
JobHistoryStats AS (
    SELECT
        job_id,
        AVG(duration * 1.0) AS avg_duration,
        AVG(duration * 1.0) * @deviation_times AS max_duration
    FROM JobsHistory
    GROUP BY job_id
    HAVING COUNT(*) >= @start_exec_count
)
INSERT INTO @DetectedJobs(
    job_id,
    job_name,
    execution_date,
    avg_duration,
    max_duration,
    current_duration
)
SELECT
    a.job_id AS job_id,
    c.name AS job_name,
    MAX(e.start_execution_date) AS execution_date,
    b.avg_duration,
    ISNULL(MAX(i.max_duration_minutes) * 60, b.max_duration) AS max_duration,
    MAX(DATEDIFF(SECOND, e.start_execution_date, GETDATE())) AS current_duration
FROM JobsHistory a
INNER JOIN JobHistoryStats b ON a.job_id = b.job_id
INNER JOIN msdb.dbo.sysjobs c ON a.job_id = c.job_id
INNER JOIN @RunningJobs d ON d.job_id = a.job_id
INNER JOIN msdb.dbo.sysjobactivity e ON e.job_id = a.job_id
AND e.stop_execution_date IS NULL
AND e.start_execution_date IS NOT NULL
LEFT JOIN @JobMaxDurationSetting i ON i.job_name = c.name
WHERE DATEDIFF(SECOND, e.start_execution_date, GETDATE()) > ISNULL(i.max_duration_minutes * 60, (SELECT MAX(d) FROM (VALUES(b.max_duration), (@default_max_duration_minutes * 60)) v(d)))
AND d.job_state = 1
GROUP BY a.job_id, c.name, b.avg_duration, b.max_duration

IF @@ROWCOUNT = 0
    RETURN

SELECT * FROM @RunningJobs
SELECT * FROM @DetectedJobs

IF @from_address IS NOT NULL AND @recipients IS NOT NULL
BEGIN

    DECLARE
        @job_id UNIQUEIDENTIFIER,
        @job_name SYSNAME,
        @execution_date DATETIME,
        @avg_duration INT,
        @max_duration INT,
        @current_duration INT
    
    DECLARE job_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT job_id, job_name, execution_date, avg_duration, max_duration, current_duration
    FROM @DetectedJobs
    ORDER BY current_duration DESC
    
    OPEN job_cursor
    
    FETCH NEXT FROM job_cursor INTO @job_id, @job_name, @execution_date, @avg_duration, @max_duration, @current_duration
    SET @body = 'Long Running Jobs Detected On Server ' + CAST(HOST_NAME() AS VARCHAR(128)) + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @body += 'Job Name: ' + CAST(@job_name AS VARCHAR(128)) + '  (ID: ' + CAST(@job_id AS CHAR(36)) + ')' + CHAR(13) + CHAR(10)
        SET @body += 'StartDate: ' + CAST(@execution_date AS VARCHAR(25)) + CHAR(13) + CHAR(10)
        SET @body += 'Current Duration: ' + CAST(@current_duration / 3600 AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(@current_duration % 3600 / 60 AS VARCHAR(2)), 2) + ':' + RIGHT('00' + CAST(@current_duration % 60 AS VARCHAR(2)), 2) + CHAR(13) + CHAR(10)
        SET @body += 'Average Duration: ' + CAST(@avg_duration / 3600 AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(@avg_duration % 3600 / 60 AS VARCHAR(2)), 2) + ':' + RIGHT('00' + CAST(@avg_duration % 60 AS VARCHAR(2)), 2) + CHAR(13) + CHAR(10)
        SET @body += 'Max Duration: ' + CAST(@max_duration / 3600 AS VARCHAR(10)) + ':' + RIGHT('00' + CAST(@max_duration % 3600 / 60 AS VARCHAR(2)), 2) + ':' + RIGHT('00' + CAST(@max_duration % 60 AS VARCHAR(2)), 2) + CHAR(13) + CHAR(10)
        SET @body += CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
    
        FETCH NEXT FROM job_cursor INTO @job_id, @job_name, @execution_date, @avg_duration, @max_duration, @current_duration
    END
    
    CLOSE job_cursor
    DEALLOCATE job_cursor
    
    EXEC msdb.dbo.sp_send_dbmail
        @from_address = @from_address,
        @recipients = @recipients,
        @subject = @subject,
        @body = @body
END

GO