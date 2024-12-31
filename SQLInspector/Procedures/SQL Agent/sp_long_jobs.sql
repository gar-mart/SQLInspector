CREATE PROCEDURE sp_long_jobs(
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
