CREATE PROCEDURE sp_long_proc_xe
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
